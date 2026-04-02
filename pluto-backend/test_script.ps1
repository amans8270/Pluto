# This script initializes the pluto-secrets namespace and injects the necessary keys into Google Cloud Secret Manager.

# 1. First, create the empty secret namespace
gcloud secrets create pluto-secrets --replication-policy="automatic"

# 2. Add DATABASE_URL secret
# Replace with your actual AlloyDB user and password and private IP
$dbUrl = "postgresql+asyncpg://pluto_user:pluto_password@10.x.x.x:5432/pluto_db"
Write-Output $dbUrl | gcloud secrets versions add pluto-secrets --data-file=-

# Note: gcloud secret manager usually holds whole files or strings. However, cloudrun-service.yaml 
# expects specifically named keys inside the secret (like key: DATABASE_URL). 
# Wait, GCP Secret Manager natively does NOT support JSON keys natively unless you parse it.
# If cloudrun-service.yaml uses:
#   secretKeyRef:
#     name: pluto-secrets
#     key: DATABASE_URL
# This means the secret name is ACTUALLY "pluto-secrets" with a version, or we must name the individual secrets "DATABASE_URL" etc.
# Actually, GCP Cloud Run secret injections expect the *Secret Name* to be passed, not a dictionary key!
