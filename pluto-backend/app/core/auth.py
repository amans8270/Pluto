"""Unified auth token verification for supported identity providers."""

from app.core.firebase import verify_firebase_token
from app.core.supabase import verify_supabase_token


async def verify_auth_token(id_token: str) -> dict:
    """
    Verify a user token from a supported provider and normalize claims.

    Normalized output always includes:
    - sub
    - email
    - phone
    - provider
    """
    errors: list[str] = []

    try:
        claims = await verify_supabase_token(id_token)
        return {
            "sub": claims.get("sub"),
            "email": claims.get("email"),
            "phone": claims.get("phone"),
            "provider": "supabase",
            "raw_claims": claims,
        }
    except Exception as exc:
        errors.append(str(exc))

    try:
        claims = await verify_firebase_token(id_token)
        return {
            "sub": claims.get("uid") or claims.get("sub"),
            "email": claims.get("email"),
            "phone": claims.get("phone_number"),
            "provider": "firebase",
            "raw_claims": claims,
        }
    except Exception as exc:
        errors.append(str(exc))

    raise ValueError("; ".join(errors) if errors else "Token verification failed.")
