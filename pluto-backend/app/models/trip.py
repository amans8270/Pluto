import enum
import uuid
from datetime import datetime, timezone

# NOTE: geoalchemy2 removed — requires GDAL C library not available on FastAPI Cloud.
# Spatial destination columns stored as lat/lon floats; migrations manage the PostGIS geom.
from sqlalchemy import (Boolean, Date, DateTime, Float, ForeignKey, Numeric,
                        SmallInteger, String, Text)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Trip(Base):
    __tablename__ = "trips"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    creator_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    destination: Mapped[str] = mapped_column(String(200), nullable=False)
    destination_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    destination_lon: Mapped[float | None] = mapped_column(Float, nullable=True)
    category: Mapped[str | None] = mapped_column(String(60), nullable=True)   # Adventure, Cultural, Leisure
    difficulty: Mapped[str | None] = mapped_column(String(30), nullable=True)  # Easy / Moderate / Hard
    start_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    end_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    max_members: Mapped[int] = mapped_column(SmallInteger, default=12)
    entry_fee_inr: Mapped[float] = mapped_column(Numeric(10, 2), default=0)
    cover_image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(15), default="OPEN")            # OPEN|FULL|ONGOING|COMPLETED|CANCELLED
    meeting_point: Mapped[str | None] = mapped_column(Text, nullable=True)
    meeting_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    meeting_lon: Mapped[float | None] = mapped_column(Float, nullable=True)
    temperature: Mapped[str | None] = mapped_column(String(20), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)  # Soft delete
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    creator: Mapped["User"] = relationship("User")
    members: Mapped[list["TripMember"]] = relationship("TripMember", back_populates="trip", lazy="select")
    applications: Mapped[list["TripApplication"]] = relationship("TripApplication", back_populates="trip", lazy="select")


class TripApplicationStatus(str, enum.Enum):
    APPLIED = "APPLIED"
    OWNER_APPROVED = "OWNER_APPROVED"
    GROUP_PENDING = "GROUP_PENDING"
    GROUP_APPROVED = "GROUP_APPROVED"
    REJECTED = "REJECTED"
    FINALIZED = "FINALIZED"


class TripApplication(Base):
    __tablename__ = "trip_applications"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("trips.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status: Mapped[TripApplicationStatus] = mapped_column(String(20), default=TripApplicationStatus.APPLIED)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    trip: Mapped["Trip"] = relationship("Trip", back_populates="applications")
    user: Mapped["User"] = relationship("User")
    approvals: Mapped[list["GroupApproval"]] = relationship("GroupApproval", back_populates="application", lazy="select")


class GroupApproval(Base):
    __tablename__ = "group_approvals"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    application_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("trip_applications.id", ondelete="CASCADE"), nullable=False, index=True)
    voter_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relationships
    application: Mapped["TripApplication"] = relationship("TripApplication", back_populates="approvals")
    voter: Mapped["User"] = relationship("User")


class TripPayment(Base):
    __tablename__ = "trip_payments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("trips.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="PENDING")
    payment_ref: Mapped[str | None] = mapped_column(String(100), nullable=True)
    promo_code: Mapped[str | None] = mapped_column(String(20), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relationships
    trip: Mapped["Trip"] = relationship("Trip")
    user: Mapped["User"] = relationship("User")


class TripMember(Base):
    __tablename__ = "trip_members"

    trip_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("trips.id", ondelete="CASCADE"), primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    joined_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    payment_ref: Mapped[str | None] = mapped_column(String(100), nullable=True)  # Razorpay/Stripe payment ID

    # Relationships
    trip: Mapped["Trip"] = relationship("Trip", back_populates="members")
    user: Mapped["User"] = relationship("User")
