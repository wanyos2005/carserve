# core/config.py
import os
from dotenv import load_dotenv

load_dotenv()

# Use DATABASE_URL directly from environment (for Neon/external DB)
# Fallback to individual components for local development
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    # Fallback for local development
    DB_USER = os.getenv("DB_USER", "AdminDb")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "Ngojakwanza")
    DB_NAME = os.getenv("DB_NAME", "car_platform")
    DB_HOST = os.getenv("DB_HOST", "postgres")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Redis configuration
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_URL = os.getenv("REDIS_URL", f"redis://{REDIS_HOST}:6379")

# JWT Configuration (align with other services)
# Accept either SECRET_KEY or JWT_SECRET_KEY
SECRET_KEY = os.getenv("SECRET_KEY") or os.getenv("JWT_SECRET_KEY", "supersecret")
JWT_SECRET_KEY = SECRET_KEY
ALGORITHM = "HS256"
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 43200

# Service URLs
ALERT_SERVICE_URL = os.getenv("ALERT_SERVICE_URL", "http://alert-service:8006")

# CORS Configuration
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")


