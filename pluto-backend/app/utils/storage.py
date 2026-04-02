import abc
import os
import uuid
import logging
from typing import BinaryIO
from fastapi import UploadFile, HTTPException
from google.cloud import storage
import httpx
import hashlib
import time
import re
from app.core.config import settings

logger = logging.getLogger(__name__)


class StorageProvider(abc.ABC):
    @abc.abstractmethod
    async def upload(self, file: UploadFile, folder: str) -> str:
        """Upload a file and return the public URL."""
        pass

    @abc.abstractmethod
    async def delete(self, file_url: str) -> bool:
        """Delete a file given its URL."""
        pass


class LocalStorageProvider(StorageProvider):
    def __init__(self, base_dir: str = "static/uploads", base_url: str = "/uploads"):
        self.base_dir = base_dir
        self.base_url = base_url
        os.makedirs(self.base_dir, exist_ok=True)

    async def upload(self, file: UploadFile, folder: str) -> str:
        try:
            ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
            filename = f"{uuid.uuid4()}.{ext}"
            rel_path = os.path.join(folder, filename)
            abs_path = os.path.join(self.base_dir, rel_path)
            os.makedirs(os.path.dirname(abs_path), exist_ok=True)

            content = await file.read()
            with open(abs_path, "wb") as f:
                f.write(content)

            logger.info(f"File uploaded locally: {abs_path}")
            return f"{self.base_url}/{rel_path}".replace("\\", "/")
        except Exception as e:
            logger.error(f"Error uploading file locally: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Failed to upload file: {str(e)}"
            )

    async def delete(self, file_url: str) -> bool:
        try:
            # Extract relative path from URL
            rel_path = file_url.replace(self.base_url, "").lstrip("/")
            abs_path = os.path.join(self.base_dir, rel_path)
            if os.path.exists(abs_path):
                os.remove(abs_path)
                logger.info(f"File deleted: {abs_path}")
            return True
        except Exception as e:
            logger.error(f"Error deleting file: {str(e)}")
            return False


class GCSStorageProvider(StorageProvider):
    def __init__(self, bucket_name: str, project_id: str):
        self.bucket_name = bucket_name
        self.project_id = project_id
        self._client = None

    @property
    def client(self):
        if self._client is None:
            try:
                self._client = storage.Client(project=self.project_id)
            except Exception as e:
                logger.error(f"Failed to create GCS client: {str(e)}")
                raise HTTPException(
                    status_code=500, detail="Storage service unavailable"
                )
        return self._client

    async def upload(self, file: UploadFile, folder: str) -> str:
        try:
            ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
            blob_name = f"{folder}/{uuid.uuid4()}.{ext}"
            bucket = self.client.bucket(self.bucket_name)
            blob = bucket.blob(blob_name)

            content = await file.read()
            content_type = file.content_type or "image/jpeg"
            blob.upload_from_string(content, content_type=content_type)
            blob.make_public()

            logger.info(f"File uploaded to GCS: {blob_name}")
            return blob.public_url
        except Exception as e:
            logger.error(f"Error uploading to GCS: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Failed to upload to storage: {str(e)}"
            )

    async def delete(self, file_url: str) -> bool:
        try:
            # Extract blob name from URL
            blob_name = (
                file_url.split(f"{self.bucket_name}/")[-1]
                if self.bucket_name in file_url
                else None
            )
            if not blob_name:
                logger.warning(f"Could not extract blob name from URL: {file_url}")
                return False

            bucket = self.client.bucket(self.bucket_name)
            blob = bucket.blob(blob_name)
            if blob.exists():
                blob.delete()
                logger.info(f"File deleted from GCS: {blob_name}")
            return True
        except Exception as e:
            logger.error(f"Error deleting from GCS: {str(e)}")
            return False


