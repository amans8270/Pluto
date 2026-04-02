"""Notifications API."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.notification import NotificationListResponse
from app.repositories.notification_repo import NotificationRepository

router = APIRouter()


@router.get("/", response_model=NotificationListResponse)
async def list_notifications(
    unread_only: bool = Query(False),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get notifications for the current user, sorted by newest first."""
    repo = NotificationRepository(db)
    notifications, total = await repo.get_for_user(
        user_id=current_user.id,
        unread_only=unread_only,
        page=page,
        limit=limit,
    )
    return NotificationListResponse(notifications=notifications, total=total, page=page)


@router.put("/read-all", status_code=204)
async def mark_all_read(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark all unread notifications as read."""
    repo = NotificationRepository(db)
    await repo.mark_all_read(user_id=current_user.id)


@router.get("/unread-count")
async def unread_count(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get count of unread notifications (used for badge on app icon)."""
    repo = NotificationRepository(db)
    count = await repo.get_unread_count(user_id=current_user.id)
    return {"unread_count": count}
