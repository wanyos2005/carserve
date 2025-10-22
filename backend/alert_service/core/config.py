# backend/alert_service/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
from typing import List, Union
import os

class Settings(BaseSettings):
    # Pydantic v2 settings config: load from .env and ignore unknown env vars
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    # Database - Use DATABASE_URL from environment (for Neon/external DB)
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://AdminDb:Ngojakwanza@postgres:5432/car_platform")
    
    # Redis for event streaming and caching
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379")
    CELERY_BROKER_URL: str = os.getenv("CELERY_BROKER_URL", "redis://redis:6379/0")
    CELERY_RESULT_BACKEND: str = os.getenv("CELERY_RESULT_BACKEND", "redis://redis:6379/1")
    
    # External service URLs
    USER_SERVICE_URL: str = os.getenv("USER_SERVICE_URL", "http://user-service:8001")
    BOOKING_SERVICE_URL: str = os.getenv("BOOKING_SERVICE_URL", "http://booking-service:8004")
    INSURANCE_SERVICE_URL: str = os.getenv("INSURANCE_SERVICE_URL", "http://insurance-service:8005")
    
    # Notification services
    FCM_SERVER_KEY: str = os.getenv("FCM_SERVER_KEY", "")
    TWILIO_ACCOUNT_SID: str = os.getenv("TWILIO_ACCOUNT_SID", "")
    TWILIO_AUTH_TOKEN: str = os.getenv("TWILIO_AUTH_TOKEN", "")
    TWILIO_PHONE_NUMBER: str = os.getenv("TWILIO_PHONE_NUMBER", "")
    # Africa's Talking
    SMS_PROVIDER: str = os.getenv("SMS_PROVIDER", "africastalking")  # twilio | africastalking
    AT_USERNAME: str = os.getenv("AT_USERNAME", "sandbox")
    AT_API_KEY: str = os.getenv("AT_API_KEY", "atsk_f3f2b279ac069c0320e24f5ec82bdeafbb31c8212f9a5b7e9b7bd6b94bff46c10869c579")
    AT_SENDER_ID: str = os.getenv("AT_SENDER_ID", "")  # optional; short code or alphanumeric when approved
    
    # Email settings (matching user service)
    SMTP_HOST: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USERNAME: str = os.getenv("SMTP_USERNAME", "tastytasty101@gmail.com")
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "degp zfga fqfp sifz")
    SMTP_FROM_EMAIL: str = os.getenv("SMTP_FROM_EMAIL", "tastytasty101@gmail.com")
    SMTP_FROM_NAME: str = os.getenv("SMTP_FROM_NAME", "DriveOn")
    SMTP_TLS: bool = os.getenv("SMTP_TLS", "True").lower() == "true"
    SMTP_SSL: bool = os.getenv("SMTP_SSL", "False").lower() == "true"
    
    # Alert settings
    ALERT_BATCH_SIZE: int = 100
    ALERT_RETRY_ATTEMPTS: int = 3
    ALERT_RETRY_DELAY: int = 300  # 5 minutes
    
    # CORS - using string type to avoid JSON parsing issues
    ALLOWED_ORIGINS_STR: str = os.getenv("ALLOWED_ORIGINS", "*")
    
    @property
    def ALLOWED_ORIGINS(self) -> List[str]:
        """Parse ALLOWED_ORIGINS_STR into a list of origins"""
        if not self.ALLOWED_ORIGINS_STR:
            return ["*"]
        return [origin.strip() for origin in self.ALLOWED_ORIGINS_STR.split(',') if origin.strip()]
    
    # Note: model_config above supersedes legacy Config for pydantic v2

settings = Settings()
ALLOWED_ORIGINS = settings.ALLOWED_ORIGINS
