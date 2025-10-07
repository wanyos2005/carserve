from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from core.db import get_db
from schemas.booking import ServiceLogCreate, ServiceLog
from crud.booking import (
    create_service_log,
    create_bulk_service_logs,
    list_service_logs_for_user,
    list_service_logs_for_provider,
    list_service_logs_for_vehicle,
)

router = APIRouter(tags=["service logs"])


# 🔹 Single service log (either by user or provider)
@router.post("/", response_model=ServiceLog)
def create_log(payload: ServiceLogCreate, db: Session = Depends(get_db)):
    return create_service_log(db, payload)


# 🔹 Provider logs full template (bulk)
@router.post("/bulk", response_model=List[ServiceLog])
def create_bulk_logs(payloads: List[ServiceLogCreate], db: Session = Depends(get_db)):
    logs = create_bulk_service_logs(db, payloads)
    return logs


# 🔹 Fetch logs by user
@router.get("/user/{user_id}", response_model=List[ServiceLog])
def list_user_logs(user_id: int, db: Session = Depends(get_db)):
    return list_service_logs_for_user(db, user_id)


# 🔹 Fetch logs by provider
@router.get("/provider/{provider_id}", response_model=List[ServiceLog])
def list_provider_logs(provider_id: str, db: Session = Depends(get_db)):
    return list_service_logs_for_provider(db, provider_id)


# 🔹 Fetch logs by vehicle
@router.get("/vehicle/{vehicle_id}", response_model=List[ServiceLog])
def list_vehicle_logs(vehicle_id: str, db: Session = Depends(get_db)):
    return list_service_logs_for_vehicle(db, vehicle_id)
