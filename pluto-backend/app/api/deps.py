from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import verify_auth_token
from app.core.database import get_db
from app.models.user import User
from app.repositories.user_repo import UserRepository

bearer_scheme = HTTPBearer(auto_error=True)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    FastAPI dependency: verifies Supabase JWT and returns the authenticated User.
    Raises HTTP 401 if token is invalid or user does not exist.
    """
    token = credentials.credentials
    try:
        claims = await verify_auth_token(token)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )

    auth_uid = claims.get("sub")
    if not auth_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token claims"
        )

    repo = UserRepository(db)
    user = await repo.get_by_supabase_uid(auth_uid)

    if not user:
        # JIT Provisioning: Create user record if valid token but no DB entry
        user = await repo.create(
            supabase_uid=auth_uid,
            email=claims.get("email"),
            phone=claims.get("phone"),
        )
        # Avoid lazy-load issues with SQLA on a fresh object that hasn't loaded relationships
        user.profile = None

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated."
        )

    return user


async def get_current_user_optional(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        HTTPBearer(auto_error=False)
    ),
    db: AsyncSession = Depends(get_db),
) -> User | None:
    """Same as get_current_user but returns None if not authenticated."""
    if not credentials:
        return None
    try:
        return await get_current_user(credentials, db)
    except HTTPException:
        return None
