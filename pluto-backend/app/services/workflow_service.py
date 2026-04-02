"""Travel Buddy Workflow Service."""
import uuid
from datetime import datetime, timezone
from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.trip import Trip, TripMember, TripApplication, TripApplicationStatus, GroupApproval, TripPayment
from app.services.trip_service import TripService
from app.services.chat_service import ChatService


class WorkflowService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def apply_for_trip(self, trip_id: uuid.UUID, user_id: uuid.UUID) -> TripApplication:
        """User applies to join a trip."""
        # 1. Check trip exists and is OPEN
        stmt = select(Trip).where(Trip.id == trip_id)
        trip = (await self.db.execute(stmt)).scalar_one_or_none()
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")
        if trip.status != "OPEN":
            raise HTTPException(status_code=400, detail="Trip is not open for applications.")

        # 2. Check not already a member
        stmt = select(TripMember).where(TripMember.trip_id == trip_id, TripMember.user_id == user_id)
        if (await self.db.execute(stmt)).scalar_one_or_none():
            raise HTTPException(status_code=400, detail="You are already a member of this trip.")

        # 3. Check existing non-rejected application
        stmt = select(TripApplication).where(
            TripApplication.trip_id == trip_id,
            TripApplication.user_id == user_id,
            TripApplication.status != TripApplicationStatus.REJECTED
        )
        if (await self.db.execute(stmt)).scalar_one_or_none():
            raise HTTPException(status_code=400, detail="You already have an active application.")

        # 4. Create application
        application = TripApplication(trip_id=trip_id, user_id=user_id, status=TripApplicationStatus.APPLIED)
        self.db.add(application)
        await self.db.flush()
        return application

    async def list_applications(self, trip_id: uuid.UUID, owner_id: uuid.UUID) -> list[TripApplication]:
        """Trip owner views all applications."""
        stmt = select(Trip).where(Trip.id == trip_id)
        trip = (await self.db.execute(stmt)).scalar_one_or_none()
        if not trip or trip.creator_id != owner_id:
            raise HTTPException(status_code=403, detail="Not authorized to view applications.")

        stmt = select(TripApplication).options(
            selectinload(TripApplication.user)
        ).where(TripApplication.trip_id == trip_id).order_by(TripApplication.created_at.desc())
        
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def owner_approve(self, application_id: uuid.UUID, owner_id: uuid.UUID) -> TripApplication:
        """Owner approves or rejects an applicant."""
        stmt = select(TripApplication).options(selectinload(TripApplication.trip)).where(TripApplication.id == application_id)
        app = (await self.db.execute(stmt)).scalar_one_or_none()
        if not app:
            raise HTTPException(status_code=404, detail="Application not found.")
        
        if app.trip.creator_id != owner_id:
            raise HTTPException(status_code=403, detail="Only the trip creator can approve applications.")
        
        if app.status != TripApplicationStatus.APPLIED:
            raise HTTPException(status_code=400, detail="Application already processed.")

        app.status = TripApplicationStatus.OWNER_APPROVED
        
        # Check current member count to determine next state
        stmt = select(func.count()).where(TripMember.trip_id == app.trip_id)
        member_count = (await self.db.execute(stmt)).scalar_one()

        if member_count <= 1:
            # Only owner is present, so group approval is trivial (no one else to vote)
            app.status = TripApplicationStatus.GROUP_APPROVED
        else:
            app.status = TripApplicationStatus.GROUP_PENDING

        await self.db.flush()
        return app

    async def group_vote(self, application_id: uuid.UUID, voter_id: uuid.UUID) -> TripApplication:
        """Existing members vote on an application."""
        stmt = select(TripApplication).options(selectinload(TripApplication.trip)).where(TripApplication.id == application_id)
        app = (await self.db.execute(stmt)).scalar_one_or_none()
        if not app:
            raise HTTPException(status_code=404, detail="Application not found.")
        
        if app.status != TripApplicationStatus.GROUP_PENDING:
            raise HTTPException(status_code=400, detail="Application is not in group voting stage.")

        # Only members can vote
        stmt = select(TripMember).where(TripMember.trip_id == app.trip_id, TripMember.user_id == voter_id)
        if not (await self.db.execute(stmt)).scalar_one_or_none():
            raise HTTPException(status_code=403, detail="Only trip members can vote.")

        # No duplicate votes
        stmt = select(GroupApproval).where(GroupApproval.application_id == application_id, GroupApproval.voter_id == voter_id)
        if (await self.db.execute(stmt)).scalar_one_or_none():
            raise HTTPException(status_code=400, detail="You have already voted.")

        # Add vote
        vote = GroupApproval(application_id=application_id, voter_id=voter_id)
        self.db.add(vote)
        await self.db.flush()

        # Check threshold
        stmt = select(func.count()).where(TripMember.trip_id == app.trip_id)
        member_count = (await self.db.execute(stmt)).scalar_one()
        required = min(member_count, 3)

        stmt = select(func.count()).where(GroupApproval.application_id == application_id)
        current_votes = (await self.db.execute(stmt)).scalar_one()

        if current_votes >= required:
            app.status = TripApplicationStatus.GROUP_APPROVED
            await self.db.flush()

        return app

    async def finalize_with_promo(self, application_id: uuid.UUID, user_id: uuid.UUID, promo: str) -> TripMember:
        """Finalize joining using promo code."""
        if promo != "NEWAPP":
            raise HTTPException(status_code=400, detail="Invalid promo code.")

        stmt = select(TripApplication).options(selectinload(TripApplication.trip)).where(TripApplication.id == application_id)
        app = (await self.db.execute(stmt)).scalar_one_or_none()
        if not app or app.user_id != user_id:
            raise HTTPException(status_code=403, detail="Not authorized.")
        
        if app.status != TripApplicationStatus.GROUP_APPROVED:
            raise HTTPException(status_code=400, detail="Application not approved by group yet.")

        # Create free payment record
        payment = TripPayment(
            trip_id=app.trip_id,
            user_id=user_id,
            amount=0,
            status="SUCCESS",
            promo_code=promo
        )
        self.db.add(payment)

        # Add to TripMember
        member = TripMember(trip_id=app.trip_id, user_id=user_id, joined_at=datetime.now(timezone.utc))
        self.db.add(member)
        
        app.status = TripApplicationStatus.FINALIZED
        
        # Add to Group Chat
        chat_service = ChatService(self.db)
        chat = await chat_service.get_or_create_trip_chat(app.trip_id, app.trip.title)
        from app.models.chat import ChatMember
        self.db.add(ChatMember(chat_id=chat.id, user_id=user_id))

        await self.db.flush()
        return member

    async def get_approval_status(self, application_id: uuid.UUID) -> dict:
        """Get details about current votes."""
        stmt = select(TripApplication).where(TripApplication.id == application_id)
        app = (await self.db.execute(stmt)).scalar_one_or_none()
        if not app:
            raise HTTPException(status_code=404, detail="Application not found.")

        stmt = select(func.count()).where(TripMember.trip_id == app.trip_id)
        member_count = (await self.db.execute(stmt)).scalar_one()
        required = min(member_count, 3)

        stmt = select(GroupApproval.voter_id).where(GroupApproval.application_id == application_id)
        voters = (await self.db.execute(stmt)).scalars().all()

        return {
            "application_id": application_id,
            "required_approvals": required,
            "current_approvals": len(voters),
            "voters": list(voters)
        }
