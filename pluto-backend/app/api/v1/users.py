"""Users & Profiles API."""

import uuid
from typing import List
from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.interest import Interest
from app.models.user import User
from app.schemas.user import (
    ProfileCreateRequest,
    ProfileResponse,
    ProfileUpdateRequest,
    UserPublicResponse,
    LocationUpdateRequest,
    InterestsUpdateRequest,
    InterestItem,
)
from app.services.user_service import UserService

router = APIRouter()


class PhotoUrlRequest(BaseModel):
    """Schema for accepting a pre-uploaded photo URL."""

    url: str
    display_order: int = 0


@router.get("/interests", response_model=List[InterestItem])
async def get_available_interests(
    db: AsyncSession = Depends(get_db),
):
    """Return all available interest tags for the UI."""
    result = await db.execute(select(Interest).order_by(Interest.name))
    return result.scalars().all()


@router.get("/me", response_model=ProfileResponse)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return the authenticated user's full profile."""
    service = UserService(db)
    return await service.get_full_profile(current_user.id)


@router.post(
    "/me/profile", response_model=ProfileResponse, status_code=status.HTTP_201_CREATED
)
async def create_profile(
    body: ProfileCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create profile during onboarding (first-time setup)."""
    service = UserService(db)
    return await service.create_profile(current_user.id, body)


@router.put("/me/profile", response_model=ProfileResponse)
async def update_profile(
    body: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update profile fields."""
    service = UserService(db)
    return await service.update_profile(current_user.id, body)


@router.put("/me/location", status_code=status.HTTP_204_NO_CONTENT)
async def update_location(
    body: LocationUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update user's current location (called periodically by the app)."""
    service = UserService(db)
    await service.update_location(
        current_user.id, body.latitude, body.longitude, body.city, body.country
    )


@router.put("/me/interests", status_code=status.HTTP_204_NO_CONTENT)
async def update_interests(
    body: InterestsUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Replace the user's interests (accepts list of interest IDs)."""
    service = UserService(db)
    await service.update_interests(current_user.id, body.interest_ids)


@router.post("/me/photos", status_code=status.HTTP_201_CREATED)
async def upload_photo(
    file: UploadFile = File(...),
    display_order: int = Query(default=0, ge=0, le=5),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Upload a profile photo. Max 6 photos per user."""
    if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(
            status_code=400, detail="Only JPEG, PNG, or WebP images are allowed."
        )
    service = UserService(db)
    url = await service.upload_photo(current_user.id, file, display_order)
    return {"url": url}


@router.post("/me/photos/url", status_code=status.HTTP_201_CREATED)
async def save_photo_url(
    body: PhotoUrlRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Save a photo URL after client-side upload.
    """
    service = UserService(db)
    photo = await service.save_photo_url(current_user.id, body.url, body.display_order)
    return {"id": str(photo.id), "url": body.url}


@router.delete("/me/photos/{photo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_photo(
    photo_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a specific photo."""
    service = UserService(db)
    await service.delete_photo(current_user.id, photo_id)


@router.get("/{user_id}", response_model=UserPublicResponse)
async def get_user_public(
    user_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get a public profile for another user (used when viewing swipe cards)."""
    service = UserService(db)
    return await service.get_public_profile(user_id, viewer_id=current_user.id)


@router.post("/me/fcm-token", status_code=status.HTTP_204_NO_CONTENT)
async def update_fcm_token(
    token: str = Query(..., description="Firebase Cloud Messaging token"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update FCM push notification token."""
    repo = UserRepository(db)
    await repo.update_fcm_token(current_user.id, token)
