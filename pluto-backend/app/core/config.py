from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    # App
    APP_NAME: str = "Pluto"
    APP_ENV: str = "development"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    SECRET_KEY: str = "change-me"
    LOG_LEVEL: str = "INFO"

    # Database
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 10

    # Firebase
    FIREBASE_PROJECT_ID: str = "pluto-93d74"
    GOOGLE_APPLICATION_CREDENTIALS: str = ""

    # Supabase
    SUPABASE_URL: str = ""
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_SERVICE_KEY: str = ""

    # Optional GCS fallback
    GCS_BUCKET_NAME: str = "pluto-media-bucket"
    GCS_PROJECT_ID: str = ""

    # CORS — NEVER use "*" in production
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080"

    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 60

    # Pagination
    DEFAULT_PAGE_SIZE: int = 20
    MAX_DISCOVER_RADIUS_KM: int = 100

    # Razorpay
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_SECRET: str = ""

    # Sentry
    SENTRY_DSN: str = ""

    # Cloudinary (photo storage — global CDN, fast uploads)
    CLOUDINARY_CLOUD_NAME: str = ""
    CLOUDINARY_API_KEY: str = ""
    CLOUDINARY_API_SECRET: str = ""


settings = Settings()
