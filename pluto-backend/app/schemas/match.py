"""Pydantic schemas for Matches."""
import uuid
from datetime import datetime
from pydantic import BaseModel


class MatchResponse(BaseModel):
    id: uuid.UUID
    user_a_id: uuid.UUID
    user_b_id: uuid.UUID
    mode: str
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class MatchListResponse(BaseModel):
    matches: list[MatchResponse]
    total: int
