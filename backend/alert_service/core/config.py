# backend/alert_service/core/config.py
from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List, Union

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql://AdminDb:Ngojakwanza@postgres:5432/car_platform"
    
    # Redis for event streaming and caching
    REDIS_URL: str = "redis://localhost:6379"
    CELERY_BROKER_URL: str = "redis://redis:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://redis:6379/1"
    
    # External service URLs
    USER_SERVICE_URL: str = "http://localhost:8001"
    BOOKING_SERVICE_URL: str = "http://localhost:8004" 
    INSURANCE_SERVICE_URL: str = "http://localhost:8005"
    
    # Notification services
    FCM_SERVER_KEY: str = ""
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_PHONE_NUMBER: str = ""
    # Africa's Talking
    SMS_PROVIDER: str = "africastalking"  # twilio | africastalking
    AT_USERNAME: str = "sandbox"
    AT_API_KEY: str = "atsk_f3f2b279ac069c0320e24f5ec82bdeafbb31c8212f9a5b7e9b7bd6b94bff46c10869c579"
    AT_SENDER_ID: str = ""  # optional; short code or alphanumeric when approved
    
    # Email settings (matching user service)
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = "tastytasty101@gmail.com"
    SMTP_PASSWORD: str = "degp zfga fqfp sifz"
    SMTP_FROM_EMAIL: str = "tastytasty101@gmail.com"
    SMTP_FROM_NAME: str = "DriveOn"
    SMTP_TLS: bool = True
    SMTP_SSL: bool = False
    
    # Alert settings
    ALERT_BATCH_SIZE: int = 100
    ALERT_RETRY_ATTEMPTS: int = 3
    ALERT_RETRY_DELAY: int = 300  # 5 minutes
    
    # CORS - using string type to avoid JSON parsing issues
    ALLOWED_ORIGINS_STR: str = "*"
    
    @property
    def ALLOWED_ORIGINS(self) -> List[str]:
        """Parse ALLOWED_ORIGINS_STR into a list of origins"""
        if not self.ALLOWED_ORIGINS_STR:
            return ["*"]
        return [origin.strip() for origin in self.ALLOWED_ORIGINS_STR.split(',') if origin.strip()]
    
    class Config:
        env_file = ".env"

settings = Settings()
ALLOWED_ORIGINS = settings.ALLOWED_ORIGINS
