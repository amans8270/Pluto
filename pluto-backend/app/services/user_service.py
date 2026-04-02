"""User Service — profile management + photo upload/delete."""

import uuid
import logging
from fastapi import HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.photo import Photo
from app.models.profile import Profile
from app.repositories.user_repo import UserRepository
from app.schemas.user import ProfileCreateRequest, ProfileUpdateRequest
from app.utils.storage import get_storage_provider
from app.core.cache import (
    cache_profile,
    get_cached_profile,
    invalidate_user_caches,
)

logger = logging.getLogger(__name__)

# Supported image formats
SUPPORTED_FORMATS = {"jpg", "jpeg", "png", "webp", "gif"}
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = UserRepository(db)
        self.storage = get_storage_provider()

    async def get_full_profile(self, user_id: uuid.UUID) -> dict:
        # Try cache first
        cached = get_cached_profile(user_id)
        if cached:
            logger.debug(f"Cache hit for profile {user_id}")
            return cached

        user = await self.repo.get_by_id(user_id)
        if not user or not user.profile:
            raise HTTPException(status_code=404, detail="Profile not found")

        profile_data = {
            "id": user.id,
            "display_name": user.profile.display_name,
            "bio": user.profile.bio,
            "age": user.profile.age,
            "gender": user.profile.gender,
            "active_mode": user.profile.active_mode,
            "education": user.profile.education,
            "occupation": user.profile.occupation,
            "languages": user.profile.languages,
            "height_cm": user.profile.height_cm,
            "photos": user.photos,
            "interests": [ui.interest for ui in user.user_interests],
        }

        # Cache the profile
        cache_profile(user_id, profile_data)
        return profile_data

    async def create_profile(
        self, user_id: uuid.UUID, data: ProfileCreateRequest
    ) -> Profile:
        existing = await self.db.execute(
            select(Profile).where(Profile.user_id == user_id)
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400, detail="Profile already exists. Use PUT to update."
            )

        # Handle interests if provided
        if data.interest_ids:
            await self.repo.set_interests(user_id, data.interest_ids)

        profile = Profile(
            user_id=user_id,
            display_name=data.display_name,
            bio=data.bio,
            age=data.age,
            gender=data.gender,
            education=data.education,
            occupation=data.occupation,
            languages=data.languages,
            height_cm=data.height_cm,
            is_profile_complete=True,
        )
        self.db.add(profile)
        await self.db.flush()
        await self.db.refresh(profile)
        return profile

    async def update_profile(
        self, user_id: uuid.UUID, data: ProfileUpdateRequest
    ) -> Profile:
        result = await self.db.execute(
            select(Profile).where(Profile.user_id == user_id)
        )
        profile = result.scalar_one_or_none()
        if not profile:
            raise HTTPException(
                status_code=404, detail="Profile not found. Create it first."
            )

        # Handle interests if provided
        if data.interest_ids is not None:
            await self.repo.set_interests(user_id, data.interest_ids)

        update_data = data.model_dump(exclude_unset=True)
        # remove interest_ids from update_data as it's handled separately
        update_data.pop("interest_ids", None)

        for field, value in update_data.items():
            setattr(profile, field, value)
        await self.db.flush()
        await self.db.refresh(profile)

        # Invalidate caches after profile update
        invalidate_user_caches(user_id)
        logger.info(f"Invalidated caches for user {user_id} after profile update")
        return profile

    async def update_location(
        self,
        user_id: uuid.UUID,
        lat: float,
        lon: float,
        city: str | None,
        country: str = "India",
    ) -> None:
        await self.repo.update_location(user_id, lat, lon, city, country)

    async def update_interests(
        self, user_id: uuid.UUID, interest_ids: list[int]
    ) -> None:
        if len(interest_ids) > 10:
            raise HTTPException(status_code=400, detail="Maximum 10 interests allowed.")
        await self.repo.set_interests(user_id, interest_ids)

    async def upload_photo(
        self, user_id: uuid.UUID, file: UploadFile, display_order: int
    ) -> str:
        if not file:
            raise HTTPException(status_code=400, detail="No file provided")

        content = await file.read()
        if len(content) > MAX_IMAGE_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"File too large. Maximum size is {MAX_IMAGE_SIZE / 1024 / 1024}MB",
            )

        ext = file.filename.rsplit(".", 1)[-1].lower() if file.filename else "jpg"
        if ext not in SUPPORTED_FORMATS:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported format. Allowed: {SUPPORTED_FORMATS}",
            )

        # Max 6 photos per user
        count_result = await self.db.execute(
            select(Photo).where(Photo.user_id == user_id)
        )
        if len(count_result.scalars().all()) >= 6:
            raise HTTPException(status_code=400, detail="Maximum 6 photos allowed.")

        try:
            await file.seek(0)
            public_url = await self.storage.upload(
                file=file,
                folder=f"pluto/{user_id}/photos",
            )

            # Save photo record to database
            photo = Photo(user_id=user_id, gcs_url=public_url, display_order=display_order)
            self.db.add(photo)
            await self.db.flush()

            invalidate_user_caches(user_id)
            logger.info(f"Photo uploaded for user {user_id}: {public_url}")
            return public_url

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error uploading photo for user {user_id}: {str(e)}")
            raise HTTPException(
                status_code=500, detail=f"Failed to upload image: {str(e)}"
            )


    async def save_photo_url(
        self, user_id: uuid.UUID, url: str, display_order: int = 0
    ) -> Photo:
        """
        Save a photo URL after client-side upload to an external storage provider.
        """
        # Max 6 photos per user
        count_result = await self.db.execute(
            select(Photo).where(Photo.user_id == user_id)
        )
        existing = count_result.scalars().all()
        if len(existing) >= 6:
            raise HTTPException(status_code=400, detail="Maximum 6 photos allowed.")

        if not url.startswith(("http://", "https://")):
            raise HTTPException(status_code=400, detail="Photo URL must be absolute.")

        # Save photo record to database
        photo = Photo(user_id=user_id, gcs_url=url, display_order=display_order)
        self.db.add(photo)
        await self.db.flush()

        # Invalidate profile cache after photo upload
        invalidate_user_caches(user_id)

        logger.info(f"Photo URL saved for user {user_id}: {url}")
        return photo

    async def delete_photo(self, user_id: uuid.UUID, photo_id: uuid.UUID) -> None:
        result = await self.db.execute(
            select(Photo).where(Photo.id == photo_id, Photo.user_id == user_id)
        )
        photo = result.scalar_one_or_none()
        if not photo:
            raise HTTPException(status_code=404, detail="Photo not found")

        await self.storage.delete(photo.gcs_url)
        await self.db.delete(photo)
        await self.db.flush()
        invalidate_user_caches(user_id)

    async def get_public_profile(
        self, user_id: uuid.UUID, viewer_id: uuid.UUID
    ) -> dict:
        user = await self.repo.get_by_id(user_id)
        if not user or not user.is_active:
            raise HTTPException(status_code=404, detail="User not found")

        profile = user.profile
        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")

        return {
            "id": user.id,
            "display_name": profile.display_name,
            "age": profile.age,
            "bio": profile.bio,
            "gender": profile.gender,
            "occupation": profile.occupation,
            "photos": user.photos or [],
            "interests": [ui.interest.name for ui in user.user_interests]
            if user.user_interests
            else [],
        }
