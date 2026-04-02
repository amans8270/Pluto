"""
Global error handling for FastAPI.
Provides consistent JSON error structure for all exceptions.
"""
import traceback
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError
import structlog

logger = structlog.get_logger(__name__)


def register_exception_handlers(app: FastAPI) -> None:
    """Attach all global exception handlers to the FastAPI app."""

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
        logger.warning(
            "HTTP exception",
            status_code=exc.status_code,
            detail=exc.detail,
            path=request.url.path,
        )
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": exc.detail,
                "status_code": exc.status_code,
                "path": str(request.url.path),
            },
        )

    @app.exception_handler(IntegrityError)
    async def integrity_error_handler(request: Request, exc: IntegrityError):
        logger.warning("DB IntegrityError", error=str(exc.orig))
        msg = "A conflict occurred"
        if "unique" in str(exc.orig).lower():
            msg = "This record already exists"
        elif "foreign key" in str(exc.orig).lower():
            msg = "Referenced record not found"
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"error": msg, "status_code": 409},
        )

    @app.exception_handler(ValueError)
    async def value_error_handler(request: Request, exc: ValueError):
        logger.warning("ValueError", error=str(exc))
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={"error": str(exc), "status_code": 422},
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        logger.error(
            "Unhandled exception",
            error=str(exc),
            traceback=traceback.format_exc(),
            path=request.url.path,
        )
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Internal server error. Please try again later.",
                "status_code": 500,
            },
        )
