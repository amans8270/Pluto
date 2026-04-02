"""Chat Service — message persistence + channel fan-out via Redis."""
import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.chat import Chat, ChatMember
from app.models.message import Message


class ChatService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_chats(self, user_id: uuid.UUID) -> list[dict]:
        """Get all chats the user is a member of."""
        q = (
            select(Chat)
            .join(ChatMember, ChatMember.chat_id == Chat.id)
            .where(ChatMember.user_id == user_id)
            .order_by(Chat.last_message_at.desc().nullslast())
        )
        result = await self.db.execute(q)
        chats = result.scalars().all()
        return chats

    async def get_messages(
        self, chat_id: uuid.UUID, user_id: uuid.UUID, before_id: uuid.UUID | None, limit: int
    ) -> list[Message]:
        """Return messages for a chat. Cursor-based (before a message ID)."""
        # Verify user is a member
        member_check = await self.db.execute(
            select(ChatMember).where(
                ChatMember.chat_id == chat_id, ChatMember.user_id == user_id
            )
        )
        if not member_check.scalar_one_or_none():
            raise HTTPException(status_code=403, detail="Not a member of this chat")

        query = (
            select(Message)
            .where(Message.chat_id == chat_id, Message.is_deleted == False)
        )
        if before_id:
            # Get the timestamp of the cursor message for keyset pagination
            cursor_q = select(Message.created_at).where(Message.id == before_id)
            cursor_ts = (await self.db.execute(cursor_q)).scalar_one_or_none()
            if cursor_ts:
                query = query.where(Message.created_at < cursor_ts)

        query = query.order_by(Message.created_at.desc()).limit(limit)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def send_message(
        self,
        chat_id: uuid.UUID,
        sender_id: uuid.UUID,
        content: str | None,
        msg_type: str = "TEXT",
        media_url: str | None = None,
    ) -> Message:
        """Persist a message and update chat's last_message."""
        msg = Message(
            chat_id=chat_id,
            sender_id=sender_id,
            content=content,
            msg_type=msg_type,
            media_url=media_url,
        )
        self.db.add(msg)

        # Update chat last_message
        chat_result = await self.db.execute(select(Chat).where(Chat.id == chat_id))
        chat = chat_result.scalar_one_or_none()
        if chat:
            chat.last_message = content or f"[{msg_type}]"
            chat.last_message_at = datetime.now(timezone.utc)

        await self.db.flush()
        await self.db.refresh(msg)
        return msg

    async def mark_chat_read(self, chat_id: uuid.UUID, user_id: uuid.UUID) -> None:
        """Update last_read timestamp for the user in this chat."""
        result = await self.db.execute(
            select(ChatMember).where(
                ChatMember.chat_id == chat_id, ChatMember.user_id == user_id
            )
        )
        member = result.scalar_one_or_none()
        if member:
            member.last_read = datetime.now(timezone.utc)
            await self.db.flush()

    async def get_or_create_match_chat(self, match_id: uuid.UUID, user_ids: list[uuid.UUID]) -> Chat:
        """Create a DM chat for a match if it doesn't exist yet."""
        result = await self.db.execute(select(Chat).where(Chat.match_id == match_id))
        chat = result.scalar_one_or_none()
        if not chat:
            chat = Chat(match_id=match_id, is_group=False)
            self.db.add(chat)
            await self.db.flush()
            for uid in user_ids:
                self.db.add(ChatMember(chat_id=chat.id, user_id=uid))
            await self.db.flush()
        return chat

    async def get_or_create_trip_chat(self, trip_id: uuid.UUID, trip_name: str) -> Chat:
        """Create a group chat for a trip if it doesn't exist."""
        result = await self.db.execute(select(Chat).where(Chat.trip_id == trip_id))
        chat = result.scalar_one_or_none()
        if not chat:
            chat = Chat(trip_id=trip_id, is_group=True, name=trip_name)
            self.db.add(chat)
            await self.db.flush()
        return chat
