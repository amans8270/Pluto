"""Matches API."""
import uuid
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.match import MatchListResponse, MatchResponse
from app.services.match_service import MatchService

router = APIRouter()


@router.get("/", response_model=MatchListResponse)
async def list_matches(
    mode: str | None = Query(None, regex="^(DATE|TRAVELBUDDY|BFF)$"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all active matches for the current user, optionally filtered by mode."""
    service = MatchService(db)
    matches = await service.list_matches(user_id=current_user.id, mode=mode)
    return MatchListResponse(matches=matches, total=len(matches))


@router.delete("/{match_id}", status_code=204)
async def unmatch(
    match_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Unmatch from a user."""
    service = MatchService(db)
    await service.unmatch(match_id=match_id, requesting_user_id=current_user.id)
