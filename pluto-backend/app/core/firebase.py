import firebase_admin
from firebase_admin import auth as firebase_auth, credentials
import logging

from app.core.config import settings

_app: firebase_admin.App | None = None
logger = logging.getLogger(__name__)


def initialize_firebase() -> None:
    global _app
    
    # Delete existing app if already initialized (to handle hot-reload with new project_id)
    try:
        for app in firebase_admin._apps.values():
            firebase_admin.delete_app(app)
    except Exception:
        pass
        
    import os
    import json
    
    cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
    cred_path = settings.GOOGLE_APPLICATION_CREDENTIALS
    
    if cred_json:
        # Load from raw string (Google Secret Manager)
        cred_dict = json.loads(cred_json)
        cred = credentials.Certificate(cred_dict)
    elif cred_path:
        # Load from file (Local dev)
        cred = credentials.Certificate(cred_path)
    else:
        logger.info("Firebase not configured; skipping initialization.")
        return

    _app = firebase_admin.initialize_app(cred, {
        "projectId": settings.FIREBASE_PROJECT_ID,
        "storageBucket": f"{settings.GCS_BUCKET_NAME}.appspot.com"
    })


async def verify_firebase_token(id_token: str) -> dict:
    """
    Verify a Firebase ID token and return the decoded claims.
    Allows a 'test_token' bypass when APP_ENV is development.
    """
    if settings.APP_ENV == "development" and id_token.startswith("test_token_"):
        # Format: test_token_FIREBASE_UID
        uid = id_token.replace("test_token_", "")
        return {"uid": uid, "email": f"{uid}@example.com"}

    try:
        decoded = firebase_auth.verify_id_token(id_token, check_revoked=True)
        return decoded
    except firebase_auth.RevokedIdTokenError:
        raise ValueError("Token has been revoked. Please sign in again.")
    except firebase_auth.InvalidIdTokenError as e:
        raise ValueError(f"Invalid Firebase token: {e}")
    except Exception as e:
        raise ValueError(f"Token verification failed: {e}")
