# backend/alert_service/routes/alerts.py
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status, Body, Query, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional, Any, Dict
from datetime import datetime, timedelta
import json

from core.db import get_db
from models.alert import Alert, AlertType, AlertStatus, AlertChannel, AlertPreference
from schemas.alert import AlertCreate, AlertPreferenceCreate, AlertPreferenceResponse, AlertResponse, AlertUpdate, AppDownloadPromptRequest, AppDownloadPromptResponse
from services.rule_engine import RuleEngine
from services.alert_service import AlertService
import logging
import asyncio
from datetime import datetime
from services.notification_service import NotificationService
from celery_app import celery_app
from pydantic import BaseModel

router = APIRouter()

@router.post("/", response_model=AlertResponse)
def create_alert(
    alert_data: AlertCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Create a new alert (simple sync style like booking_service)."""
    try:
        service = AlertService(db)
        alert = service.create_alert_sync(alert_data)
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
        alert = db.query(Alert).filter(Alert.id == alert_id).first()
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
async def get_alerts(
    user_id: Optional[int] = None,
    alert_type: Optional[AlertType] = None,
    status: Optional[AlertStatus] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """Get alerts with optional filtering"""
    service = AlertService(db)
    return await service.get_alerts(user_id=user_id, alert_type=alert_type, status=status, limit=limit, offset=offset)

@router.get("/{alert_id}", response_model=AlertResponse)
async def get_alert(alert_id: str, db: Session = Depends(get_db)):
    """Get a specific alert by ID"""
    service = AlertService(db)
    alert = await service.get_alert(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return alert

@router.patch("/{alert_id}", response_model=AlertResponse)
async def update_alert(
    alert_id: str,
    alert_update: AlertUpdate,
    db: Session = Depends(get_db)
):
    """Update an alert"""
    service = AlertService(db)
    alert = await service.update_alert(alert_id, alert_update)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return alert

@router.delete("/{alert_id}")
async def delete_alert(alert_id: str, db: Session = Depends(get_db)):
    """Delete an alert"""
    service = AlertService(db)
    success = await service.delete_alert(alert_id)
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
async def get_unread_alert_count(user_id: int, db: Session = Depends(get_db)):
    """Get count of unread alerts for a user"""
    service = AlertService(db)
    count = await service.get_unread_count(user_id)
    return {"user_id": user_id, "unread_count": count}

@router.patch("/{alert_id}/mark-read")
async def mark_alert_read(alert_id: str, db: Session = Depends(get_db)):
    """Mark an alert as read"""
    service = AlertService(db)
    success = await service.mark_alert_read(alert_id)
    if not success:
        raise HTTPException(status_code=404, detail="Alert not found")
    return {"message": "Alert marked as read"}


# =============================================================================
# PRODUCTION TOPIC BROADCAST ENDPOINTS
# =============================================================================

class TopicBroadcastRequest(BaseModel):
    topic: str
    title: str
    message: str
    data: Optional[Dict[str, Any]] = None
    image_url: Optional[str] = None
"""example: curl -i -X POST 'http://localhost:8006/alerts/broadcast/topic' -H 'Content-Type: application/json' --data '{"topic":"promotions.city.nairobi",
"title":"Road Alert","message":"Accident on A104"}'"""
@router.post("/broadcast/topic")
async def broadcast_to_topic(payload: TopicBroadcastRequest, db: Session = Depends(get_db)):
    """Production topic broadcast via NotificationService."""
    service = NotificationService(db)
    result = await service.broadcast_to_topic(
        topic=payload.topic,
        title=payload.title,
        message=payload.message,
        data=payload.data,
        image_url=payload.image_url,
    )
    if result.get("success"):
        return {"success": True, "topic": payload.topic, "message_id": result.get("message_id")}
    raise HTTPException(status_code=500, detail=result.get("error", "Topic broadcast failed"))

