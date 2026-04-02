"""Pydantic schemas for Chats & Messages."""
import uuid
from datetime import datetime
from pydantic import BaseModel


class SendMessageRequest(BaseModel):
    content: str | None = None
    msg_type: str = "TEXT"  # TEXT | IMAGE | VIDEO | LOCATION | SYSTEM
    media_url: str | None = None


class MessageResponse(BaseModel):
    id: uuid.UUID
    chat_id: uuid.UUID
    sender_id: uuid.UUID
    content: str | None
    media_url: str | None
    msg_type: str
    is_deleted: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class MessageListResponse(BaseModel):
    messages: list[MessageResponse]


class ChatSummary(BaseModel):
    id: uuid.UUID
    is_group: bool
    name: str | None
    last_message: str | None
    last_message_at: datetime | None
    trip_id: uuid.UUID | None
    match_id: uuid.UUID | None

    model_config = {"from_attributes": True}


class ChatListResponse(BaseModel):
    chats: list[ChatSummary]
