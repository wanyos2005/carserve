from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from datetime import datetime, timedelta

from core.db import get_db
from schemas.booking import ServiceLogCreate, ServiceLog
from crud.booking import (
    create_service_log,
    create_bulk_service_logs,
    list_service_logs_for_user,
    list_service_logs_for_provider,
    list_service_logs_for_vehicle,
)
import os
import httpx

router = APIRouter(tags=["service logs"])


# 🔹 Single service log (either by user or provider)
@router.post("/", response_model=ServiceLog)
def create_log(payload: ServiceLogCreate, db: Session = Depends(get_db)):
    log = create_service_log(db, payload)
    # If cost present, attempt to create an expense record
    try:
        if log.cost and log.user_id and log.vehicle_id:
            expenses_url = os.getenv("EXPENSES_SERVICE_URL", "http://expenses-service:8007")
            body = {
                "owner_id": log.user_id,
                "vehicle_id": log.vehicle_id,
                "provider_id": log.provider_id,
                "expense_type": "service",
                "location": (log.provider_name or "")[:120],
                "cost": int(log.cost),
            }
            # Fire and forget
            try:
                with httpx.Client(timeout=3.0) as client:
                    client.post(f"{expenses_url}/expense/create-expense", json=body)
            except Exception:
                pass
    except Exception:
        pass
    return log


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

# Alert System Integration Endpoints
@router.get("/due")
def get_service_logs_due(
    days_ahead: int = Query(30, description="Number of days ahead to check for due services"),
    db: Session = Depends(get_db)
):
    """Get service logs with services due within specified days (for alert system)"""
    from models.booking import ServiceLog
    
    # Get service logs that have next_service_date or next_service_km set
    service_logs = db.query(ServiceLog).filter(
        ServiceLog.next_service_date.isnot(None)
    ).all()
    
    # Filter by date
    date_threshold = datetime.utcnow() + timedelta(days=days_ahead)
    due_services = []
    
    for log in service_logs:
        if log.next_service_date and log.next_service_date <= date_threshold:
            due_services.append({
                "id": log.id,
                "user_id": log.user_id,
                "vehicle_id": log.vehicle_id,
                "provider_id": log.provider_id,
                "provider_name": log.provider_name,
                "service_name": log.service_name,
                "current_mileage": log.mileage_km,
                "next_service_km": log.next_service_km,
                "next_service_date": log.next_service_date.isoformat() if log.next_service_date else None,
                "last_service_date": log.performed_at.isoformat() if log.performed_at else None,
                "service_type": "Regular Maintenance"  # Default, can be enhanced
            })
    
    return due_services
