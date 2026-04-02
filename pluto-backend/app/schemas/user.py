"""Pydantic schemas for Users & Profiles."""
import uuid
from typing import Optional, List
from pydantic import BaseModel, Field, field_validator


class InterestItem(BaseModel):
    id: int
    name: str
    category: Optional[str] = None
    icon: Optional[str] = None

    model_config = {"from_attributes": True}


class ProfileCreateRequest(BaseModel):
    display_name: str = Field(..., min_length=2, max_length=60)
    bio: Optional[str] = Field(None, max_length=500)
    age: int = Field(..., ge=18, le=100)
    gender: str = Field(..., pattern="^(MALE|FEMALE|NON_BINARY|OTHER)$")
    education: Optional[str] = None
    occupation: Optional[str] = None
    languages: Optional[List[str]] = None
    height_cm: Optional[int] = Field(None, ge=100, le=250)
    interest_ids: Optional[List[int]] = Field(None, min_length=3, max_length=10)


class ProfileUpdateRequest(BaseModel):
    display_name: Optional[str] = Field(None, min_length=2, max_length=60)
    bio: Optional[str] = Field(None, max_length=500)
    education: Optional[str] = None
    occupation: Optional[str] = None
    languages: Optional[List[str]] = None
    height_cm: Optional[int] = Field(None, ge=100, le=250)
    date_visible: Optional[bool] = None
    travel_visible: Optional[bool] = None
    bff_visible: Optional[bool] = None
    interest_ids: Optional[List[int]] = None
    active_mode: Optional[str] = Field(None, pattern="^(DATE|TRAVELBUDDY|BFF)$")


class LocationUpdateRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    city: Optional[str] = None
    country: str = "India"


class InterestsUpdateRequest(BaseModel):
    interest_ids: List[int] = Field(..., min_length=3, max_length=10)


class PhotoResponse(BaseModel):
    id: uuid.UUID
    gcs_url: str
    thumbnail_url: Optional[str]
    display_order: int

    model_config = {"from_attributes": True}


class ProfileResponse(BaseModel):
    id: uuid.UUID
    display_name: str
    bio: Optional[str]
    age: int
    gender: str
    active_mode: str
    education: Optional[str]
    occupation: Optional[str]
    languages: Optional[List[str]]
    height_cm: Optional[int]
    interests: List[InterestItem] = []
    photos: List[PhotoResponse] = []

    model_config = {"from_attributes": True}


class UserPublicResponse(BaseModel):
    id: uuid.UUID
    display_name: str
    age: int
    bio: Optional[str]
    gender: str
    occupation: Optional[str]
    photos: List[PhotoResponse] = []
    interests: List[str] = []
    dist_km: Optional[float] = None

    model_config = {"from_attributes": True}
