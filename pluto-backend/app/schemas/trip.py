"""Pydantic schemas for Trips."""
import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field


class TripCreateRequest(BaseModel):
    title: str = Field(..., min_length=5, max_length=150)
    description: Optional[str] = None
    destination: str = Field(..., min_length=2, max_length=200)
    destination_lat: Optional[float] = None
    destination_lon: Optional[float] = None
    category: Optional[str] = None    # Adventure, Cultural, Leisure, etc.
    difficulty: Optional[str] = None  # Easy, Moderate, Hard
    start_date: date
    end_date: date
    max_members: int = Field(12, ge=2, le=50)
    entry_fee_inr: float = Field(0.0, ge=0)
    meeting_point: Optional[str] = None
    temperature: Optional[str] = None


class TripJoinRequest(BaseModel):
    payment_ref: Optional[str] = None  # Razorpay order ID


class TripSummary(BaseModel):
    id: uuid.UUID
    title: str
    destination: str
    category: Optional[str]
    start_date: date
    end_date: date
    max_members: int
    entry_fee_inr: float
    cover_image_url: Optional[str]
    status: str
    joined_count: Optional[int] = None
    spots_left: Optional[int] = None
    dist_km: Optional[float] = None
    creator_name: Optional[str] = None
    creator_photo: Optional[str] = None

    model_config = {"from_attributes": True}


class TripDetailResponse(BaseModel):
    id: uuid.UUID
    title: str
    description: Optional[str]
    destination: str
    category: Optional[str]
    difficulty: Optional[str]
    start_date: date
    end_date: date
    max_members: int
    entry_fee_inr: float
    cover_image_url: Optional[str]
    meeting_point: Optional[str]
    temperature: Optional[str]
    status: str
    created_at: datetime
    joined_count: int
    spots_left: int
    is_owner: bool
    viewer_status: str
    application_id: Optional[uuid.UUID] = None

    model_config = {"from_attributes": True}


class TripListResponse(BaseModel):
    trips: list
    total: int
    page: int
