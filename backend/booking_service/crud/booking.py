# backend/booking_service/app/crud/booking.py
from sqlalchemy.orm import Session
from datetime import datetime

from models.booking import Booking, ServiceLog
from schemas.booking import BookingCreate, BookingUpdate, ServiceLogCreate

from typing import List, Optional
from uuid import UUID


def create_service_log(db: Session, payload: ServiceLogCreate):
    log = ServiceLog(**payload.dict())
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

def list_service_logs_for_user(db: Session, user_id: int):
    return db.query(ServiceLog).filter(ServiceLog.user_id == user_id).all()



def list_service_logs_for_user(db: Session, user_id: int):
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
        base_price=payload.base_price,
        agreed_price=payload.agreed_price,
        has_negotiated=payload.has_negotiated,
        negotiation_notes=payload.negotiation_notes,
    )
    db.add(b)
    db.commit()
    db.refresh(b)
    return b

def get_booking(db: Session, booking_id: str) -> Optional[Booking]:
    return db.query(Booking).filter(Booking.id == booking_id).first()

def update_booking(db: Session, booking_id: str, updates: BookingUpdate):
    b = db.query(Booking).filter(Booking.id == booking_id).first()
    if not b:
        return None
    
    # Track if status is changing to "completed"
    old_status = b.status
    updates_dict = updates.dict(exclude_unset=True)
    new_status = updates_dict.get('status') if 'status' in updates_dict else old_status
    
    # If status is changing to "completed", set completed_at
    if new_status and new_status.lower() == 'completed' and old_status.lower() != 'completed':
        # Only set if not already set
        if not b.completed_at:
            b.completed_at = datetime.utcnow()
    
    # Apply all updates
    for k, v in updates_dict.items():
        setattr(b, k, v)
    
    db.commit()
    db.refresh(b)
    return b

def delete_booking(db: Session, booking_id: str):
    b = db.query(Booking).filter(Booking.id == booking_id).first()
    if not b:
        return False
    db.delete(b)
    db.commit()
    return True


def list_bookings_for_user(db: Session, user_id: int, limit: int = 50, offset: int = 0) -> List[Booking]:
    return db.query(Booking).filter(Booking.user_id == user_id).order_by(Booking.created_at.desc()).offset(offset).limit(limit).all()

def list_bookings_for_provider(db: Session, provider_id: str, limit: int = 50, offset: int = 0) -> List[Booking]:
    from datetime import datetime, timezone
    from sqlalchemy import func
    
    # Normalize provider_id (trim whitespace)
    provider_id_trimmed = provider_id.strip() if provider_id else None
    
    # First try exact match
    query = db.query(Booking).filter(Booking.provider_id == provider_id_trimmed)
    
    # First, get all bookings (before limit) for debugging
    all_bookings = query.order_by(Booking.created_at.desc()).all()
    
    # If no results, try case-insensitive match
    if len(all_bookings) == 0 and provider_id_trimmed:
        query = db.query(Booking).filter(
            func.lower(Booking.provider_id) == provider_id_trimmed.lower()
        )
        all_bookings = query.order_by(Booking.created_at.desc()).all()
        if all_bookings:
            print(f"🔍 DEBUG: Found bookings using case-insensitive match")
    
    # Debug: Log all bookings found
    print(f"🔍 DEBUG: Querying bookings for provider_id: {provider_id} (trimmed: {provider_id_trimmed})")
    print(f"🔍 DEBUG: Total bookings found (before limit): {len(all_bookings)}")
    
    # Count by status
    status_counts = {}
    for b in all_bookings:
        status = b.status or "null"
        status_counts[status] = status_counts.get(status, 0) + 1
    print(f"🔍 DEBUG: Bookings by status: {status_counts}")
    
    # Check for pending bookings
    pending_bookings = [b for b in all_bookings if b.status and b.status.lower() == 'pending']
    print(f"🔍 DEBUG: Pending bookings found: {len(pending_bookings)}")
    if pending_bookings:
        print(f"🔍 DEBUG: Pending booking IDs: {[b.id for b in pending_bookings[:5]]}")
        print(f"🔍 DEBUG: Pending booking created_at: {[b.created_at for b in pending_bookings[:3]]}")
        print(f"🔍 DEBUG: Pending booking provider_ids: {[b.provider_id for b in pending_bookings[:3]]}")
    
    # Also check for any bookings with similar provider_ids (for debugging)
    if len(all_bookings) == 0 and provider_id_trimmed:
        # Check if there are any bookings with similar provider_id (case variations)
        similar_query = db.query(Booking).filter(
            Booking.provider_id.ilike(f"%{provider_id_trimmed}%")
        ).limit(10).all()
        if similar_query:
            print(f"🔍 DEBUG: Found {len(similar_query)} bookings with similar provider_id:")
            for b in similar_query:
                print(f"🔍 DEBUG:   - Booking {b.id}: provider_id='{b.provider_id}', status='{b.status}'")
    
    # Now apply limit and offset
    bookings = all_bookings[offset:offset+limit]
    
    # Debug logging for timezone issues
    if bookings:
        now_utc = datetime.now(timezone.utc)
        today_start_utc = datetime(now_utc.year, now_utc.month, now_utc.day, tzinfo=timezone.utc)
        today_count = sum(1 for b in bookings if b.created_at and b.created_at >= today_start_utc)
        print(f"📊 Provider {provider_id}: Total bookings returned: {len(bookings)}, Today's bookings (UTC): {today_count}")
        if bookings:
            print(f"📊 Most recent booking created_at: {bookings[0].created_at} (UTC), status: {bookings[0].status}")
            print(f"📊 Current UTC time: {now_utc}")
    
    return bookings
def create_bulk_service_logs(db: Session, payloads: List[ServiceLogCreate]):
    logs = [ServiceLog(**p.dict()) for p in payloads]
    db.add_all(logs)
    db.commit()
    for log in logs:
        db.refresh(log)
    return logs


def list_service_logs_for_provider(db: Session, provider_id: str):
    from datetime import datetime, timezone
    logs = db.query(ServiceLog).filter(ServiceLog.provider_id == provider_id).order_by(ServiceLog.created_at.desc()).all()
    
    # Debug logging for timezone issues
    if logs:
        now_utc = datetime.now(timezone.utc)
        today_start_utc = datetime(now_utc.year, now_utc.month, now_utc.day, tzinfo=timezone.utc)
        today_count = sum(1 for l in logs if l.created_at and l.created_at >= today_start_utc)
        print(f"📊 Provider {provider_id}: Total service logs returned: {len(logs)}, Today's logs (UTC): {today_count}")
        if logs:
            print(f"📊 Most recent log created_at: {logs[0].created_at} (UTC)")
            print(f"📊 Current UTC time: {now_utc}")
    
    return logs


def list_service_logs_for_vehicle(db: Session, vehicle_id: str):
    return db.query(ServiceLog).filter(ServiceLog.vehicle_id == vehicle_id).order_by(ServiceLog.created_at.desc()).all()
