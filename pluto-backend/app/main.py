# ── Main Router Registration (aligned with pluto-93d74) ─────────────────────────
# Replace the v1 router section in app/main.py with this:

from fastapi import FastAPI
from contextlib import asynccontextmanager

from app.api.v1 import auth, users, swipes, matches, chats, trips, notifications
from app.api import websocket as ws
from app.core.logging import configure_logging
from app.core.exceptions import register_exception_handlers
from app.core.rate_limit import RateLimitMiddleware
from app.core.config import settings
from app.core.firebase import initialize_firebase
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup — keep fast, no blocking I/O here
    # DB connects lazily on first request via SQLAlchemy pool
    configure_logging()
    initialize_firebase()

    # Warm up DB connection pool in background (non-blocking)
    # This pre-opens connections so first user requests don't pay cold-start cost
    async def _warmup():
        import asyncio, logging
        log = logging.getLogger("warmup")
        try:
            from app.core.database import engine
            from sqlalchemy import text
            # Open pool_size connections eagerly
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            log.info("✅ DB pool warmed up")
        except Exception as e:
            log.warning(f"⚠️ DB warmup failed (will retry on first request): {e}")

    import asyncio
    asyncio.create_task(_warmup())

    yield
    # Shutdown: dispose engine pool
    from app.core.database import engine
    await engine.dispose()


app = FastAPI(
    title="Pluto API",
    version="1.0.0",
    description="Pluto — Multi-mode social platform (Dating, TravelBuddy, BFF)",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Middlewares (order matters — outermost runs first)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"],
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(RateLimitMiddleware)

# Exception handlers
register_exception_handlers(app)

# Routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(swipes.router, prefix="/api/v1/swipes", tags=["Swipes"])
app.include_router(matches.router, prefix="/api/v1/matches", tags=["Matches"])
app.include_router(chats.router, prefix="/api/v1/chats", tags=["Chats"])
app.include_router(trips.router, prefix="/api/v1/trips", tags=["Trips"])
app.include_router(
    notifications.router, prefix="/api/v1/notifications", tags=["Notifications"]
)
app.include_router(ws.router, prefix="/ws", tags=["WebSocket"])

# Static files for local development (storage abstraction)
from fastapi.staticfiles import StaticFiles
import os

os.makedirs("static/uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="static/uploads"), name="uploads")


@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "version": "1.0.0", "env": settings.APP_ENV}
