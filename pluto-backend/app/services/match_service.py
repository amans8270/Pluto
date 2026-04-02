"""
Match Service — Discover feed + Swipe recording + Match detection.
"""
import json
import uuid
from datetime import datetime, timezone

import structlog
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.cache import cache_get, cache_set
from app.models.match import Match
from app.models.swipe import Swipe
from app.models.user import User
from app.repositories.notification_repo import NotificationRepository

logger = structlog.get_logger(__name__)


class MatchService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_discover_feed(
        self,
        user: User,
        mode: str,
        min_age: int,
        max_age: int,
        radius_km: int,
        gender_filter: str | None,
        target_lat: float | None = None,
        target_lon: float | None = None,
    ) -> list[dict]:
        """
        Returns candidate profiles for the swipe deck.
        Checks Redis cache first (TTL 5 min). Falls back to DB query.
        """
        cache_key = f"discover:{user.id}:{mode}:{min_age}:{max_age}:{radius_km}:{gender_filter}:{target_lat}:{target_lon}"
        cached = await cache_get(cache_key)
        if cached:
            return json.loads(cached)

        # 1. Determine search center (passed-in or from DB)
        lat, lon = target_lat, target_lon
        
        if lat is None or lon is None:
            # Fallback: Get user location from DB
            loc_result = await self.db.execute(
                text("SELECT ST_X(geom::geometry) as lon, ST_Y(geom::geometry) as lat FROM locations WHERE user_id = :uid"),
                {"uid": str(user.id)},
            )
            loc = loc_result.fetchone()
            if loc:
                lat, lon = loc.lat, loc.lon
            else:
                # Still no location? Return empty or some default "landing" location
                return []
        else:
            # If coordinates were passed, update the user's location in the background (upsert)
            from app.repositories.user_repo import UserRepository
            repo = UserRepository(self.db)
            await repo.update_location(user.id, lat, lon)
        mode_col = {"DATE": "date_visible", "TRAVELBUDDY": "travel_visible", "BFF": "bff_visible"}[mode]

        gender_clause = "AND p.gender = :gender" if gender_filter else ""
        query = text(f"""
            SELECT
                u.id,
                p.display_name,
                p.age,
                p.bio,
                p.gender,
                p.occupation,
                ROUND((ST_Distance(l.geom, ST_MakePoint(:lon, :lat)::GEOGRAPHY) / 1000)::numeric, 1) AS dist_km,
                COALESCE(
                    (SELECT json_agg(ph.gcs_url ORDER BY ph.display_order)
                     FROM photos ph WHERE ph.user_id = u.id LIMIT 6), '[]'
                ) AS photos,
                COALESCE(
                    (SELECT json_agg(i.name)
                     FROM user_interests ui JOIN interests i ON i.id = ui.interest_id
                     WHERE ui.user_id = u.id), '[]'
                ) AS interests
            FROM users u
            JOIN profiles p     ON p.user_id = u.id
            JOIN locations l    ON l.user_id = u.id
            WHERE u.is_active = TRUE
              AND p.{mode_col} = TRUE
              AND p.age BETWEEN :min_age AND :max_age
              AND ST_DWithin(l.geom, ST_MakePoint(:lon, :lat)::GEOGRAPHY, :radius_m)
              AND u.id != :me
              {gender_clause}
              AND u.id NOT IN (
                  SELECT swiped_id FROM swipes
                  WHERE swiper_id = :me AND mode = :mode
              )
              AND u.id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = :me)
            ORDER BY dist_km, RANDOM()
            LIMIT 20
        """)

        params = {
            "lat": lat, "lon": lon, "min_age": min_age, "max_age": max_age,
            "radius_m": radius_km * 1000, "me": str(user.id), "mode": mode,
        }
        if gender_filter:
            params["gender"] = gender_filter

        result = await self.db.execute(query, params)
        rows = result.mappings().all()
        candidates = [dict(r) for r in rows]

        # Cache for 5 minutes
        await cache_set(cache_key, json.dumps(candidates, default=str), ttl=300)
        return candidates

    async def record_swipe(self, swiper: User, swiped_id: uuid.UUID, mode: str, action: str) -> dict:
        """Record swipe. If mutual LIKE → create match + notify."""
        # Insert swipe (ignore if already swiped in this mode)
        swipe = Swipe(swiper_id=swiper.id, swiped_id=swiped_id, mode=mode, action=action)
        self.db.add(swipe)
        await self.db.flush()

        matched = False
        match_id = None

        if action in ("LIKE", "SUPERLIKE"):
            # Check if the target has already liked us back in this mode
            mutual = await self.db.execute(
                select(Swipe).where(
                    Swipe.swiper_id == swiped_id,
                    Swipe.swiped_id == swiper.id,
                    Swipe.mode == mode,
                    Swipe.action.in_(["LIKE", "SUPERLIKE"]),
                )
            )
            if mutual.scalar_one_or_none():
                # Create match (enforce ordered user IDs)
                a, b = sorted([swiper.id, swiped_id], key=str)
                match = Match(user_a_id=a, user_b_id=b, mode=mode)
                self.db.add(match)
                await self.db.flush()
                matched = True
                match_id = str(match.id)

                # Create notification for the other user
                notif_repo = NotificationRepository(self.db)
                await notif_repo.create(
                    user_id=swiped_id,
                    type="MATCH",
                    title="You have a new match! 🎉",
                    body=f"You and someone matched in {mode} mode!",
                    data={"match_id": match_id, "mode": mode},
                )

        return {"matched": matched, "match_id": match_id, "mode": mode}

    async def list_matches(self, user_id: uuid.UUID, mode: str | None) -> list[dict]:
        query = select(Match).where(
            ((Match.user_a_id == user_id) | (Match.user_b_id == user_id)),
            Match.status == "ACTIVE",
        )
        if mode:
            query = query.where(Match.mode == mode)
        query = query.order_by(Match.created_at.desc())
        result = await self.db.execute(query)
        return result.scalars().all()

    async def unmatch(self, match_id: uuid.UUID, requesting_user_id: uuid.UUID) -> None:
        result = await self.db.execute(select(Match).where(Match.id == match_id))
        match = result.scalar_one_or_none()
        if not match:
            from fastapi import HTTPException
            raise HTTPException(status_code=404, detail="Match not found")
        if requesting_user_id not in (match.user_a_id, match.user_b_id):
            from fastapi import HTTPException
            raise HTTPException(status_code=403, detail="Not your match")
        match.status = "UNMATCHED"
        await self.db.flush()
