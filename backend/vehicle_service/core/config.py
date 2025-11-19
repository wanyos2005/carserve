#backend/vehicle_service/core/config.py
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

# JWT Configuration (align with user_service)
# Accept either SECRET_KEY or JWT_SECRET_KEY - must match user_service
SECRET_KEY = os.getenv("SECRET_KEY") or os.getenv("JWT_SECRET_KEY", "supersecret")
JWT_SECRET_KEY = SECRET_KEY  # Keep for backward compatibility if needed
ALGORITHM = "HS256"

# CORS
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")
