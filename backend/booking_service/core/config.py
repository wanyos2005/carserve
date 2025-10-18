from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    # Use DATABASE_URL directly from environment (for Neon/external DB)
    database_url: str = os.getenv("DATABASE_URL", "postgresql://AdminDb:Ngojakwanza@postgres:5432/car_platform")
    
    # Fallback individual components for local development
    db_user: str = "AdminDb"
    db_password: str = "Ngojakwanza"
    db_name: str = "car_platform"
    db_host: str = "postgres"
    db_port: str = "5432"
    
    secret_key: str = "supersecret"
    allowed_origins: str = "*"

    class Config:
        env_file = ".env"
        extra = "ignore"  # ✅ Ignore unknown env vars instead of crashing
        

settings = Settings()
