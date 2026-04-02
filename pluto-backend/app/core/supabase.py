"""
Supabase Auth — JWT verification using local JWKS (no network calls per request).
~20x faster than network verification.
"""

from functools import lru_cache
import jwt
from jwt import PyJWKClient
from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions
from app.core.config import settings

_supabase_client: Client | None = None
_supabase_service_client: Client | None = None


def get_supabase_client() -> Client:
    global _supabase_client
    if _supabase_client is None:
        if not settings.SUPABASE_URL or not settings.SUPABASE_ANON_KEY:
            raise ValueError("SUPABASE_URL and SUPABASE_ANON_KEY must be set")
        _supabase_client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_ANON_KEY,
            options=ClientOptions(
                auto_refresh_token=False,
                persist_session=False,
            ),
        )
    return _supabase_client


def get_supabase_service_client() -> Client:
    global _supabase_service_client
    if _supabase_service_client is None:
        if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_KEY:
            raise ValueError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
        _supabase_service_client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY,
        )
    return _supabase_service_client


@lru_cache(maxsize=1)
def get_jwks_client() -> PyJWKClient:
    """Cached JWKS client — fetches keys once, cached forever."""
    jwks_url = f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json"
    return PyJWKClient(
        jwks_url,
        cache_keys=True,
        lifespan=3600,  # Cache JWKS for 1 hour
    )


async def verify_supabase_token(id_token: str) -> dict:
    """
    Verify a Supabase JWT locally using JWKS.
    No network call per request — ~5ms vs ~100ms.
    """
    # Dev mode bypass for testing
    if settings.APP_ENV == "development" and id_token.startswith("test_token_"):
        uid = id_token.replace("test_token_", "")
        return {"sub": uid, "email": f"{uid}@example.com"}

    try:
        jwks_client = get_jwks_client()
        signing_key = jwks_client.get_signing_key_from_jwt(id_token)

        payload = jwt.decode(
            id_token,
            signing_key.key,
            algorithms=["ES256"],
            audience="authenticated",
            issuer=f"{settings.SUPABASE_URL}/auth/v1",
            options={
                "verify_exp": True,
                "verify_aud": True,
                "verify_iss": True,
            },
        )

        return {
            "sub": payload["sub"],
            "email": payload.get("email"),
            "phone": payload.get("phone"),
        }
    except jwt.ExpiredSignatureError:
        raise ValueError("Token has expired")
    except jwt.InvalidAudienceError:
        raise ValueError("Invalid token audience")
    except jwt.InvalidIssuerError:
        raise ValueError("Invalid token issuer")
    except Exception as e:
        raise ValueError(f"Token verification failed: {e}")