"""example: curl -i -X POST 'http://localhost:8006/alerts/broadcast/topic/form' -F 'topic=promotions.city.nairobi' -F 'title=Road Alert' -F 'message=Accident on A104' -F 'image_file=@path/to/image.jpg'"""
@router.post("/broadcast/topic/form")
async def broadcast_to_topic_form(
    topic: str = Form(...),
    title: str = Form(...),
    message: str = Form(...),
    image_url: Optional[str] = Form(None),
    image_file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    """Multipart-friendly topic broadcast.
    Notes:
      - If image_file is provided, you must first upload it to object storage and provide image_url.
      - This endpoint will only pass through image_url to FCM.
    """
    if image_file is not None and not image_url:
        # Storage pipeline not configured here; require URL for now
        raise HTTPException(status_code=400, detail="image_url is required when sending image; upload the file to storage and provide its URL")

    service = NotificationService(db)
    result = await service.broadcast_to_topic(
        topic=topic,
        title=title,
        message=message,
        data=None,
        image_url=image_url,
    )
    if result.get("success"):
        return {"success": True, "topic": topic, "message_id": result.get("message_id")}
    raise HTTPException(status_code=500, detail=result.get("error", "Topic broadcast failed"))

class TopicSubscriptionRequest(BaseModel):
    topic: str
    tokens: List[str]

@router.post("/broadcast/topic/subscribe")
async def subscribe_tokens_to_topic(payload: TopicSubscriptionRequest, db: Session = Depends(get_db)):
    """Subscribe device tokens to a topic."""
    service = NotificationService(db)
    result = await service.subscribe_tokens_to_topic(payload.topic, payload.tokens)
    if result.get("success"):
        return result
    raise HTTPException(status_code=500, detail=result.get("error", "Subscription failed"))

@router.post("/broadcast/topic/unsubscribe")
async def unsubscribe_tokens_from_topic(payload: TopicSubscriptionRequest, db: Session = Depends(get_db)):
    """Unsubscribe device tokens from a topic."""
    service = NotificationService(db)
    result = await service.unsubscribe_tokens_from_topic(payload.topic, payload.tokens)
    if result.get("success"):
        return result
    raise HTTPException(status_code=500, detail=result.get("error", "Unsubscription failed"))

# =============================================================================
# PREFERENCES AND GENERIC NOTIFICATION ENDPOINTS (migrated from notifications.py)
# =============================================================================

from schemas.alert import AlertPreferenceCreate, AlertPreferenceResponse
from fastapi import Query, status as http_status
from pydantic import BaseModel

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
    existing = db.query(AlertPreference).filter(
        AlertPreference.user_id == preference_data.user_id,
        AlertPreference.alert_type == preference_data.alert_type
    ).first()
    if existing:
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
    preference = db.query(AlertPreference).filter(
        AlertPreference.user_id == user_id,
        AlertPreference.alert_type == alert_type
    ).first()
    if not preference:
        raise HTTPException(status_code=404, detail="Alert preference not found")
    db.delete(preference)
    db.commit()
    return {"message": "Alert preference deleted"}

@router.post("/notify", response_model=NotificationResponse)
async def send_notification_generic(
    notification: NotificationRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    try:
        from datetime import datetime
        import uuid
        # Create a transient Alert-like object for NotificationService
        alert = Alert(
            id=str(uuid.uuid4()),
            user_id=notification.user_id,
            type=AlertType.PROMOTIONAL,
            title=notification.title,
            message=notification.message,
            priority=notification.priority,
            channels=notification.channels,
            status=AlertStatus.PENDING,
            action_url=notification.action_url,
            action_text=notification.action_text,
            created_at=datetime.utcnow()
        )
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
    try:
        from models.alert import NotificationLog
        from sqlalchemy import desc as sa_desc
        query = db.query(NotificationLog).filter(NotificationLog.user_id == user_id)
        if channel:
            query = query.filter(NotificationLog.channel == channel)
        if status:
            query = query.filter(NotificationLog.status == status)
        logs = query.order_by(sa_desc(NotificationLog.sent_at)).offset(offset).limit(limit).all()
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
    try:
        from models.alert import NotificationLog
        from sqlalchemy import func
        week_ago = datetime.utcnow() - timedelta(days=7)
        status_counts = db.query(
            NotificationLog.status,
            func.count(NotificationLog.id).label('count')
        ).filter(
            NotificationLog.user_id == user_id
        ).group_by(NotificationLog.status).all()
        channel_counts = db.query(
            NotificationLog.channel,
            func.count(NotificationLog.id).label('count')
        ).filter(
            NotificationLog.user_id == user_id
        ).group_by(NotificationLog.channel).all()
        recent_count = db.query(NotificationLog).filter(
            NotificationLog.user_id == user_id,
            NotificationLog.sent_at >= week_ago
        ).count()
        return {
            "user_id": user_id,
            "status_breakdown": {status.value: count for status, count in status_counts},
            "channel_breakdown": {channel.value: count for channel, count in channel_counts},
            "recent_activity": {"last_7_days": recent_count}
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get notification stats: {str(e)}")
@router.post("/test/fcm/multicast")
async def test_fcm_multicast(
    tokens: List[str],
    title: str = "Test Multicast Notification",
    body: str = "This is a test multicast notification from DriveOn",
    db: Session = Depends(get_db)
):
    """Test FCM multicast notification sending"""
    try:
        from services.fcm_service import FCMService
        from core.config import settings
        
        # Initialize FCM service if not already done
        if not FCMService.is_initialized():
            if not FCMService.initialize(
                project_id=settings.FCM_PROJECT_ID,
                private_key=settings.FCM_PRIVATE_KEY,
                client_email=settings.FCM_CLIENT_EMAIL
            ):
                raise HTTPException(status_code=500, detail="Failed to initialize FCM service")
        
        # Send test multicast notification
        result = FCMService.send_multicast_notification(
            tokens=tokens,
            title=title,
            body=body,
            data={
                "type": "test_multicast",
                "alert_id": "test-multicast-123",
                "action_url": "https://driveon.com/test"
            }
        )
        
        if result['success']:
            return {
                "message": f"Test multicast notification sent to {result.get('success_count', 0)}/{len(tokens)} devices",
                "success_count": result.get('success_count'),
                "failure_count": result.get('failure_count'),
                "result": result
            }
        else:
            raise HTTPException(status_code=500, detail=f"Failed to send multicast notification: {result.get('error')}")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.post("/test/fcm/topic")
async def test_fcm_topic(
    topic: str,
    title: str = "Test Topic Notification",
    body: str = "This is a test topic notification from DriveOn",
    db: Session = Depends(get_db)
):
    """Test FCM topic notification sending"""
    try:
        from services.fcm_service import FCMService
        from core.config import settings
        
        # Initialize FCM service if not already done
        if not FCMService.is_initialized():
            if not FCMService.initialize(
                project_id=settings.FCM_PROJECT_ID,
                private_key=settings.FCM_PRIVATE_KEY,
                client_email=settings.FCM_CLIENT_EMAIL
            ):
                raise HTTPException(status_code=500, detail="Failed to initialize FCM service")
        
        # Send test topic notification
        result = FCMService.send_topic_notification(
            topic=topic,
            title=title,
            body=body,
            data={
                "type": "test_topic",
                "alert_id": "test-topic-123",
                "action_url": "https://driveon.com/test"
            }
        )
        
        if result['success']:
            return {
                "message": f"Test topic notification sent to topic '{topic}'",
                "message_id": result.get('message_id'),
                "result": result
            }
        else:
            raise HTTPException(status_code=500, detail=f"Failed to send topic notification: {result.get('error')}")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

# (Removed FCM status test)

# =============================================================================
# SOCIAL NOTIFICATION ENDPOINTS (Centralized)
# =============================================================================

@router.post("/social/send")
async def send_social_notification(
    user_id: int,
    title: str,
    message: str,
    notification_type: str,
    data: dict = None,
    fcm_token: str = None,
    db: Session = Depends(get_db)
):
    """Send social notification to a single user"""
    try:
        from services.notification_service import NotificationService
        service = NotificationService(db)
        
        result = await service.send_social_notification(
            user_id=user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            data=data,
            fcm_token=fcm_token
        )
        
        if result['success']:
            return result
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result['message']
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send social notification: {str(e)}"
        )
@router.post("/social/multicast")
async def send_multicast_social_notification(
    title: str = Query(...),
    message: str = Query(...),
    notification_type: str = Query(...),
    # Accept user IDs from multiple sources for flexibility
    user_ids_q: Optional[list[int]] = Query(default=None, alias="user_ids"),
    body: Any = Body(default=None),
    db: Session = Depends(get_db)
):
    """Send social notification to multiple users.
    Accepts user_ids as:
      - query: repeated user_ids=1&user_ids=2
      - body array: [1,2,3]
      - body object: {"user_ids":[1,2,3]}
Body object
    curl -i -X POST 'http://localhost:8006/alerts/social/multicast?title=Promo&message=Big%20sale&notification_type=multicast_test' -H 'Content-Type: application/json' --data '{"user_ids":[2,3,4]}'
Body array
    curl -i -X POST 'http://localhost:8006/alerts/social/multicast?title=Promo&message=Big%20sale&notification_type=multicast_test' -H 'Content-Type: application/json' --data '[2,3,4]'
Query only
    curl -i -X POST 'http://localhost:8006/alerts/social/multicast?title=Promo&message=Big%20sale&notification_type=multicast_test&user_ids=2&user_ids=3&user_ids=4'

    """
    try:
        # Resolve user_ids
        resolved_ids: Optional[list[int]] = None
        if user_ids_q:
            resolved_ids = user_ids_q
        elif isinstance(body, list):
            resolved_ids = body
        elif isinstance(body, dict) and 'user_ids' in body:
            resolved_ids = body.get('user_ids')

        if not resolved_ids or not isinstance(resolved_ids, list):
            raise HTTPException(status_code=422, detail="user_ids are required (query: user_ids, body array, or body.user_ids)")

        from services.notification_service import NotificationService
        service = NotificationService(db)

        # Optional extras may be provided in body when it's an object
        extra_data = body.get('data') if isinstance(body, dict) else None
        extra_tokens = body.get('fcm_tokens') if isinstance(body, dict) else None

        result = await service.send_multicast_social_notification(
            user_ids=resolved_ids,
            title=title,
            message=message,
            notification_type=notification_type,
            data=extra_data,
            fcm_tokens=extra_tokens
        )

        if result['success']:
            return result
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result['message']
            )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send multicast social notification: {str(e)}"
        )

