# backend/social_service/core/config.py
import os
from dotenv import load_dotenv

load_dotenv()

"""
Database URL resolution supporting both external (Neon) and internal (local docker) DBs.
Rules:
- Respect DATABASE_URL if provided
- Normalize driver: postgresql+psycopg2:// -> postgresql://
- For local dev (no explicit sslmode in URL and ENVIRONMENT != production), force sslmode=disable
"""

ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    DB_USER = os.getenv("DB_USER", "AdminDb")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "Ngojakwanza")
    DB_NAME = os.getenv("DB_NAME", "car_platform")
    DB_HOST = os.getenv("DB_HOST", "postgres")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Normalize SQLAlchemy-style prefix if present
if DATABASE_URL.startswith("postgresql+psycopg2://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql+psycopg2://", "postgresql://", 1)

# If no sslmode present and not production, disable SSL for local docker postgres
if "sslmode=" not in DATABASE_URL and ENVIRONMENT != "production":
    sep = "&" if "?" in DATABASE_URL else "?"
    DATABASE_URL = f"{DATABASE_URL}{sep}sslmode=disable"

# Redis configuration
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_URL = os.getenv("REDIS_URL", f"redis://{REDIS_HOST}:6379")

# JWT Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "supersecret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# CORS Configuration
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

# Social Service Specific Configuration
SOCIAL_SERVICE_PORT = int(os.getenv("SOCIAL_SERVICE_PORT", "8008"))

# Media Storage Configuration
MEDIA_STORAGE_TYPE = os.getenv("MEDIA_STORAGE_TYPE", "local")  # local, s3, cloudflare, oracle
MEDIA_UPLOAD_PATH = os.getenv("MEDIA_UPLOAD_PATH", "/app/uploads")
MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE", "10485760"))  # 10MB in bytes
ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"]
ALLOWED_VIDEO_TYPES = ["video/mp4", "video/webm", "video/quicktime"]

# AWS S3 Configuration (if using S3)
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_S3_BUCKET = os.getenv("AWS_S3_BUCKET")
AWS_S3_REGION = os.getenv("AWS_S3_REGION", "us-east-1")

# Cloudflare R2 Configuration (if using Cloudflare)
CLOUDFLARE_ACCOUNT_ID = os.getenv("CLOUDFLARE_ACCOUNT_ID")
CLOUDFLARE_ACCESS_KEY_ID = os.getenv("CLOUDFLARE_ACCESS_KEY_ID")
CLOUDFLARE_SECRET_ACCESS_KEY = os.getenv("CLOUDFLARE_SECRET_ACCESS_KEY")
CLOUDFLARE_BUCKET = os.getenv("CLOUDFLARE_BUCKET")
CLOUDFLARE_PUBLIC_URL = os.getenv("CLOUDFLARE_PUBLIC_URL")  # Custom domain or R2.dev URL

# Oracle Cloud Storage Configuration (if using Oracle)
ORACLE_ACCESS_KEY_ID = os.getenv("ORACLE_ACCESS_KEY_ID")
ORACLE_SECRET_ACCESS_KEY = os.getenv("ORACLE_SECRET_ACCESS_KEY")
ORACLE_BUCKET = os.getenv("ORACLE_BUCKET")
ORACLE_REGION = os.getenv("ORACLE_REGION", "us-ashburn-1")
ORACLE_NAMESPACE = os.getenv("ORACLE_NAMESPACE")

# Content Moderation
ENABLE_CONTENT_MODERATION = os.getenv("ENABLE_CONTENT_MODERATION", "true").lower() == "true"
MODERATION_API_KEY = os.getenv("MODERATION_API_KEY")

# Analytics Configuration
ENABLE_ANALYTICS = os.getenv("ENABLE_ANALYTICS", "true").lower() == "true"
ANALYTICS_RETENTION_DAYS = int(os.getenv("ANALYTICS_RETENTION_DAYS", "90"))

# Rate Limiting
RATE_LIMIT_ENABLED = os.getenv("RATE_LIMIT_ENABLED", "true").lower() == "true"
RATE_LIMIT_REQUESTS_PER_MINUTE = int(os.getenv("RATE_LIMIT_REQUESTS_PER_MINUTE", "60"))

# Notification Configuration
ENABLE_NOTIFICATIONS = os.getenv("ENABLE_NOTIFICATIONS", "true").lower() == "true"
FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY")
PUSH_NOTIFICATION_ENABLED = os.getenv("PUSH_NOTIFICATION_ENABLED", "true").lower() == "true"

# Celery Configuration
CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL", f"redis://{REDIS_HOST}:6379/0")
CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND", f"redis://{REDIS_HOST}:6379/1")
