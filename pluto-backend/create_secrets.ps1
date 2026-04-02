# Create GCP Secrets for Pluto Backend
# Open this file, replace the placeholder '"REPLACE_ME"' strings with your actual production keys, and run it in your terminal.

$PROJECT_ID = "pluto-backend-490622"

Function Create-Secret {
    param(
        [string]$SecretName,
        [string]$SecretValue
    )
    Write-Host "Creating secret: $SecretName"
    
    # Create the secret namespace (suppress error if it already exists)
    gcloud secrets create $SecretName --replication-policy="automatic" 2>$null
    
    # Inject the value as a new version
    Write-Output $SecretValue | gcloud secrets versions add $SecretName --data-file=-
}

# 1. Provide your Cloud SQL / AlloyDB connection string
Create-Secret -SecretName "DATABASE_URL" -SecretValue "postgresql+asyncpg://postgres:pluto@10.79.32.5:5432/postgres"

# 2. Provide your Valkey (Memorystore) connection string
Create-Secret -SecretName "VALKEY_URL" -SecretValue "redis://10.128.0.3:6379"

# 3. Provide the name of your Cloud Storage Bucket (e.g. "pluto-media-storage")
Create-Secret -SecretName "GCS_BUCKET_NAME" -SecretValue "pluto-media-bucket"

# 4. Provide your Firebase Service Account JSON (stringified). 
# Note: For JSON payloads in PowerShell, using a file path is much easier.
# Save your serviceAccountKey.json locally first.
Write-Host "Uploading Firebase Service Account JSON..."
gcloud secrets create FIREBASE_CREDENTIALS_JSON --replication-policy="automatic" 2>$null
gcloud secrets versions add FIREBASE_CREDENTIALS_JSON --data-file="./serviceAccountKey.json"

Write-Host "All secrets successfully provisioned to Secret Manager!"