class SupabaseStorageProvider(StorageProvider):
    def __init__(self, bucket_name: str = "photos"):
        self.bucket_name = bucket_name
        self._client = None

    @property
    def client(self):
        if self._client is None:
            from supabase import create_client

            self._client = create_client(
                settings.SUPABASE_URL,
                settings.SUPABASE_SERVICE_KEY,
            )
        return self._client

    async def upload(self, file: UploadFile, folder: str) -> str:
        try:
            ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
            file_path = f"{folder}/{uuid.uuid4()}.{ext}"

            content = await file.read()
            content_type = file.content_type or "image/jpeg"

            self.client.storage.from_(self.bucket_name).upload(
                path=file_path,
                file=content,
                file_options={"content-type": content_type},
            )

            public_url = self.client.storage.from_(self.bucket_name).get_public_url(
                file_path
            )
            logger.info(f"File uploaded to Supabase: {file_path}")
            return public_url
        except Exception as e:
            logger.error(f"Error uploading to Supabase: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Failed to upload to storage: {str(e)}"
            )

    async def delete(self, file_url: str) -> bool:
        try:
            file_path = file_url.split(f"/{self.bucket_name}/")[-1]
            self.client.storage.from_(self.bucket_name).remove([file_path])
            logger.info(f"File deleted from Supabase: {file_path}")
            return True
        except Exception as e:
            logger.error(f"Error deleting from Supabase: {str(e)}")
            return False


class CloudinaryStorageProvider(StorageProvider):
    def __init__(self):
        self.cloud_name = settings.CLOUDINARY_CLOUD_NAME
        self.api_key = settings.CLOUDINARY_API_KEY
        self.api_secret = settings.CLOUDINARY_API_SECRET

    def _ensure_configured(self) -> None:
        if not (self.cloud_name and self.api_key and self.api_secret):
            raise HTTPException(
                status_code=503,
                detail=(
                    "Photo storage is not configured. Set "
                    "CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and "
                    "CLOUDINARY_API_SECRET."
                ),
            )

    async def upload(self, file: UploadFile, folder: str) -> str:
        self._ensure_configured()

        content = await file.read()
        timestamp = str(int(time.time()))
        params_to_sign = f"folder={folder}&timestamp={timestamp}"
        signature = hashlib.sha1(
            (params_to_sign + self.api_secret).encode()
        ).hexdigest()
        upload_url = f"https://api.cloudinary.com/v1_1/{self.cloud_name}/image/upload"

        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                upload_url,
                data={
                    "api_key": self.api_key,
                    "timestamp": timestamp,
                    "folder": folder,
                    "signature": signature,
                },
                files={
                    "file": (
                        file.filename or f"{uuid.uuid4()}.jpg",
                        content,
                        file.content_type or "image/jpeg",
                    )
                },
            )

        if resp.status_code != 200:
            logger.error("Cloudinary upload failed: %s", resp.text)
            raise HTTPException(
                status_code=502,
                detail=f"Cloudinary upload failed: {resp.text}",
            )

        result = resp.json()
        public_url = result.get("secure_url") or result.get("url")
        if not public_url:
            raise HTTPException(
                status_code=502,
                detail="Cloudinary upload succeeded but returned no URL.",
            )

        logger.info("File uploaded to Cloudinary: %s", public_url)
        return public_url

    async def delete(self, file_url: str) -> bool:
        self._ensure_configured()

        if not file_url or "res.cloudinary.com" not in file_url:
            return False

        try:
            marker = f"/{self.cloud_name}/image/upload/"
            if marker not in file_url:
                return False

            public_id_with_ext = file_url.split(marker, 1)[1]
            public_id_with_ext = re.sub(r"^v\d+/", "", public_id_with_ext)
            public_id = public_id_with_ext.rsplit(".", 1)[0]
            destroy_url = (
                f"https://api.cloudinary.com/v1_1/{self.cloud_name}/image/destroy"
            )
            timestamp = str(int(time.time()))
            params_to_sign = f"public_id={public_id}&timestamp={timestamp}"
            signature = hashlib.sha1(
                (params_to_sign + self.api_secret).encode()
            ).hexdigest()

            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.post(
                    destroy_url,
                    data={
                        "public_id": public_id,
                        "timestamp": timestamp,
                        "api_key": self.api_key,
                        "signature": signature,
                    },
                )

            if resp.status_code != 200:
                logger.warning("Cloudinary delete failed: %s", resp.text)
                return False

            return resp.json().get("result") in {"ok", "not found"}
        except Exception as e:
            logger.error("Error deleting from Cloudinary: %s", str(e))
            return False


def get_storage_provider() -> StorageProvider:
    if (
        settings.CLOUDINARY_CLOUD_NAME
        and settings.CLOUDINARY_API_KEY
        and settings.CLOUDINARY_API_SECRET
    ):
        return CloudinaryStorageProvider()
    if settings.APP_ENV in ("dev", "development") or not settings.GCS_BUCKET_NAME:
        return LocalStorageProvider()
    return GCSStorageProvider(settings.GCS_BUCKET_NAME, settings.GCS_PROJECT_ID)
