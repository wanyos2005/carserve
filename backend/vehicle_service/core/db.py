# backend/vehicle_service/core/db.py
from sqlalchemy import create_engine, MetaData
from sqlalchemy.orm import sessionmaker, declarative_base
from core.config import DATABASE_URL

# Engine
engine = create_engine(DATABASE_URL)

# Session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Metadata for 'vehicles' schema
metadata = MetaData(schema="vehicles")
Base = declarative_base(metadata=metadata)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
