# backend/booking_service/app/core/db.py
from sqlalchemy import create_engine, MetaData
from sqlalchemy.orm import sessionmaker, declarative_base
from core.config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(autoflush=False, autocommit=False, bind=engine)
Base = declarative_base()
metadata = MetaData(schema=None)  # we set schema in models explicitly if needed

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
