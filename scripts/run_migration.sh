#!/bin/bash
# ══════════════════════════════════════════════════════════════
# Pluto — Run DB Migration on AlloyDB
# ══════════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"  # override via env
REGION="asia-south1"
DB_NAME="pluto"

echo "🗄️  Running Pluto DB migration..."

# Get AlloyDB instance IP
DB_IP=$(gcloud alloydb instances describe pluto-primary \
  --cluster=pluto-db \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(ipAddress)")

echo "AlloyDB IP: $DB_IP"

# Use Cloud SQL Proxy / AlloyDB Auth Proxy for secure connection
# Download auth proxy if not present
if [ ! -f "alloydb-auth-proxy" ]; then
  curl -o alloydb-auth-proxy https://storage.googleapis.com/alloydb-auth-proxy/v1.5.2/alloydb-auth-proxy.linux.amd64
  chmod +x alloydb-auth-proxy
fi

# Start proxy in background
./alloydb-auth-proxy \
  "projects/$PROJECT_ID/locations/$REGION/clusters/pluto-db/instances/pluto-primary" &
PROXY_PID=$!

sleep 3

echo "Running migration..."
PGPASSWORD=$DB_PASSWORD psql \
  -h 127.0.0.1 \
  -p 5432 \
  -U postgres \
  -d $DB_NAME \
  -f "pluto-backend/migrations/init.sql" \
  --echo-errors

# Stop proxy
kill $PROXY_PID 2>/dev/null

echo "✅ Migration complete!"
