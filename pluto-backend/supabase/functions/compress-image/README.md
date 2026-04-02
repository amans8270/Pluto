# Supabase Edge Function - Image Compression

## Setup Instructions

### 1. Install Supabase CLI

```bash
# Windows (PowerShell)
iwr -useb https://raw.githubusercontent.com/supabase/cli/main/install.ps1 | iex

# macOS/Linux
npm install -g supabase
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Link your project

```bash
supabase link --project-ref esedlxfmzwndjhqboknl
```

### 4. Deploy the Edge Function

```bash
cd pluto-backend
supabase functions deploy compress-image
```

### 5. Create Storage Bucket

1. Go to Supabase Dashboard → Storage
2. Create a new bucket:
   - **Name**: `photos`
   - **Public**: Yes (so images can be viewed directly)
   - **File size limit**: 10MB

### 6. Set Edge Function Environment Variables

In Supabase Dashboard → Edge Functions → Settings:

```env
SUPABASE_URL=https://esedlxfmzwndjhqboknl.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 7. Configure Storage RLS (Row Level Security)

In Supabase Dashboard → Storage → Policies, add:

```sql
-- Allow authenticated uploads
CREATE POLICY "Allow uploads" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'photos');

-- Allow public reads
CREATE POLICY "Allow reads" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'photos');

-- Allow authenticated deletes
CREATE POLICY "Allow deletes" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'photos');
```

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    Image Upload Flow                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │   Client    │───▶│   FastAPI       │───▶│  Edge Function  │ │
│  │  (Flutter)  │    │   (Backend)     │    │   (WASM)        │ │
│  └─────────────┘    └─────────────────┘    └─────────────────┘ │
│                           │                      │              │
│                           │                      ▼              │
│                           │            ┌─────────────────┐     │
│                           │            │  ImageMagick    │     │
│                           │            │     WASM        │     │
│                           │            │  - Resize 1200  │     │
│                           │            │  - Convert WebP │     │
│                           │            │  - Compress 85% │     │
│                           │            └─────────────────┘     │
│                           │                      │              │
│                           │                      ▼              │
│                           │            ┌─────────────────┐     │
│                           │            │  Supabase       │     │
│                           │◀───────────│  Storage        │     │
│                           │            └─────────────────┘     │
│                           │                                    │
│                           ▼                                    │
│                    ┌─────────────────┐                         │
│                    │   PostgreSQL    │                         │
│                    │  (Photo URL)    │                         │
│                    └─────────────────┘                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- **Resize**: Images larger than 1200px are resized proportionally
- **Convert**: All images converted to WebP format (smaller, faster)
- **Compress**: 85% quality for optimal size/quality balance
- **Format Support**: JPEG, PNG, WebP, GIF inputs

## Testing

```bash
# Test locally (optional)
supabase functions serve compress-image

# Or test via curl
curl -X POST https://esedlxfmzwndjhqboknl.supabase.co/functions/v1/compress-image \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -F "file=@test-image.jpg" \
  -F "user_id=test-user-123" \
  -F "folder=photos"
```

## Expected Response

```json
{
  "success": true,
  "url": "https://esedlxfmzwndjhqboknl.supabase.co/storage/v1/object/public/photos/test-user-123/photos/1710000000_abc12345.webp",
  "path": "test-user-123/photos/1710000000_abc12345.webp",
  "stats": {
    "original_size_bytes": 2048000,
    "compressed_size_bytes": 204800,
    "compression_ratio": "90.0%"
  }
}
```
