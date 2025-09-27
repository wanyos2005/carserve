# backend/booking_service/app/crud/booking.py
from sqlalchemy.orm import Session

from app.models.booking import Booking, ServiceLog
from app.schemas.booking import BookingCreate, BookingUpdate, ServiceLogCreate

from typing import List, Optional
from uuid import UUID


def create_service_log(db: Session, payload: ServiceLogCreate) -> ServiceLog:
    log = ServiceLog(**payload.dict())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


def list_service_logs_for_user(db: Session, user_id: UUID):
    return db.query(ServiceLog).filter(ServiceLog.user_id == user_id).all()


def create_booking(db: Session, payload: BookingCreate) -> Booking:
    b = Booking(
        user_id=payload.user_id,
        vehicle_id=payload.vehicle_id,
        provider_id=payload.provider_id,
        service_id=payload.service_id,
        scheduled_at=payload.scheduled_at,
        location=payload.location,
        meta=payload.meta,
    )
    db.add(b)
    db.commit()
    db.refresh(b)
    return b

def get_booking(db: Session, booking_id: UUID) -> Optional[Booking]:
    return db.query(Booking).filter(Booking.id == booking_id).first()

def update_booking(db: Session, booking_id: UUID, updates: BookingUpdate):
    b = db.query(Booking).filter(Booking.id == booking_id).first()
    if not b:
        return None
    for k, v in updates.dict(exclude_unset=True).items():
        setattr(b, k, v)
    db.commit()
    db.refresh(b)
    return b

def delete_booking(db: Session, booking_id: UUID):
    b = db.query(Booking).filter(Booking.id == booking_id).first()
    if not b:
        return False
    db.delete(b)
    db.commit()
    return True


def list_bookings_for_user(db: Session, user_id: int, limit: int = 50, offset: int = 0) -> List[Booking]:
    return db.query(Booking).filter(Booking.user_id == user_id).order_by(Booking.created_at.desc()).offset(offset).limit(limit).all()
