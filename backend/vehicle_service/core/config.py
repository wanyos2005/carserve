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

# External service URLs
# vehicle_service delegates authentication to user_service - no JWT secrets needed!
USER_SERVICE_URL = os.getenv("USER_SERVICE_URL", "http://user-service:8001")

# CORS
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")
