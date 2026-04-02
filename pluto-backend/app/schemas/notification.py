"""Pydantic schemas for Notifications."""
import uuid
from datetime import datetime
from typing import Any, Optional
from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: uuid.UUID
    type: str
    title: Optional[str]
    body: Optional[str]
    data: Optional[Any]
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationListResponse(BaseModel):
    notifications: list[NotificationResponse]
    total: int
    page: int
