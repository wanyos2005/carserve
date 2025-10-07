# vehicle_service/routes/vehicles.py

from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
import httpx

from core.db import get_db
from core.security import get_current_user_id
from schemas.vehicles import VehicleCreate, VehicleRead, VehicleUpdate
from crud.vehicles import (
    create_vehicle,
    list_vehicles,
    get_vehicle,
    update_vehicle,
    delete_vehicle,
    create_guest_vehicle,
)
from models.vehicles import Vehicle
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi import HTTPException
import logging
logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/", response_model=VehicleRead, status_code=status.HTTP_201_CREATED)
def create_vehicle_route(
    payload: VehicleCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    return create_vehicle(db, user_id, payload)


@router.get("/", response_model=List[VehicleRead])
def list_vehicles_route(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
    plate: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
):
    return list_vehicles(db, user_id, plate, skip, limit)


@router.get("/{vehicle_id}", response_model=VehicleRead)
def get_vehicle_route(
    vehicle_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    return get_vehicle(db, user_id, vehicle_id)


@router.put("/{vehicle_id}", response_model=VehicleRead)
def update_vehicle_route(
    vehicle_id: str,
    payload: VehicleUpdate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    return update_vehicle(db, user_id, vehicle_id, payload)


@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vehicle_route(
    vehicle_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    delete_vehicle(db, user_id, vehicle_id)
    return None

@router.post("/guest", response_model=VehicleRead)
async def create_guest_vehicle_route(payload: VehicleCreate, db: Session = Depends(get_db)):
    if not payload.owner_id:
        raise HTTPException(status_code=400, detail="Owner ID required for guest vehicle")
    vehicle = Vehicle(**payload.dict())
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle




    
