# backend/alert_service/routes/notifications.py
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel

from core.db import get_db
from models.alert import AlertPreference, AlertType, AlertChannel, AlertStatus
from schemas.alert import AlertPreferenceCreate, AlertPreferenceResponse
from services.notification_service import NotificationService

router = APIRouter()

# Generic notification schemas for other services
class NotificationRequest(BaseModel):
    user_id: int
    title: str
    message: str
    channels: List[AlertChannel]
    priority: int = 1
    action_url: Optional[str] = None
    action_text: Optional[str] = None
    notification_type: str = "SOCIAL_NOTIFICATION"

class NotificationResponse(BaseModel):
    success: bool
    message: str
    notification_id: Optional[str] = None

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

@router.post("/send", response_model=NotificationResponse)
async def send_notification(
    notification: NotificationRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Generic notification endpoint for other services (Social, User, etc.)"""
    try:
        # Create alert-like object for processing
        from datetime import datetime
        import uuid
        
        alert = Alert(
            id=str(uuid.uuid4()),
            user_id=notification.user_id,
            type=AlertType.PROMOTIONAL,  # Use PROMOTIONAL for social notifications
            title=notification.title,
            message=notification.message,
            priority=notification.priority,
            channels=notification.channels,
            status=AlertStatus.PENDING,
            action_url=notification.action_url,
            action_text=notification.action_text,
            created_at=datetime.utcnow()
        )
        
        # Process through existing alert system
        notification_service = NotificationService(db)
        background_tasks.add_task(notification_service.send_alert, alert)
        
        return NotificationResponse(
            success=True,
            message=f"Notification queued for user {notification.user_id}",
            notification_id=alert.id
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send notification: {str(e)}")

@router.get("/logs/{user_id}", response_model=List[dict])
async def get_notification_logs(
    user_id: int,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    channel: Optional[AlertChannel] = None,
    status: Optional[AlertStatus] = None,
    db: Session = Depends(get_db)
):
    """Get notification logs for a user"""
    try:
        from models.alert import NotificationLog
        
        query = db.query(NotificationLog).filter(NotificationLog.user_id == user_id)
        
        if channel:
            query = query.filter(NotificationLog.channel == channel)
        if status:
            query = query.filter(NotificationLog.status == status)
            
        logs = query.order_by(NotificationLog.sent_at.desc()).offset(offset).limit(limit).all()
        
        return [
            {
                "id": log.id,
                "alert_id": log.alert_id,
                "user_id": log.user_id,
                "channel": log.channel.value,
                "status": log.status.value,
                "external_id": log.external_id,
                "sent_at": log.sent_at.isoformat() if log.sent_at else None,
                "delivered_at": log.delivered_at.isoformat() if log.delivered_at else None,
                "error_message": log.error_message,
                "retry_count": log.retry_count
            }
            for log in logs
        ]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get notification logs: {str(e)}")

@router.get("/logs/stats/{user_id}")
async def get_notification_stats(
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get notification statistics for a user"""
    try:
        from models.alert import NotificationLog
        from sqlalchemy import func
        
        # Get total counts by status
        status_counts = db.query(
            NotificationLog.status,
            func.count(NotificationLog.id).label('count')
        ).filter(
            NotificationLog.user_id == user_id
        ).group_by(NotificationLog.status).all()
        
        # Get total counts by channel
        channel_counts = db.query(
            NotificationLog.channel,
            func.count(NotificationLog.id).label('count')
        ).filter(
            NotificationLog.user_id == user_id
        ).group_by(NotificationLog.channel).all()
        
        # Get recent activity (last 7 days)
        from datetime import datetime, timedelta
        week_ago = datetime.utcnow() - timedelta(days=7)
        
        recent_count = db.query(NotificationLog).filter(
            NotificationLog.user_id == user_id,
            NotificationLog.sent_at >= week_ago
        ).count()
        
        return {
            "user_id": user_id,
            "status_breakdown": {status.value: count for status, count in status_counts},
            "channel_breakdown": {channel.value: count for channel, count in channel_counts},
            "recent_activity": {
                "last_7_days": recent_count
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get notification stats: {str(e)}")

