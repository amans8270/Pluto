"""Trips API — TravelBuddy mode."""
import uuid
from fastapi import APIRouter, Depends, File, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.models.trip import Trip, TripMember
from app.schemas.trip import (TripCreateRequest, TripDetailResponse,
                               TripListResponse, TripJoinRequest)
from app.schemas.workflow import (TripApplicationResponse, TripPaymentRequest,
                                   TripMemberResponse, GroupApprovalStatusResponse)
from app.services.trip_service import TripService
from app.services.workflow_service import WorkflowService

router = APIRouter()


@router.get("/", response_model=TripListResponse)
async def list_trips(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius_km: int = Query(500, ge=10, le=2000),
    category: str | None = Query(None),
    search: str | None = Query(None),
    page: int = Query(1, ge=1),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Browse open trips nearby, with optional search and category filter."""
    service = TripService(db)
    trips, total = await service.list_trips(
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        category=category,
        search=search,
        page=page,
    )
    return TripListResponse(trips=trips, total=total, page=page)


@router.post("/", response_model=TripDetailResponse, status_code=status.HTTP_201_CREATED)
async def create_trip(
    body: TripCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new trip. Creator is automatically added as first member."""
    service = TripService(db)
    return await service.create_trip(creator=current_user, data=body)


@router.get("/my-trips", response_model=TripListResponse)
async def my_trips(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all trips created by or joined by the current user."""
    service = TripService(db)
    trips, total = await service.get_user_trips(user_id=current_user.id)
    return TripListResponse(trips=trips, total=total, page=1)


@router.get("/{trip_id}", response_model=TripDetailResponse)
async def get_trip(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get full trip details including member list and group chat ID."""
    service = TripService(db)
    return await service.get_trip_detail(trip_id=trip_id, viewer_id=current_user.id)


@router.post("/{trip_id}/join", status_code=status.HTTP_200_OK)
async def join_trip(
    trip_id: uuid.UUID,
    body: TripJoinRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Join a trip. For paid trips, requires a payment_ref (Razorpay order ID).
    Returns the trip's group chat ID.
    """
    service = TripService(db)
    chat_id = await service.join_trip(
        trip_id=trip_id,
        user=current_user,
        payment_ref=body.payment_ref,
    )
    return {"success": True, "chat_id": str(chat_id), "message": "You've joined the trip! 🎉"}


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_trip(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel (soft-delete) a trip. Only the creator can do this."""
    service = TripService(db)
    await service.cancel_trip(trip_id=trip_id, requesting_user_id=current_user.id)


@router.post("/{trip_id}/cover", status_code=status.HTTP_200_OK)
async def upload_trip_cover(
    trip_id: uuid.UUID,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Upload cover image for a trip."""
    service = TripService(db)
    url = await service.upload_cover_image(trip_id=trip_id, creator_id=current_user.id, file=file)
    return {"cover_image_url": url}


# ── Travel Buddy Workflow ──────────────────────────────────────────

@router.post("/{trip_id}/apply", response_model=TripApplicationResponse)
async def apply_to_trip(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """User applies to join a trip."""
    service = WorkflowService(db)
    return await service.apply_for_trip(trip_id=trip_id, user_id=current_user.id)


@router.get("/{trip_id}/applications", response_model=list[TripApplicationResponse])
async def list_trip_applications(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Trip owner sees all applicants."""
    service = WorkflowService(db)
    apps = await service.list_applications(trip_id=trip_id, owner_id=current_user.id)
    return [
        TripApplicationResponse(
            id=a.id, trip_id=a.trip_id, user_id=a.user_id, status=a.status,
            created_at=a.created_at, updated_at=a.updated_at,
            username=a.user.username if a.user else "User",
            photo_url=None
        ) for a in apps
    ]


@router.post("/applications/{id}/owner-approve", response_model=TripApplicationResponse)
async def owner_approve_application(
    id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Trip owner approves an applicant."""
    service = WorkflowService(db)
    return await service.owner_approve(application_id=id, owner_id=current_user.id)


@router.post("/applications/{id}/group-approve", response_model=TripApplicationResponse)
async def group_vote_application(
    id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Existing members vote for an applicant."""
    service = WorkflowService(db)
    return await service.group_vote(application_id=id, voter_id=current_user.id)


@router.get("/applications/{id}/status", response_model=GroupApprovalStatusResponse)
async def get_application_approval_status(
    id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current vote count for an application."""
    service = WorkflowService(db)
    result = await service.get_approval_status(application_id=id)
    return GroupApprovalStatusResponse(**result)


@router.post("/applications/{id}/pay", response_model=bool)
async def pay_and_finalize(
    id: uuid.UUID,
    body: TripPaymentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Finalize membership using promo code (or payment in future)."""
    service = WorkflowService(db)
    await service.finalize_with_promo(application_id=id, user_id=current_user.id, promo=body.promo_code)
    return True


@router.get("/{trip_id}/members", response_model=list[TripMemberResponse])
async def list_trip_members(
    trip_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all finalized members of a trip."""
    # Simple query for now
    stmt = select(TripMember).options(selectinload(TripMember.user)).where(TripMember.trip_id == trip_id)
    result = await db.execute(stmt)
    members = result.scalars().all()
    
    # We also need to know who the owner is for the response
    stmt_trip = select(Trip).where(Trip.id == trip_id)
    trip = (await db.execute(stmt_trip)).scalar_one_or_none()
    owner_id = trip.creator_id if trip else None

    return [
        TripMemberResponse(
            user_id=m.user_id,
            username=m.user.username if m.user else "User",
            photo_url=None, 
            joined_at=m.joined_at,
            is_owner=(m.user_id == owner_id)
        ) for m in members
    ]
