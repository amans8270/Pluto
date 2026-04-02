"""Pydantic schemas for Travel Buddy workflow."""
import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.models.trip import TripApplicationStatus


class TripApplicationResponse(BaseModel):
    id: uuid.UUID
    trip_id: uuid.UUID
    user_id: uuid.UUID
    status: TripApplicationStatus
    created_at: datetime
    updated_at: datetime
    username: Optional[str] = None
    photo_url: Optional[str] = None

    class Config:
        from_attributes = True


class TripPaymentRequest(BaseModel):
    amount: float = 11.0
    promo_code: Optional[str] = None
    payment_ref: Optional[str] = None


class TripMemberResponse(BaseModel):
    user_id: uuid.UUID
    username: Optional[str] = None
    photo_url: Optional[str] = None
    joined_at: datetime
    is_owner: bool = False

    class Config:
        from_attributes = True


class GroupApprovalStatusResponse(BaseModel):
    application_id: uuid.UUID
    required_approvals: int
    current_approvals: int
    voters: list[uuid.UUID]
