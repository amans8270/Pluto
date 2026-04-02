"""Auth API — Supabase JWT verification + user registration."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.auth import verify_auth_token
from app.core.database import get_db
from app.models.user import User
from app.repositories.user_repo import UserRepository
from app.schemas.auth import AuthVerifyRequest, AuthResponse

router = APIRouter()


@router.post("/verify", response_model=AuthResponse, status_code=status.HTTP_200_OK)
async def verify_token(
    body: AuthVerifyRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Verify a Supabase ID token. If the user doesn't exist, create them.
    Returns basic user info and whether onboarding is needed.
    """
    try:
        claims = await verify_auth_token(body.id_token)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))

    auth_uid = claims["sub"]
    repo = UserRepository(db)

    user = await repo.get_by_supabase_uid(auth_uid)
    is_new_user = False

    if not user:
        # Create new user record
        user = await repo.create(
            supabase_uid=auth_uid,
            email=claims.get("email"),
            phone=claims.get("phone"),
        )
        user.profile = None  # Avoid lazy-load attempt on fresh object
        is_new_user = True

    # Update FCM token if provided
    if body.fcm_token:
        await repo.update_fcm_token(user.id, body.fcm_token)

    return AuthResponse(
        user_id=str(user.id),
        supabase_uid=user.supabase_uid,
        email=user.email,
        auth_provider=claims.get("provider"),
        is_new_user=is_new_user,
        needs_onboarding=not user.profile or not user.profile.is_profile_complete,
    )


@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Permanently delete the authenticated user's account."""
    repo = UserRepository(db)
    await repo.delete(current_user.id)
