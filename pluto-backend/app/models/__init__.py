"""SQLAlchemy models package — imports all models so Alembic can discover them."""
from app.models.user import User
from app.models.profile import Profile
from app.models.photo import Photo
from app.models.interest import Interest, UserInterest
from app.models.location import Location
from app.models.swipe import Swipe
from app.models.match import Match
from app.models.chat import Chat, ChatMember
from app.models.message import Message
from app.models.trip import (Trip, TripMember, TripApplication,
                             TripApplicationStatus, GroupApproval, TripPayment)
from app.models.notification import Notification
from app.models.block import Block, Report

__all__ = [
    "User", "Profile", "Photo", "Interest", "UserInterest",
    "Location", "Swipe", "Match", "Chat", "ChatMember",
    "Message", "Trip", "TripMember", "TripApplication",
    "TripApplicationStatus", "GroupApproval", "TripPayment", "Notification",
    "Block", "Report",
]
