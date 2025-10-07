#1. backend/booking_service/app/routers/bookings.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from core.db import get_db
from schemas.booking import BookingCreate, BookingOut, BookingUpdate
from crud.booking import (
    create_booking,
    get_booking,
    list_bookings_for_user,
    update_booking,
    delete_booking,
)

# ❌ remove prefix="/bookings"
router = APIRouter(tags=["bookings"])


@router.post("/", response_model=BookingOut)
def create(payload: BookingCreate, db: Session = Depends(get_db)):
    b = create_booking(db, payload)
    return b



@router.get("/{booking_id}", response_model=BookingOut)
def get_one(booking_id: str, db: Session = Depends(get_db)):
    b = get_booking(db, booking_id)
    if not b:
        raise HTTPException(status_code=404, detail="Booking not found")
    return b

@router.put("/{booking_id}", response_model=BookingOut)
def update(booking_id: str, updates: BookingUpdate, db: Session = Depends(get_db)):
    b = update_booking(db, booking_id, updates)
    if not b:
        raise HTTPException(status_code=404, detail="Booking not found")
    return b

@router.delete("/{booking_id}", status_code=204)
def delete(booking_id: str, db: Session = Depends(get_db)):
    ok = delete_booking(db, booking_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Booking not found")
    return {}



@router.get("/user/{user_id}", response_model=List[BookingOut])
def list_for_user(user_id: int, db: Session = Depends(get_db)):
    return list_bookings_for_user(db, user_id)



