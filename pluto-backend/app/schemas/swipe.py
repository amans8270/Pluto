"""Pydantic schemas for Swipes & Discover."""
import uuid
from typing import Any
from pydantic import BaseModel


class SwipeRequest(BaseModel):
    target_user_id: uuid.UUID
    mode: str  # DATE | TRAVELBUDDY | BFF
    action: str  # LIKE | DISLIKE | SUPERLIKE


class SwipeResponse(BaseModel):
    matched: bool
    match_id: str | None
    mode: str


class CandidateProfile(BaseModel):
    id: uuid.UUID
    display_name: str
    age: int
    bio: str | None
    gender: str
    occupation: str | None
    dist_km: float | None
    photos: list[str] = []
    interests: list[str] = []

    model_config = {"from_attributes": True}


class DiscoverResponse(BaseModel):
    candidates: list[Any]
    mode: str
