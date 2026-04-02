"""
Supabase Edge Function client for image compression.
Uploads images to Supabase Edge Function which handles:
- WASM-based image processing
- Resize to max 1200px
- Convert to WebP format
- Store in Supabase Storage
"""

import io
import logging
from typing import Optional

import httpx
from fastapi import UploadFile, HTTPException

from app.core.config import settings

logger = logging.getLogger(__name__)

# Edge Function URL
EDGE_FUNCTION_URL = f"{settings.SUPABASE_URL}/functions/v1/compress-image"


class EdgeFunctionClient:
    """Client for calling Supabase Edge Functions."""

    def __init__(self):
        self.url = EDGE_FUNCTION_URL
        self.headers = {
            "Authorization": f"Bearer {settings.SUPABASE_SERVICE_KEY}",
            "apikey": settings.SUPABASE_ANON_KEY,
        }

    async def compress_and_upload(
        self, file: UploadFile, user_id: str, folder: str = "photos"
    ) -> dict:
        """
        Upload image to Edge Function for compression and storage.

        Args:
            file: The uploaded file
            user_id: User ID for organizing storage
            folder: Folder name within user's storage path

        Returns:
            dict with 'url' (public URL) and 'path' (storage path)
        """
        if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_KEY:
            raise HTTPException(
                status_code=500,
                detail="Supabase not configured. Set SUPABASE_URL and SUPABASE_SERVICE_KEY.",
            )

        # Read file content
        content = await file.read()

        # Create multipart form data
        files = {
            "file": (file.filename, content, file.content_type or "image/jpeg"),
        }
        data = {
            "user_id": str(user_id),
            "folder": folder,
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            try:
                response = await client.post(
                    self.url,
                    headers=self.headers,
                    files=files,
                    data=data,
                )

                if response.status_code != 200:
                    error_detail = response.text
                    logger.error(
                        f"Edge Function error: {response.status_code} - {error_detail}"
                    )
                    raise HTTPException(
                        status_code=500,
                        detail=f"Image compression failed: {error_detail}",
                    )

                result = response.json()

                logger.info(
                    f"Image compressed: {result.get('stats', {}).get('compression_ratio', 'N/A')} reduction"
                )

                return {
                    "url": result["url"],
                    "path": result["path"],
                    "stats": result.get("stats", {}),
                }

            except httpx.TimeoutException:
                logger.error("Edge Function timeout")
                raise HTTPException(
                    status_code=504,
                    detail="Image compression timeout. Please try again.",
                )
            except httpx.RequestError as e:
                logger.error(f"Edge Function request error: {str(e)}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Image compression service unavailable: {str(e)}",
                )

    async def delete_from_storage(self, file_path: str) -> bool:
        """Delete a file from Supabase Storage via direct API."""
        if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_KEY:
            return False

        # Extract bucket and path from file_path
        # Expected format: user_id/folder/filename.webp
        bucket = "photos"

        async with httpx.AsyncClient() as client:
            try:
                response = await client.delete(
                    f"{settings.SUPABASE_URL}/storage/v1/object/{bucket}/{file_path}",
                    headers={
                        **self.headers,
                        "Content-Type": "application/json",
                    },
                )
                return response.status_code == 200
            except Exception as e:
                logger.error(f"Delete from storage error: {str(e)}")
                return False


# Singleton instance
edge_client = EdgeFunctionClient()
