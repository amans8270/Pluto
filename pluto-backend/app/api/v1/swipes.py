"""Swipe & Discover API."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.cache import cache_get, cache_set, cache_invalidate_prefix
from app.models.user import User
from app.schemas.swipe import SwipeRequest, SwipeResponse, DiscoverResponse
from app.services.match_service import MatchService

router = APIRouter()


@router.get("/discover", response_model=DiscoverResponse)
async def discover(
    mode: str = Query("DATE", regex="^(DATE|TRAVELBUDDY|BFF)$"),
    min_age: int = Query(18, ge=18, le=80),
    max_age: int = Query(35, ge=18, le=80),
    radius_km: int = Query(50, ge=1, le=500),
    gender: str | None = Query(None),
    lat: float | None = Query(None, ge=-90, le=90),
    lon: float | None = Query(None, ge=-180, le=180),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get a paginated list of candidate profiles for the swipe deck.
    Results are cached per user in memory (TTL 5 min).
    """
    service = MatchService(db)
    candidates = await service.get_discover_feed(
        user=current_user,
        mode=mode,
        min_age=min_age,
        max_age=max_age,
        radius_km=radius_km,
        gender_filter=gender,
        target_lat=lat,
        target_lon=lon,
    )
    return DiscoverResponse(candidates=candidates, mode=mode)


@router.post("/", response_model=SwipeResponse, status_code=201)
async def record_swipe(
    body: SwipeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Record a swipe action (LIKE / DISLIKE / SUPERLIKE).
    Returns whether a match was created.
    """
    service = MatchService(db)
    result = await service.record_swipe(
        swiper=current_user,
        swiped_id=body.target_user_id,
        mode=body.mode,
        action=body.action,
    )
    return result
