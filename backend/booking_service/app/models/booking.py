# backend/booking_service/app/models/booking.py

from sqlalchemy import Column, String, JSON, TIMESTAMP, Integer, func
from sqlalchemy.dialects.postgresql import UUID
import uuid

from app.core.db import Base

class Booking(Base):
    __tablename__ = "bookings"
    __table_args__ = {"schema": "bookings"}

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        unique=True,
        nullable=False,
    )

    # ✅ user_id should be int since users table uses integers
    user_id = Column(Integer, nullable=False)

    vehicle_id = Column(UUID(as_uuid=True), nullable=False)
    provider_id = Column(UUID(as_uuid=True), nullable=False)
    service_id = Column(UUID(as_uuid=True), nullable=True)

    status = Column(String(50), default="pending")
    scheduled_at = Column(TIMESTAMP(timezone=True), nullable=True)
    location = Column(JSON, nullable=True)
    meta = Column(JSON, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class ServiceLog(Base):
    __tablename__ = "service_logs"
    __table_args__ = {"schema": "bookings"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True)

    # ✅ user_id should be int here too
    user_id = Column(Integer, nullable=False)

    vehicle_id = Column(UUID(as_uuid=True), nullable=True)

    provider_id = Column(UUID(as_uuid=True), nullable=True)
    service_id = Column(UUID(as_uuid=True), nullable=True)

    provider_name = Column(String(255), nullable=True)
    provider_contact = Column(JSON, nullable=True)
    service_name = Column(String(255), nullable=True)
    service_details = Column(JSON, nullable=True)

    performed_at = Column(TIMESTAMP(timezone=True), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
