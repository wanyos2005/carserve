from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    # Use DATABASE_URL directly from environment (for Neon/external DB)
    database_url: str = os.getenv("DATABASE_URL", "postgresql://AdminDb:Ngojakwanza@postgres:5432/car_platform")
    
    # Fallback individual components for local development
    db_user: str = os.getenv("DB_USER", "AdminDb")
    db_password: str = os.getenv("DB_PASSWORD", "Ngojakwanza")
    db_name: str = os.getenv("DB_NAME", "car_platform")
    db_host: str = os.getenv("DB_HOST", "postgres")
    db_port: str = os.getenv("DB_PORT", "5432")
    
    secret_key: str = os.getenv("JWT_SECRET_KEY", "supersecret")
    allowed_origins: str = os.getenv("ALLOWED_ORIGINS", "*")

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()

