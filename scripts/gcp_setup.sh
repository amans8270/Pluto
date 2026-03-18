#!/bin/bash
# ══════════════════════════════════════════════════════════════
# Pluto — GCP One-Time Infrastructure Setup Script
# Run this ONCE after cloning on a machine with gcloud + psql
# ══════════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ID="your-gcp-project-id"   # ← CHANGE THIS
REGION="asia-south1"
SERVICE_ACCOUNT="pluto-backend"
DB_PASSWORD="$(openssl rand -base64 24)"

echo "🚀 Pluto GCP Setup — Project: $PROJECT_ID"

# ── 1. APIs ───────────────────────────────────────────────────
echo "Enabling GCP APIs..."
gcloud services enable \
  run.googleapis.com \
  alloydb.googleapis.com \
  redis.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  cloudbuild.googleapis.com \
  vpcaccess.googleapis.com \
  --project=$PROJECT_ID

# ── 2. Service Account ────────────────────────────────────────
echo "Creating service account..."
gcloud iam service-accounts create $SERVICE_ACCOUNT \
  --display-name="Pluto Backend Service Account" \
  --project=$PROJECT_ID || true

SA_EMAIL="$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com"

for role in \
  roles/secretmanager.secretAccessor \
  roles/storage.objectAdmin \
  roles/alloydb.client \
  roles/cloudtrace.agent \
  roles/logging.logWriter \
  roles/monitoring.metricWriter; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$role"
done

# ── 3. VPC Connector (for AlloyDB + Memorystore) ──────────────
echo "Creating VPC Access Connector..."
gcloud compute networks vpc-access connectors create pluto-connector \
  --region=$REGION \
  --network=default \
  --range=10.8.0.0/28 \
  --project=$PROJECT_ID || true

# ── 4. AlloyDB Cluster + Instance ────────────────────────────
echo "Creating AlloyDB cluster (this takes ~5 min)..."
gcloud alloydb clusters create pluto-db \
  --region=$REGION \
  --password=$DB_PASSWORD \
  --project=$PROJECT_ID || true

gcloud alloydb instances create pluto-primary \
  --cluster=pluto-db \
  --region=$REGION \
  --instance-type=PRIMARY \
  --cpu-count=2 \
  --project=$PROJECT_ID || true

echo "✅ AlloyDB password: $DB_PASSWORD  ← SAVE THIS"

# ── 5. Redis (Memorystore) ─────────────────────────────────────
echo "Creating Redis instance..."
gcloud redis instances create pluto-redis \
  --size=1 \
  --region=$REGION \
  --redis-version=redis_7_0 \
  --network=default \
  --project=$PROJECT_ID || true

# ── 6. GCS Bucket ────────────────────────────────────────────
echo "Creating GCS bucket..."
gsutil mb -c STANDARD -l $REGION gs://$PROJECT_ID-pluto-media/ || true
gsutil iam ch allUsers:objectViewer gs://$PROJECT_ID-pluto-media/

# ── 7. Secret Manager ─────────────────────────────────────────
echo "Setting up secrets (you'll need to update DB and Redis IPs below)..."

DB_IP=$(gcloud alloydb instances describe pluto-primary \
  --cluster=pluto-db --region=$REGION --format="value(ipAddress)" 2>/dev/null || echo "TODO_FILL")
REDIS_HOST=$(gcloud redis instances describe pluto-redis \
  --region=$REGION --format="value(host)" 2>/dev/null || echo "TODO_FILL")

printf "%s" "postgresql+asyncpg://postgres:$DB_PASSWORD@$DB_IP:5432/pluto" | \
  gcloud secrets create DATABASE_URL --data-file=- --project=$PROJECT_ID 2>/dev/null || \
  printf "%s" "postgresql+asyncpg://postgres:$DB_PASSWORD@$DB_IP:5432/pluto" | \
  gcloud secrets versions add DATABASE_URL --data-file=- --project=$PROJECT_ID

printf "%s" "redis://$REDIS_HOST:6379" | \
  gcloud secrets create REDIS_URL --data-file=- --project=$PROJECT_ID 2>/dev/null || \
  printf "%s" "redis://$REDIS_HOST:6379" | \
  gcloud secrets versions add REDIS_URL --data-file=- --project=$PROJECT_ID

printf "%s" "$PROJECT_ID-pluto-media" | \
  gcloud secrets create GCS_BUCKET_NAME --data-file=- --project=$PROJECT_ID 2>/dev/null

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Infrastructure created. Next steps:"
echo "  1. Add FIREBASE_CREDENTIALS_JSON secret manually:"
echo "     gcloud secrets create FIREBASE_CREDENTIALS_JSON --data-file=serviceAccountKey.json"
echo ""
echo "  2. Run the DB migration:"
echo "     gcloud alloydb connect pluto-primary --region=$REGION"
echo "     Then run: \\i pluto-backend/migrations/init.sql"
echo ""
echo "  3. Replace PROJECT_ID in cloudrun-service.yaml, then:"
echo "     gcloud builds submit --config cloudbuild.yaml"
echo "════════════════════════════════════════════════════════"
