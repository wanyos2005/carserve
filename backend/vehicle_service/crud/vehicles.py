# vehicle_service/crud/vehicles.py

from typing import List, Optional
from fastapi import HTTPException
from sqlalchemy.orm import Session

from models.vehicles import Vehicle
from schemas.vehicles import VehicleCreate, VehicleUpdate
import httpx


def normalize_plate(plate: str) -> str:
    return plate.strip().upper()


# --- CREATE ---
def create_vehicle(db: Session, user_id: str, payload: VehicleCreate) -> Vehicle:
    plate = normalize_plate(payload.plate)

    existing = db.query(Vehicle).filter(Vehicle.plate == plate).first()
    if existing:
        raise HTTPException(status_code=400, detail="Plate already registered")

    vehicle = Vehicle(
        owner_id=user_id,
        make=payload.make,
        model=payload.model,
        plate=plate,
        mileage=payload.mileage or 0,
        yom=payload.yom,
        fuel_type=payload.fuel_type,
        transmission=payload.transmission,
        color=payload.color,
    )

    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


# --- READ (LIST) ---
def list_vehicles(
    db: Session,
    user_id: str,
    plate: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
) -> List[Vehicle]:
    q = db.query(Vehicle).filter(Vehicle.owner_id == user_id)
    if plate:
        q = q.filter(Vehicle.plate == normalize_plate(plate))
    return q.offset(skip).limit(limit).all()


# --- READ (SINGLE) ---
def get_vehicle(db: Session, user_id: str, vehicle_id: str) -> Vehicle:
    v = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
    if not v or v.owner_id != user_id:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return v


# --- UPDATE ---
def update_vehicle(
    db: Session, user_id: str, vehicle_id: str, payload: VehicleUpdate
) -> Vehicle:
    v = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
    if not v or v.owner_id != user_id:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    if payload.plate is not None:
        new_plate = normalize_plate(payload.plate)
        if new_plate != v.plate:
            exists = db.query(Vehicle).filter(Vehicle.plate == new_plate).first()
            if exists:
                raise HTTPException(status_code=400, detail="Plate already registered")
            v.plate = new_plate

    update_fields = [
        "make", "model", "mileage", "yom", "fuel_type", "transmission", "color"
    ]
    for field in update_fields:
        value = getattr(payload, field)
        if value is not None:
            setattr(v, field, value)

    db.add(v)
    db.commit()
    db.refresh(v)
    return v


# --- DELETE ---
def delete_vehicle(db: Session, user_id: str, vehicle_id: str):
    v = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
    if not v or v.owner_id != user_id:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    db.delete(v)
    db.commit()

# --- ASYNC GUEST VEHICLE CREATION ---
async def create_guest_vehicle(db: Session, payload: VehicleCreate) -> Vehicle:
    """
    Creates a guest user in user-service, then registers their vehicle.
    """
    # 2️⃣ Create their vehicle
    vehicle = Vehicle(
        owner_id=payload.owner_id,  # This is the guest user ID from user-service
        make=payload.make,
        model=payload.model,
        plate=normalize_plate(payload.plate),
        mileage=payload.mileage or 0,
        yom=payload.yom,
        fuel_type=payload.fuel_type,
        transmission=payload.transmission,
        color=payload.color,
        guest_owner_name=payload.guest_owner_name,
        guest_owner_email=payload.guest_owner_email,
        guest_owner_phone=payload.guest_owner_phone,
        created_by_provider_id=payload.created_by_provider_id,
    )

    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


