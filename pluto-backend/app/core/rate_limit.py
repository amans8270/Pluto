"""
Rate limiting middleware using in-memory dictionary (sliding window counter).
Limits per user+endpoint combination.
"""
import time
import asyncio
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from app.core.config import settings

class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Sliding window rate limiter backed by local memory.
    Limits: X requests per window_seconds per IP/user.
    """

    LIMITS = {
        "/api/v1/swipes": (400, 3600),          # 400 swipes/hour
        "/api/v1/auth/verify": (10, 300),        # 10 login attempts/5min
        "/api/v1/users/me/photos": (20, 86400),  # 20 photo uploads/day
        "/api/v1/trips": (20, 3600),             # 20 trip creates/hour
        "default": (200, 60),                   # 200 req/min default
    }

    def __init__(self, app):
        super().__init__(app)
        self._counters = {}
        self._lock = asyncio.Lock()

    async def dispatch(self, request: Request, call_next) -> Response:
        # Skip rate limiting in dev
        if settings.APP_ENV == "dev":
            return await call_next(request)

        path = request.url.path
        client_ip = request.headers.get("X-Forwarded-For", request.client.host if request.client else "unknown")

        # Find matching limit
        limit, window = next(
            ((lim, win) for prefix, (lim, win) in self.LIMITS.items()
             if prefix != "default" and path.startswith(prefix)),
            self.LIMITS["default"],
        )

        current_window = int(time.time()) // window
        key = f"rl:{client_ip}:{path.rstrip('/')}:{current_window}"

        async with self._lock:
            # Clean up old windows occasionally to prevent memory leak (lazy evaluation)
            now = time.time()
            if len(self._counters) > 10000:
                # Naive cleanup: remove keys older than their window
                keys_to_delete = []
                for k, v in self._counters.items():
                    _, expire_at = v
                    if now > expire_at:
                        keys_to_delete.append(k)
                for k in keys_to_delete:
                    self._counters.pop(k, None)

            record = self._counters.get(key)
            if record:
                count, expire_at = record
                self._counters[key] = (count + 1, expire_at)
                count += 1
            else:
                self._counters[key] = (1, now + window)
                count = 1

            remaining = max(0, limit - count)
            reset_at = (current_window + 1) * window

            if count > limit:
                return JSONResponse(
                    status_code=429,
                    content={
                        "error": "Rate limit exceeded. Please slow down.",
                        "retry_after": reset_at - int(now),
                    },
                    headers={
                        "X-RateLimit-Limit": str(limit),
                        "X-RateLimit-Remaining": "0",
                        "X-RateLimit-Reset": str(reset_at),
                        "Retry-After": str(reset_at - int(now)),
                    },
                )

        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(limit)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(reset_at)
        return response
