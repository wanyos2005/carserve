#1. backend/booking_service/app/routers/bookings.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from core.db import get_db
import os
import httpx
from schemas.booking import BookingCreate, BookingOut, BookingUpdate
from crud.booking import (
    create_booking,
    get_booking,
    list_bookings_for_user,
    list_bookings_for_provider,
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
    # Attempt to create an expense entry when booking is accepted/completed
    try:
        should_create_expense = (b.status in ["accepted", "completed"]) and (not getattr(b, "expense_recorded", False))
        price = getattr(b, "agreed_price", None) or getattr(b, "base_price", None)
        if should_create_expense and price and b.user_id and b.vehicle_id:
            expenses_url = os.getenv("EXPENSES_SERVICE_URL", "http://expenses-service:8007")
            body = {
                "owner_id": b.user_id,
                "vehicle_id": b.vehicle_id,
                "provider_id": b.provider_id,
                "expense_type": "service",
                "location": None,
                "cost": int(price),
            }
            try:
                with httpx.Client(timeout=3.0) as client:
                    client.post(f"{expenses_url}/expense/create-expense", json=body)
                # mark as recorded
                update_booking(db, booking_id, BookingUpdate(expense_recorded=True))
                b = get_booking(db, booking_id)
            except Exception:
                pass
    except Exception:
        pass
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

@router.get("/provider/{provider_id}", response_model=List[BookingOut])
def list_for_provider(provider_id: str, db: Session = Depends(get_db)):
    return list_bookings_for_provider(db, provider_id)



