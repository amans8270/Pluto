"""Trip Service — TravelBuddy core logic."""

import uuid

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.trip import Trip, TripMember
from app.models.user import User
from app.repositories.notification_repo import NotificationRepository
from app.schemas.trip import TripCreateRequest
from app.services.chat_service import ChatService
from app.utils.storage import get_storage_provider


class TripService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.storage = get_storage_provider()

    async def list_trips(
        self,
        latitude: float,
        longitude: float,
        radius_km: int,
        category: str | None,
        search: str | None,
        page: int,
    ) -> tuple[list[dict], int]:
        """Geo-query for nearby open trips with optional search/category."""
        where_clauses = [
            "t.status = 'OPEN'",
            "t.start_date >= CURRENT_DATE",
            f"ST_DWithin(t.destination_geom, ST_MakePoint(:lon, :lat)::GEOGRAPHY, :radius_m)",
        ]
        params: dict = {"lat": latitude, "lon": longitude, "radius_m": radius_km * 1000}
        if category:
            where_clauses.append("t.category = :category")
            params["category"] = category
        if search:
            where_clauses.append(
                "to_tsvector('english', t.title || ' ' || t.destination) @@ plainto_tsquery(:search)"
            )
            params["search"] = search

        where_sql = " AND ".join(where_clauses)
        limit = 20
        offset = (page - 1) * limit
        params.update({"limit": limit, "offset": offset})

        query = text(f"""
            SELECT
                t.id, t.title, t.destination, t.category, t.start_date, t.end_date,
                t.max_members, t.entry_fee_inr, t.cover_image_url, t.status,
                t.difficulty, t.temperature,
                COUNT(tm.user_id) AS joined_count,
                (t.max_members - COUNT(tm.user_id)) AS spots_left,
                ROUND((ST_Distance(t.destination_geom, ST_MakePoint(:lon,:lat)::GEOGRAPHY)/1000)::numeric,1) AS dist_km,
                u.id AS creator_id,
                p.display_name AS creator_name,
                (SELECT gcs_url FROM photos WHERE user_id = u.id ORDER BY display_order LIMIT 1) AS creator_photo
            FROM trips t
            JOIN users u ON u.id = t.creator_id
            JOIN profiles p ON p.user_id = u.id
            LEFT JOIN trip_members tm ON tm.trip_id = t.id
            WHERE {where_sql}
            GROUP BY t.id, u.id, p.display_name
            HAVING COUNT(tm.user_id) < t.max_members
            ORDER BY t.start_date ASC
            LIMIT :limit OFFSET :offset
        """)

        result = await self.db.execute(query, params)
        rows = [dict(r) for r in result.mappings().all()]

        # Count
        count_q = text(f"""
            SELECT COUNT(*) FROM (
                SELECT t.id FROM trips t
                LEFT JOIN trip_members tm ON tm.trip_id = t.id
                WHERE {where_sql}
                GROUP BY t.id
                HAVING COUNT(tm.user_id) < t.max_members
            ) sub
        """)
        total = (await self.db.execute(count_q, params)).scalar_one()
        return rows, total

    async def create_trip(self, creator: User, data: TripCreateRequest) -> dict:
        """Create trip + auto-create group chat + add creator as first member."""
        trip = Trip(
            creator_id=creator.id,
            title=data.title,
            description=data.description,
            destination=data.destination,
            category=data.category,
            difficulty=data.difficulty,
            start_date=data.start_date,
            end_date=data.end_date,
            max_members=data.max_members,
            entry_fee_inr=data.entry_fee_inr,
            meeting_point=data.meeting_point,
            temperature=data.temperature,
        )
        if data.destination_lat and data.destination_lon:
            trip.destination_geom = (
                f"SRID=4326;POINT({data.destination_lon} {data.destination_lat})"
            )

        self.db.add(trip)
        await self.db.flush()

        # Creator joins automatically
        self.db.add(TripMember(trip_id=trip.id, user_id=creator.id))

        # Create group chat
        chat_service = ChatService(self.db)
        await chat_service.get_or_create_trip_chat(trip.id, data.title)

        await self.db.flush()
        await self.db.refresh(trip)

        # Return dict with all required fields for response
        return {
            "id": trip.id,
            "title": trip.title,
            "description": trip.description,
            "destination": trip.destination,
            "category": trip.category,
            "difficulty": trip.difficulty,
            "start_date": trip.start_date,
            "end_date": trip.end_date,
            "max_members": trip.max_members,
            "entry_fee_inr": trip.entry_fee_inr,
            "cover_image_url": trip.cover_image_url,
            "meeting_point": trip.meeting_point,
            "temperature": trip.temperature,
            "status": trip.status,
            "created_at": trip.created_at,
            "joined_count": 1,
            "spots_left": trip.max_members - 1,
            "is_owner": True,
            "viewer_status": "MEMBER",
            "application_id": None,
        }

    async def get_trip_detail(self, trip_id: uuid.UUID, viewer_id: uuid.UUID) -> dict:
        result = await self.db.execute(
            select(Trip)
            .options(
                selectinload(Trip.members).selectinload(TripMember.user),
                selectinload(Trip.applications),
            )
            .where(Trip.id == trip_id)
        )
        trip = result.scalar_one_or_none()
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")

        # Calculate status for the viewer
        viewer_status = "NONE"
        application_id = None

        # Is member?
        if any(m.user_id == viewer_id for m in trip.members):
            viewer_status = "MEMBER"
        else:
            # Is applicant?
            from app.models.trip import TripApplicationStatus

            app = next(
                (
                    a
                    for a in trip.applications
                    if a.user_id == viewer_id
                    and a.status != TripApplicationStatus.REJECTED
                ),
                None,
            )
            if app:
                viewer_status = app.status.value
                application_id = app.id

        # Convert to dict for response
        data = {
            "id": trip.id,
            "title": trip.title,
            "description": trip.description,
            "destination": trip.destination,
            "category": trip.category,
            "difficulty": trip.difficulty,
            "start_date": trip.start_date,
            "end_date": trip.end_date,
            "max_members": trip.max_members,
            "entry_fee_inr": trip.entry_fee_inr,
            "cover_image_url": trip.cover_image_url,
            "meeting_point": trip.meeting_point,
            "temperature": trip.temperature,
            "status": trip.status,
            "created_at": trip.created_at,
            "joined_count": len(trip.members),
            "spots_left": trip.max_members - len(trip.members),
            "is_owner": trip.creator_id == viewer_id,
            "viewer_status": viewer_status,
            "application_id": application_id,
        }
        return data

    async def join_trip(
        self, trip_id: uuid.UUID, user: User, payment_ref: str | None
    ) -> uuid.UUID:
        """Join a trip. Validates spots, payment, then adds member + returns chat ID."""
        result = await self.db.execute(select(Trip).where(Trip.id == trip_id))
        trip = result.scalar_one_or_none()
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")

        if trip.status != "OPEN":
            raise HTTPException(status_code=400, detail="This trip is no longer open.")

        # Count current members
        count_result = await self.db.execute(
            select(func.count()).where(TripMember.trip_id == trip_id)
        )
        count = count_result.scalar_one()
        if count >= trip.max_members:
            raise HTTPException(status_code=400, detail="Trip is full.")

        # Check not already a member
        existing = await self.db.execute(
            select(TripMember).where(
                TripMember.trip_id == trip_id, TripMember.user_id == user.id
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=400, detail="Already a member of this trip."
            )

        # Validate payment if fee required
        if trip.entry_fee_inr > 0 and not payment_ref:
            raise HTTPException(
                status_code=402, detail="Payment required to join this trip."
            )

        # Add member
        self.db.add(
            TripMember(trip_id=trip_id, user_id=user.id, payment_ref=payment_ref)
        )

        # If now full, update status
        if count + 1 >= trip.max_members:
            trip.status = "FULL"

        await self.db.flush()

        # Add user to trip group chat
        chat_service = ChatService(self.db)
        chat = await chat_service.get_or_create_trip_chat(trip_id, trip.title)
        from app.models.chat import ChatMember

        self.db.add(ChatMember(chat_id=chat.id, user_id=user.id))
        await self.db.flush()

        # Send system message
        from app.models.profile import Profile

        profile_result = await self.db.execute(
            select(Profile).where(Profile.user_id == user.id)
        )
        profile = profile_result.scalar_one_or_none()
        name = profile.display_name if profile else "Someone"
        await chat_service.send_message(
            chat_id=chat.id,
            sender_id=user.id,
            content=f"🎉 {name} has joined the trip!",
            msg_type="SYSTEM",
        )

        # Notify trip creator
        notif_repo = NotificationRepository(self.db)
        await notif_repo.create(
            user_id=trip.creator_id,
            type="TRIP_JOIN",
            title="New member joined your trip! 🧳",
            body=f"{name} just joined {trip.title}",
            data={"trip_id": str(trip_id)},
        )

        return chat.id

    async def cancel_trip(
        self, trip_id: uuid.UUID, requesting_user_id: uuid.UUID
    ) -> None:
        result = await self.db.execute(select(Trip).where(Trip.id == trip_id))
        trip = result.scalar_one_or_none()
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")
        if trip.creator_id != requesting_user_id:
            raise HTTPException(
                status_code=403, detail="Only the trip creator can cancel it."
            )
        trip.status = "CANCELLED"
        await self.db.flush()

    async def upload_cover_image(
        self, trip_id: uuid.UUID, creator_id: uuid.UUID, file: UploadFile
    ) -> str:
        result = await self.db.execute(select(Trip).where(Trip.id == trip_id))
        trip = result.scalar_one_or_none()
        if not trip or trip.creator_id != creator_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        url = await self.storage.upload(file=file, folder=f"trips/{trip_id}")
        trip.cover_image_url = url
        await self.db.flush()
        return url

    async def get_user_trips(self, user_id: uuid.UUID) -> tuple[list, int]:
        query = (
            select(Trip)
            .join(TripMember, TripMember.trip_id == Trip.id)
            .where(TripMember.user_id == user_id)
            .order_by(Trip.start_date.asc())
        )
        result = await self.db.execute(query)
        trips = result.scalars().all()

        trip_dicts = []
        for t in trips:
            # Get member count
            count_result = await self.db.execute(
                select(func.count()).where(TripMember.trip_id == t.id)
            )
            joined_count = count_result.scalar_one()
            trip_dicts.append(
                {
                    "id": t.id,
                    "title": t.title,
                    "destination": t.destination,
                    "category": t.category,
                    "start_date": t.start_date,
                    "end_date": t.end_date,
                    "max_members": t.max_members,
                    "entry_fee_inr": t.entry_fee_inr,
                    "cover_image_url": t.cover_image_url,
                    "status": t.status,
                    "joined_count": joined_count,
                    "spots_left": t.max_members - joined_count,
                }
            )
        return trip_dicts, len(trip_dicts)
