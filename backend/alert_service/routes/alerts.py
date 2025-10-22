# backend/alert_service/routes/alerts.py
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import json

from core.db import get_db
from models.alert import Alert, AlertType, AlertStatus, AlertChannel
from schemas.alert import AlertCreate, AlertResponse, AlertUpdate, AppDownloadPromptRequest, AppDownloadPromptResponse
from services.rule_engine import RuleEngine
from crud.alert import (
    create_alert as crud_create_alert,
    list_alerts as crud_list_alerts,
    get_alert as crud_get_alert,
    update_alert as crud_update_alert,
    delete_alert as crud_delete_alert,
    get_unread_count as crud_unread_count,
    mark_alert_read as crud_mark_read,
)
import logging
import asyncio
from datetime import datetime
from services.notification_service import NotificationService
from celery_app import celery_app

router = APIRouter()

@router.post("/", response_model=AlertResponse)
def create_alert(
    alert_data: AlertCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Create a new alert (simple sync style like booking_service)."""
    try:
        logging.getLogger("uvicorn").info("create_alert: entering crud_create_alert")
        alert = crud_create_alert(db, alert_data)
        logging.getLogger("uvicorn").info(f"create_alert: created alert id={alert.id}")
        # Enqueue delivery to Celery (fire-and-forget)
        celery_app.send_task("deliver_alert", args=[alert.id])
    except Exception as exc:
        # Ensure any failed transaction is rolled back and error is surfaced
        try:
            db.rollback()
        except Exception:
            pass
        logging.getLogger("uvicorn").error(f"create_alert failed: {exc}")
        raise HTTPException(status_code=500, detail="Failed to create alert")
    return alert


def _deliver_alert_background(alert_id: str) -> None:
    """Background job: load alert and deliver via NotificationService.
    Runs in a thread after response returns.
    """
    from core.db import SessionLocal
    from models.alert import AlertStatus

    logger = logging.getLogger("uvicorn")
    db = SessionLocal()
    try:
        alert = crud_get_alert(db, alert_id)
        if not alert:
            logger.error(f"_deliver_alert_background: alert not found id={alert_id}")
            return
        service = NotificationService(db)
        try:
            asyncio.run(service.send_alert(alert))
            alert.status = AlertStatus.DELIVERED
            alert.delivered_at = datetime.utcnow()
        except Exception as exc:
            logger.error(f"_deliver_alert_background: delivery failed for {alert_id}: {exc}")
            alert.status = AlertStatus.FAILED
            alert.error_message = str(exc)
        finally:
            db.commit()
    finally:
        db.close()

@router.get("/", response_model=List[AlertResponse])
def get_alerts(
    user_id: Optional[int] = None,
    alert_type: Optional[AlertType] = None,
    status: Optional[AlertStatus] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """Get alerts with optional filtering"""
    return crud_list_alerts(db, user_id=user_id, alert_type=alert_type, status=status, limit=limit, offset=offset)

@router.get("/{alert_id}", response_model=AlertResponse)
def get_alert(alert_id: str, db: Session = Depends(get_db)):
    """Get a specific alert by ID"""
    alert = crud_get_alert(db, alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return alert

@router.patch("/{alert_id}", response_model=AlertResponse)
def update_alert(
    alert_id: str,
    alert_update: AlertUpdate,
    db: Session = Depends(get_db)
):
    """Update an alert"""
    alert = crud_update_alert(db, alert_id, alert_update)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return alert

@router.delete("/{alert_id}")
def delete_alert(alert_id: str, db: Session = Depends(get_db)):
    """Delete an alert"""
    success = crud_delete_alert(db, alert_id)
    if not success:
        raise HTTPException(status_code=404, detail="Alert not found")
    return {"message": "Alert deleted successfully"}

@router.post("/trigger/insurance-expiry")
async def trigger_insurance_expiry_alerts(
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Manually trigger insurance expiry alerts (for testing/scheduling)"""
    rule_engine = RuleEngine(db)
    background_tasks.add_task(rule_engine.check_insurance_expiry)
    return {"message": "Insurance expiry check triggered"}

@router.post("/trigger/service-due")
async def trigger_service_due_alerts(
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Manually trigger service due alerts (for testing/scheduling)"""
    rule_engine = RuleEngine(db)
    background_tasks.add_task(rule_engine.check_service_due)
    return {"message": "Service due check triggered"}

@router.post("/trigger/app-download-prompt", response_model=AppDownloadPromptResponse)
async def trigger_app_download_prompt(
    request_data: AppDownloadPromptRequest,
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db)
):
    """Trigger app download prompt when a service is logged for a user without the app"""
    try:
        from services.alert_service import AlertService
        alert_service = AlertService(db)
        
        alert = await alert_service.trigger_app_download_prompt(
            user_id=request_data.user_id,
            vehicle_info=request_data.vehicle_info,
            service_provider_name=request_data.service_provider_name,
            service_type=request_data.service_type,
            discount_code=request_data.discount_code
        )
        
        if alert:
            # Enqueue delivery to Celery (fire-and-forget)
            celery_app.send_task("deliver_alert", args=[alert.id])
            return AppDownloadPromptResponse(
                message="App download prompt triggered successfully",
                alert_id=alert.id,
                user_id=request_data.user_id,
                discount_code=request_data.discount_code,
                success=True
            )
        else:
            return AppDownloadPromptResponse(
                message="App download prompt skipped - user already has app or prompt not needed",
                alert_id=None,
                user_id=request_data.user_id,
                discount_code=request_data.discount_code,
                success=False
            )
            
    except Exception as e:
        logging.getLogger("uvicorn").error(f"Failed to trigger app download prompt: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to trigger app download prompt: {str(e)}")

@router.get("/user/{user_id}/unread-count")
def get_unread_alert_count(user_id: int, db: Session = Depends(get_db)):
    """Get count of unread alerts for a user"""
    count = crud_unread_count(db, user_id)
    return {"user_id": user_id, "unread_count": count}

@router.patch("/{alert_id}/mark-read")
def mark_alert_read(alert_id: str, db: Session = Depends(get_db)):
    """Mark an alert as read"""
    success = crud_mark_read(db, alert_id)
    if not success:
        raise HTTPException(status_code=404, detail="Alert not found")
    return {"message": "Alert marked as read"}
