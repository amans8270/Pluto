"""Chats API (REST portion — WebSocket is in api/websocket.py)."""
import uuid
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.chat import ChatListResponse, MessageListResponse, SendMessageRequest, MessageResponse
from app.services.chat_service import ChatService

router = APIRouter()


@router.get("/", response_model=ChatListResponse)
async def list_chats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all chats (DM + group) for the current user, sorted by last message time."""
    service = ChatService(db)
    chats = await service.list_chats(user_id=current_user.id)
    return ChatListResponse(chats=chats)


@router.get("/{chat_id}/messages", response_model=MessageListResponse)
async def get_messages(
    chat_id: uuid.UUID,
    before: uuid.UUID | None = Query(None, description="Cursor: get messages before this message ID"),
    limit: int = Query(30, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get message history for a chat (cursor-based pagination)."""
    service = ChatService(db)
    messages = await service.get_messages(
        chat_id=chat_id,
        user_id=current_user.id,
        before_id=before,
        limit=limit,
    )
    return MessageListResponse(messages=messages)


@router.post("/{chat_id}/messages", response_model=MessageResponse, status_code=201)
async def send_message(
    chat_id: uuid.UUID,
    body: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Send a message via REST (fallback if WebSocket is unavailable)."""
    service = ChatService(db)
    return await service.send_message(
        chat_id=chat_id,
        sender_id=current_user.id,
        content=body.content,
        msg_type=body.msg_type,
        media_url=body.media_url,
    )


@router.put("/{chat_id}/read", status_code=204)
async def mark_as_read(
    chat_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark all messages in a chat as read."""
    service = ChatService(db)
    await service.mark_chat_read(chat_id=chat_id, user_id=current_user.id)
