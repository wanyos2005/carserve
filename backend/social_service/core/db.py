# backend/social_service/core/db.py
from sqlalchemy import create_engine, MetaData
from sqlalchemy.orm import sessionmaker, declarative_base
from core.config import DATABASE_URL

# Engine with connection pooling and retry logic
engine = create_engine(
    DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=3600    # Recycle connections every hour
)

# Session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Metadata for 'social' schema
metadata = MetaData(schema="social")
Base = declarative_base(metadata=metadata)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
