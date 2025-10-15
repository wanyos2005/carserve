# backend/alert_service/core/db.py
from sqlalchemy import create_engine, MetaData
from sqlalchemy.orm import sessionmaker, declarative_base
from core.config import settings
import logging

engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autoflush=False, autocommit=False, bind=engine)
Base = declarative_base()
metadata = MetaData(schema=None)  # we set schema in models explicitly if needed

def get_db():
    logging.getLogger("uvicorn").info("get_db: creating SessionLocal")
    db = SessionLocal()
    try:
        logging.getLogger("uvicorn").info("get_db: yielding session")
        yield db
    finally:
        logging.getLogger("uvicorn").info("get_db: closing session")
        db.close()
