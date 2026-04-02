"""User Repository — all DB queries for users and profiles."""

import uuid
from sqlalchemy import select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.user import User
from app.models.profile import Profile
from app.models.location import Location
from app.models.interest import UserInterest


class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        result = await self.db.execute(
            select(User)
            .options(
                selectinload(User.profile),
                selectinload(User.photos),
                selectinload(User.location),
                selectinload(User.user_interests).selectinload(UserInterest.interest),
            )
            .where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_supabase_uid(self, supabase_uid: str) -> User | None:
        result = await self.db.execute(
            select(User)
            .options(selectinload(User.profile))
            .where(User.supabase_uid == supabase_uid)
        )
        return result.scalar_one_or_none()

    async def create(
        self, supabase_uid: str, email: str | None, phone: str | None
    ) -> User:
        user = User(supabase_uid=supabase_uid, email=email, phone=phone)
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def update_fcm_token(self, user_id: uuid.UUID, token: str) -> None:
        await self.db.execute(
            update(User).where(User.id == user_id).values(fcm_token=token)
        )

    async def delete(self, user_id: uuid.UUID) -> None:
        await self.db.execute(delete(User).where(User.id == user_id))

    async def update_location(
        self,
        user_id: uuid.UUID,
        lat: float,
        lon: float,
        city: str | None = None,
        country: str = "India",
    ) -> None:
        """
        Upsert user location using PostGIS.
        SECURITY: Coordinates are blurred to ~100m precision (3 decimal places).
        """
        # Blur coordinates to ~100m precision to prevent stalking
        blurred_lat = round(lat, 3)
        blurred_lon = round(lon, 3)

        result = await self.db.execute(
            select(Location).where(Location.user_id == user_id)
        )
        loc = result.scalar_one_or_none()
        if loc:
            loc.geom = f"SRID=4326;POINT({blurred_lon} {blurred_lat})"
            loc.city = city
            loc.country = country
        else:
            loc = Location(
                user_id=user_id,
                geom=f"SRID=4326;POINT({blurred_lon} {blurred_lat})",
                city=city,
                country=country,
            )
            self.db.add(loc)
        await self.db.flush()

    async def set_interests(self, user_id: uuid.UUID, interest_ids: list[int]) -> None:
        """Replace all interests for a user (2 queries instead of N+1)."""
        from sqlalchemy.dialects.postgresql import insert as pg_insert
        # Delete existing
        await self.db.execute(
            delete(UserInterest).where(UserInterest.user_id == user_id)
        )
        # Bulk insert new ones in a single query
        if interest_ids:
            await self.db.execute(
                pg_insert(UserInterest).values(
                    [{"user_id": user_id, "interest_id": iid} for iid in interest_ids]
                )
            )
        await self.db.flush()
