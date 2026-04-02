"""Pydantic schemas for Auth."""

from pydantic import BaseModel


class AuthVerifyRequest(BaseModel):
    id_token: str
    fcm_token: str | None = None


class AuthResponse(BaseModel):
    user_id: str
    supabase_uid: str
    email: str | None
    is_new_user: bool
    needs_onboarding: bool