@router.post("/social/new-post")
async def send_new_post_notification(
    post_id: str,
    user_id: int,
    content: str,
    followers: list,
    db: Session = Depends(get_db)
):
    """Send new post notification to followers"""
    try:
        from services.notification_service import NotificationService
        service = NotificationService(db)
        
        # Truncate content for notification
        notification_body = content[:100] + "..." if len(content) > 100 else content
        
        result = await service.send_multicast_social_notification(
            user_ids=followers,
            title="New Post from DriveOn",
            message=notification_body,
            notification_type="new_post",
            data={
                "post_id": post_id,
                "user_id": str(user_id),
                "action_url": f"https://driveon.com/social/post/{post_id}"
            }
        )
        
        if result['success']:
            return result
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result['message']
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send new post notification: {str(e)}"
        )

@router.post("/social/new-like")
async def send_new_like_notification(
    post_id: str,
    liker_id: int,
    liker_name: str,
    post_owner_id: int,
    db: Session = Depends(get_db)
):
    """Send new like notification to post owner"""
    try:
        from services.notification_service import NotificationService
        service = NotificationService(db)
        
        result = await service.send_social_notification(
            user_id=post_owner_id,
            title="New Like!",
            message=f"{liker_name} liked your post",
            notification_type="new_like",
            data={
                "post_id": post_id,
                "liker_id": str(liker_id),
                "action_url": f"https://driveon.com/social/post/{post_id}"
            }
        )
        
        if result['success']:
            return result
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result['message']
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send new like notification: {str(e)}"
        )

@router.post("/social/new-comment")
async def send_new_comment_notification(
    post_id: str,
    commenter_id: int,
    commenter_name: str,
    comment: str,
    post_owner_id: int,
    db: Session = Depends(get_db)
):
    """Send new comment notification to post owner"""
    try:
        from services.notification_service import NotificationService
        service = NotificationService(db)
        
        # Truncate comment for notification
        notification_body = comment[:50] + "..." if len(comment) > 50 else comment
        
        result = await service.send_social_notification(
            user_id=post_owner_id,
            title="New Comment!",
            message=f"{commenter_name}: {notification_body}",
            notification_type="new_comment",
            data={
                "post_id": post_id,
                "commenter_id": str(commenter_id),
                "action_url": f"https://driveon.com/social/post/{post_id}"
            }
        )
        
        if result['success']:
            return result
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=result['message']
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send new comment notification: {str(e)}"
        )

"""this file deals with HTTP concerns
Parse multipart/form-data (Form fields + File/UploadFile).
If a file is included, upload it to storage (e.g., R2/S3), get an image_url.
Normalize all inputs into simple types (strings, lists, dicts) and pass to the service."""