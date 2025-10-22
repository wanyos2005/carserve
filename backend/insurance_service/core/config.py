#backend/vehicle_service/core/config.py
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




SECRET_KEY = os.getenv("SECRET_KEY", "supersecret")
ALGORITHM = "HS256"

# CORS
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")
