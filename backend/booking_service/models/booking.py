# backend/booking_service/app/models/booking.py

from sqlalchemy import Column, String, JSON, TIMESTAMP, Integer, func
from sqlalchemy.dialects.postgresql import UUID
import uuid

from core.db import Base

class Booking(Base):
    __tablename__ = "bookings"
    __table_args__ = {"schema": "bookings"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    # ✅ user_id should be int since users table uses integers
    user_id = Column(Integer, nullable=False)

    vehicle_id = Column(String, index=True)
    provider_id = Column(String, index=True)
    service_id = Column(String, index=True)

    status = Column(String(50), default="pending")
    scheduled_at = Column(TIMESTAMP(timezone=True), nullable=True)
    location = Column(JSON, nullable=True)
    meta = Column(JSON, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class ServiceLog(Base):
    __tablename__ = "service_logs"
    __table_args__ = {"schema": "bookings"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    # User & Vehicle
    user_id = Column(Integer, nullable=False)
    vehicle_id = Column(String, index=True)

    # Provider details (nullable if user logs manually)
    provider_id = Column(String, index=True)
    provider_name = Column(String(255), nullable=True)
    provider_contact = Column(JSON, nullable=True)

    # Service details
    service_id = Column(String, index=True)
    service_name = Column(String(255), nullable=True)

    # Items checked/changed
    service_items = Column(JSON, nullable=True)  

    mileage_km = Column(Integer, nullable=True)
    performed_at = Column(TIMESTAMP(timezone=True), nullable=True)

    # Next service info
    next_service_km = Column(Integer, nullable=True)
    next_service_date = Column(TIMESTAMP(timezone=True), nullable=True)

    # Mechanic info
    mechanic_name = Column(String(255), nullable=True)
    mechanic_contact = Column(String(255), nullable=True)
    
    # NEW → Who logged this (user vs provider vs system)
    logged_by = Column(String(50), default="user")  # "user", "provider", "system"
    notes = Column(String, nullable=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


