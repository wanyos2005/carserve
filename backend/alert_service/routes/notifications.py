# backend/alert_service/routes/notifications.py
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional

from core.db import get_db
from models.alert import AlertPreference, AlertType, AlertChannel
from schemas.alert import AlertPreferenceCreate, AlertPreferenceResponse
from services.notification_service import NotificationService

router = APIRouter()

@router.post("/preferences", response_model=AlertPreferenceResponse)
async def create_alert_preference(
    preference_data: AlertPreferenceCreate,
    db: Session = Depends(get_db)
):
    """Create or update alert preferences for a user"""
    # Check if preference already exists
    existing = db.query(AlertPreference).filter(
        AlertPreference.user_id == preference_data.user_id,
        AlertPreference.alert_type == preference_data.alert_type
    ).first()
    
    if existing:
        # Update existing preference
        existing.is_enabled = preference_data.is_enabled
        existing.channels = preference_data.channels
        existing.frequency = preference_data.frequency
        existing.quiet_hours_start = preference_data.quiet_hours_start
        existing.quiet_hours_end = preference_data.quiet_hours_end
        existing.timezone = preference_data.timezone
        existing.min_priority = preference_data.min_priority
        existing.batch_alerts = preference_data.batch_alerts
        db.commit()
        db.refresh(existing)
        return existing
    else:
        # Create new preference
        preference = AlertPreference(
            user_id=preference_data.user_id,
            alert_type=preference_data.alert_type,
            is_enabled=preference_data.is_enabled,
            channels=preference_data.channels,
            frequency=preference_data.frequency,
            quiet_hours_start=preference_data.quiet_hours_start,
            quiet_hours_end=preference_data.quiet_hours_end,
            timezone=preference_data.timezone,
            min_priority=preference_data.min_priority,
            batch_alerts=preference_data.batch_alerts
        )
        db.add(preference)
        db.commit()
        db.refresh(preference)
        return preference

@router.get("/preferences/{user_id}", response_model=List[AlertPreferenceResponse])
async def get_user_alert_preferences(
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get all alert preferences for a user"""
    preferences = db.query(AlertPreference).filter(
        AlertPreference.user_id == user_id
    ).all()
    return preferences

@router.get("/preferences/{user_id}/{alert_type}", response_model=AlertPreferenceResponse)
async def get_user_alert_preference(
    user_id: int,
    alert_type: AlertType,
    db: Session = Depends(get_db)
):
    """Get specific alert preference for a user"""
    preference = db.query(AlertPreference).filter(
        AlertPreference.user_id == user_id,
        AlertPreference.alert_type == alert_type
    ).first()
    
    if not preference:
        raise HTTPException(status_code=404, detail="Alert preference not found")
    return preference

@router.delete("/preferences/{user_id}/{alert_type}")
async def delete_alert_preference(
    user_id: int,
    alert_type: AlertType,
    db: Session = Depends(get_db)
):
    """Delete an alert preference"""
    preference = db.query(AlertPreference).filter(
        AlertPreference.user_id == user_id,
        AlertPreference.alert_type == alert_type
    ).first()
    
    if not preference:
        raise HTTPException(status_code=404, detail="Alert preference not found")
    
    db.delete(preference)
    db.commit()
    return {"message": "Alert preference deleted"}

@router.post("/test/{user_id}")
async def send_test_notification(
    user_id: int,
    channel: AlertChannel,
    background_tasks: BackgroundTasks,
    message: str = "This is a test notification",
    db: Session = Depends(get_db)
):
    """Send a test notification to a user"""
    notification_service = NotificationService(db)
    
    # Create a test alert
    from models.alert import Alert, AlertType, AlertStatus
    from datetime import datetime
    
    test_alert = Alert(
        id="test-alert",
        user_id=user_id,
        type=AlertType.PROMOTIONAL,
        title="Test Notification",
        message=message,
        priority=1,
        channels=[channel],
        status=AlertStatus.PENDING,
        created_at=datetime.utcnow()
    )
    
    background_tasks.add_task(notification_service.send_alert, test_alert)
    return {"message": f"Test {channel} notification sent to user {user_id}"}

