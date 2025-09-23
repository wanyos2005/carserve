#vehicle_service/routes/vehicles.py
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from core.db import get_db
from core.security import get_current_user_id
from models.vehicles import Vehicle
from schemas.vehicles import VehicleCreate, VehicleRead, VehicleUpdate

router = APIRouter()

def normalize_plate(plate: str) -> str:
    # Simple normalization: trim + uppercase (e.g., "KDA 123A" stays consistent)
    return plate.strip().upper()

@router.post("/", response_model=VehicleRead, status_code=status.HTTP_201_CREATED)
def create_vehicle(
    payload: VehicleCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    plate = normalize_plate(payload.plate)

    # Enforce unique plate
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

@router.get("/", response_model=List[VehicleRead])
def list_vehicles(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
    plate: Optional[str] = Query(None, description="Filter by plate"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
):
    q = db.query(Vehicle).filter(Vehicle.owner_id == user_id)
    if plate:
        q = q.filter(Vehicle.plate == normalize_plate(plate))
    return q.offset(skip).limit(limit).all()

@router.get("/{vehicle_id}", response_model=VehicleRead)
def get_vehicle(
    vehicle_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    v = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
    if not v or v.owner_id != user_id:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return v

@router.put("/{vehicle_id}", response_model=VehicleRead)
def update_vehicle(
    vehicle_id: str,
    payload: VehicleUpdate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
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

    if payload.make is not None:
        v.make = payload.make
    if payload.model is not None:
        v.model = payload.model
    if payload.mileage is not None:
        v.mileage = payload.mileage
    if payload.yom is not None:
        v.yom = payload.yom
    if payload.fuel_type is not None:
        v.fuel_type = payload.fuel_type
    if payload.transmission is not None:
        v.transmission = payload.transmission
    if payload.color is not None:
        v.color = payload.color

    db.add(v)
    db.commit()
    db.refresh(v)
    return v

@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vehicle(
    vehicle_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    v = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
    if not v or v.owner_id != user_id:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    db.delete(v)
    db.commit()
    return None


