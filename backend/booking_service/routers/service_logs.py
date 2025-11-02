from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from datetime import datetime, timedelta, timezone

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
    
    # 🔥 NEW: Award loyalty points if cost present
    try:
        if log.cost and log.user_id:
            loyalty_url = os.getenv("LOYALTY_SERVICE_URL", "http://loyalty-service:8009")
            body = {
                "user_id": log.user_id,
                "provider_id": log.provider_id,
                "service_id": log.service_id,
                "amount_spent": int(log.cost),
                "reference_type": "service_log",
                "reference_id": log.id,
            }
            # Fire and forget - don't block service logging
            try:
                with httpx.Client(timeout=7.0) as client:
                    client.post(f"{loyalty_url}/loyalty/points/award", json=body)
            except Exception as e:
                print(f"Warning: Failed to award loyalty points: {e}")
    except Exception as e:
        print(f"Warning: Error in loyalty points integration: {e}")
    
    return log


# 🔹 Provider logs full template (bulk)
@router.post("/bulk", response_model=List[ServiceLog])
def create_bulk_logs(payloads: List[ServiceLogCreate], db: Session = Depends(get_db)):
    logs = create_bulk_service_logs(db, payloads)
    
    # 🔥 NEW: Trigger app download prompts for guest users
    try:
        _trigger_app_download_prompts_for_logs(logs, db)
    except Exception as e:
        # Don't fail the service logging if alert trigger fails
        print(f"Warning: Failed to trigger app download prompts: {e}")
    
    # 🔥 NEW: Award loyalty points for bulk logs
    try:
        _award_loyalty_points_for_logs(logs)
    except Exception as e:
        print(f"Warning: Failed to award loyalty points for bulk logs: {e}")
    
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
    
    # Filter by date - use timezone-aware datetime for comparison
    date_threshold = datetime.now(timezone.utc) + timedelta(days=days_ahead)
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


def _trigger_app_download_prompts_for_logs(logs: List[ServiceLog], db: Session):
    """Trigger app download prompts for guest users after service logging"""
    try:
        # Group logs by user_id to avoid duplicate prompts
        user_logs = {}
        for log in logs:
            if log.user_id not in user_logs:
                user_logs[log.user_id] = []
            user_logs[log.user_id].append(log)
        
        # Process each user's logs
        for user_id, user_service_logs in user_logs.items():
            # Get the first log for user info (all logs for same user will have same provider/vehicle info)
            first_log = user_service_logs[0]
            
            # Prepare vehicle info - pass vehicle_id for alert service to query
            vehicle_info = first_log.vehicle_id  # Pass the ID, alert service will query for details
            
            # Prepare service info
            service_names = [log.service_name for log in user_service_logs if log.service_name]
            service_type = service_names[0] if service_names else "Service"
            if len(service_names) > 1:
                service_type = f"{service_type} and {len(service_names)-1} other services"
            
            # 🔥 AlertService will now handle app detection internally and query for proper names
            # Pass provider_id so alert service can query for proper provider name
            _call_alert_service_for_app_prompt(
                user_id=user_id,
                vehicle_info=vehicle_info,
                service_provider_name=first_log.provider_id or first_log.provider_name or "Service Provider",
                service_type=service_type
            )
            
    except Exception as e:
        print(f"Error in _trigger_app_download_prompts_for_logs: {e}")


def _call_alert_service_for_app_prompt(
    user_id: int, 
    vehicle_info: str, 
    service_provider_name: str, 
    service_type: str
):
    """Call alert service to trigger app download prompt"""
    try:
        alert_service_url = os.getenv("ALERT_SERVICE_URL", "http://alert-service:8006")
        
        payload = {
            "user_id": user_id,
            "vehicle_info": vehicle_info,
            "service_provider_name": service_provider_name,
            "service_type": service_type,
            "discount_code": "FIRST10"
        }
        
        # Fire and forget - don't block service logging
        with httpx.Client(timeout=5.0) as client:
            response = client.post(
                f"{alert_service_url}/alerts/trigger/app-download-prompt",
                json=payload
            )
            
            if response.status_code == 200:
                print(f"✅ App download prompt triggered for user {user_id}")
            else:
                print(f"⚠️ Alert service returned {response.status_code} for user {user_id}")
                
    except Exception as e:
        print(f"❌ Failed to call alert service for user {user_id}: {e}")


def _award_loyalty_points_for_logs(logs: List[ServiceLog]):
    """Award loyalty points for service logs"""
    try:
        loyalty_url = os.getenv("LOYALTY_SERVICE_URL", "http://loyalty-service:8009")
        
        # Group by user to avoid duplicate calls for same user
        user_logs = {}
        for log in logs:
            if log.cost and log.user_id:
                if log.user_id not in user_logs:
                    user_logs[log.user_id] = []
                user_logs[log.user_id].append(log)
        
        # Award points for each user (aggregate costs)
        for user_id, user_service_logs in user_logs.items():
            total_cost = sum(log.cost for log in user_service_logs if log.cost)
            if total_cost > 0:
                # Use first log for provider/service context
                first_log = user_service_logs[0]
                body = {
                    "user_id": user_id,
                    "provider_id": first_log.provider_id,
                    "service_id": first_log.service_id,
                    "amount_spent": total_cost,
                    "reference_type": "service_log",
                    "reference_id": first_log.id,  # Reference first log
                }
                
                # Fire and forget
                try:
                    with httpx.Client(timeout=3.0) as client:
                        response = client.post(f"{loyalty_url}/loyalty/points/award", json=body)
                        if response.status_code == 200:
                            result = response.json()
                            print(f"✅ Awarded {result.get('points_awarded', 0)} points to user {user_id}")
                        else:
                            print(f"⚠️ Loyalty service returned {response.status_code} for user {user_id}")
                except Exception as e:
                    print(f"❌ Failed to award loyalty points for user {user_id}: {e}")
                    
    except Exception as e:
        print(f"❌ Error in _award_loyalty_points_for_logs: {e}")
