"""Notification Repository."""
import uuid
from sqlalchemy import select, update, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification


class NotificationRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, user_id: uuid.UUID, type: str, title: str, body: str, data: dict | None = None) -> Notification:
        notif = Notification(user_id=user_id, type=type, title=title, body=body, data=data)
        self.db.add(notif)
        await self.db.flush()
        return notif

    async def get_for_user(
        self, user_id: uuid.UUID, unread_only: bool, page: int, limit: int
    ) -> tuple[list[Notification], int]:
        query = select(Notification).where(Notification.user_id == user_id)
        if unread_only:
            query = query.where(Notification.is_read == False)
        query = query.order_by(Notification.created_at.desc())

        count_q = select(func.count()).select_from(query.subquery())
        total = (await self.db.execute(count_q)).scalar_one()

        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)
        result = await self.db.execute(query)
        return result.scalars().all(), total

    async def mark_all_read(self, user_id: uuid.UUID) -> None:
        await self.db.execute(
            update(Notification)
            .where(Notification.user_id == user_id, Notification.is_read == False)
            .values(is_read=True)
        )

    async def get_unread_count(self, user_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.count())
            .where(Notification.user_id == user_id, Notification.is_read == False)
        )
        return result.scalar_one()
