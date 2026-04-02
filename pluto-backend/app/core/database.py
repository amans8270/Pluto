from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.pool import AsyncAdaptedQueuePool

from app.core.config import settings


class Base(DeclarativeBase):
    pass


# Async SQLAlchemy engine with Supabase Supavisor pooler compatibility
engine = create_async_engine(
    settings.DATABASE_URL,
    poolclass=AsyncAdaptedQueuePool,
    pool_size=10,          # More warm connections = fewer cold starts
    max_overflow=5,
    pool_pre_ping=False,   # Skip extra round-trip per request (saves ~100ms/req to Tokyo)
    pool_recycle=1800,     # Keep connections alive 30 min (reduce cold starts)
    pool_timeout=20,
    echo=False,
    connect_args={
        # Required for Supabase Supavisor (both session + transaction modes)
        # Disables prepared statement caching which poolers don't support
        "statement_cache_size": 0,
        "prepared_statement_cache_size": 0,
    },
)

# Session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)


async def get_db() -> AsyncSession:
    """Dependency: yields an async DB session, auto-closes on exit."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
