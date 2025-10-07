from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    db_user: str
    db_password: str
    db_name: str
    db_host: str
    db_port: str
    secret_key: str
    allowed_origins: str
    database_url: str  # e.g. postgresql+psycopg2://user:password@localhost:5432/car_platform

    class Config:
        env_file = ".env"
        extra = "ignore"  # ✅ Ignore unknown env vars instead of crashing
        

settings = Settings()
