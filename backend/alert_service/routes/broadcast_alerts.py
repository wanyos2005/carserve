# backend/alert_service/routes/broadcast_alerts.py
"""
Drivon Alerts – Broadcast Alert endpoints.

Admins create/publish broadcast alerts (OSINT-sourced) that are fanned out
to all users.  Users fetch active alerts via GET /broadcast-alerts/active.
"""
from fastapi import APIRouter, Depends, HTTPException, Header, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone
import logging

from core.db import get_db
from models.alert import BroadcastAlert, BroadcastAlertStatus
from schemas.alert import BroadcastAlertCreate, BroadcastAlertUpdate, BroadcastAlertResponse
from celery_app import celery_app
import uuid

router = APIRouter()
logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# Lightweight admin guard
# Checks that the caller provides a valid user JWT and that user is an admin,
# by delegating to user-service.  Falls back to a static ADMIN_SECRET env var
# for internal/service-to-service calls.
# ─────────────────────────────────────────────────────────────────────────────

async def require_admin(
    authorization: Optional[str] = Header(default=None),
    x_admin_secret: Optional[str] = Header(default=None, alias="x-admin-secret"),
) -> str:
    """Returns admin identifier (user_id string or 'system') if authorised."""
    from core.config import settings
    import aiohttp

    # Option 1: static admin secret (env var ADMIN_SECRET) for internal calls
    admin_secret = getattr(settings, "ADMIN_SECRET", None)
    if admin_secret and x_admin_secret == admin_secret:
        return "system"

    # Option 2: JWT bearer token – delegate role check to user-service
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ", 1)[1]
        try:
            async with aiohttp.ClientSession() as session:
                headers = {"Authorization": f"Bearer {token}"}
                async with session.get(
                    f"{settings.USER_SERVICE_URL}/me",
                    headers=headers,
                    timeout=aiohttp.ClientTimeout(total=5),
                ) as resp:
                    if resp.status == 200:
                        user_data = await resp.json()
                        is_admin = user_data.get("is_admin") or user_data.get("role") in ("admin", "super_admin")
                        if is_admin:
                            return str(user_data.get("id", "unknown"))
                        raise HTTPException(status_code=403, detail="Admin role required")
                    raise HTTPException(status_code=401, detail="Invalid token")
        except HTTPException:
            raise
        except Exception as exc:
            logger.error(f"Admin auth check failed: {exc}")
            raise HTTPException(status_code=503, detail="Auth service unavailable")

    raise HTTPException(status_code=401, detail="Authorization required")


# ─────────────────────────────────────────────────────────────────────────────
# Admin CRUD
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/", response_model=BroadcastAlertResponse, status_code=201)
async def create_broadcast_alert(
    data: BroadcastAlertCreate,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    """Create a broadcast alert (saved as DRAFT)."""
    alert = BroadcastAlert(
        id=str(uuid.uuid4()),
        title=data.title,
        message=data.message,
        type=data.type,
        priority=data.priority,
        channels=[c.value for c in data.channels],
        target_audience=data.target_audience,
        latitude=data.latitude,
        longitude=data.longitude,
        radius_km=data.radius_km,
        active_from=data.active_from,
        expires_at=data.expires_at,
        source=data.source,
        action_url=data.action_url,
        action_text=data.action_text,
        media_urls=data.media_urls,
        created_by_admin=admin_id,
        status=BroadcastAlertStatus.DRAFT,
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)
    logger.info(f"Broadcast alert created id={alert.id} by admin={admin_id}")
    return alert


@router.get("/", response_model=List[BroadcastAlertResponse])
async def list_broadcast_alerts(
    status: Optional[BroadcastAlertStatus] = None,
    alert_type: Optional[str] = None,
    limit: int = Query(50, le=200),
    offset: int = 0,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    """List all broadcast alerts (admin view)."""
    q = db.query(BroadcastAlert)
    if status:
        q = q.filter(BroadcastAlert.status == status)
    if alert_type:
        q = q.filter(BroadcastAlert.type == alert_type)
    return q.order_by(BroadcastAlert.created_at.desc()).offset(offset).limit(limit).all()


@router.get("/active", response_model=List[BroadcastAlertResponse])
def get_active_broadcast_alerts(
    alert_type: Optional[str] = None,
    limit: int = Query(20, le=100),
    db: Session = Depends(get_db),
):
    """Public endpoint – returns currently active (non-expired) broadcast alerts."""
    now = datetime.now(timezone.utc)
    q = db.query(BroadcastAlert).filter(BroadcastAlert.status == BroadcastAlertStatus.ACTIVE)
    if alert_type:
        q = q.filter(BroadcastAlert.type == alert_type)
    # Exclude expired ones even if not yet marked by the beat job
    q = q.filter(
        (BroadcastAlert.expires_at == None) | (BroadcastAlert.expires_at > now)
    )
    return q.order_by(BroadcastAlert.priority.desc(), BroadcastAlert.created_at.desc()).limit(limit).all()


@router.get("/{alert_id}", response_model=BroadcastAlertResponse)
async def get_broadcast_alert(
    alert_id: str,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    alert = db.query(BroadcastAlert).filter(BroadcastAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Broadcast alert not found")
    return alert


@router.patch("/{alert_id}", response_model=BroadcastAlertResponse)
async def update_broadcast_alert(
    alert_id: str,
    data: BroadcastAlertUpdate,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    alert = db.query(BroadcastAlert).filter(BroadcastAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Broadcast alert not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        if field == "channels" and value is not None:
            value = [c.value if hasattr(c, "value") else c for c in value]
        setattr(alert, field, value)
    db.commit()
    db.refresh(alert)
    return alert


@router.delete("/{alert_id}", status_code=204)
async def delete_broadcast_alert(
    alert_id: str,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    alert = db.query(BroadcastAlert).filter(BroadcastAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Broadcast alert not found")
    db.delete(alert)
    db.commit()


DRIVON_ALERTS_TOPIC = "drivon_alerts_all"


@router.post("/subscribe-push", status_code=200)
def subscribe_push(token: str, db: Session = Depends(get_db)):
    """
    Subscribe a single FCM token to the Drivon Alerts topic.
    Called fire-and-forget by user-service after saving an FCM token.
    No auth required — internal call; token is opaque to this service.
    """
    from core.config import settings
    from services.fcm_service import FCMService

    if not FCMService.is_initialized():
        FCMService.initialize(
            project_id=settings.FCM_PROJECT_ID,
            private_key=settings.FCM_PRIVATE_KEY,
            client_email=settings.FCM_CLIENT_EMAIL,
        )

    result = FCMService.subscribe_to_topic([token], DRIVON_ALERTS_TOPIC)
    if not result.get("success"):
        logger.warning(f"subscribe_push: topic subscription failed: {result.get('error')}")
    return {"subscribed": result.get("success_count", 0)}


@router.post("/unsubscribe-push", status_code=200)
def unsubscribe_push(token: str, db: Session = Depends(get_db)):
    """
    Unsubscribe a single FCM token from the Drivon Alerts topic.
    Called fire-and-forget by user-service before removing an FCM token.
    """
    from core.config import settings
    from services.fcm_service import FCMService

    if not FCMService.is_initialized():
        FCMService.initialize(
            project_id=settings.FCM_PROJECT_ID,
            private_key=settings.FCM_PRIVATE_KEY,
            client_email=settings.FCM_CLIENT_EMAIL,
        )

    result = FCMService.unsubscribe_from_topic([token], DRIVON_ALERTS_TOPIC)
    if not result.get("success"):
        logger.warning(f"unsubscribe_push: topic unsubscription failed: {result.get('error')}")
    return {"unsubscribed": result.get("success_count", 0)}


@router.post("/{alert_id}/publish", response_model=BroadcastAlertResponse)
async def publish_broadcast_alert(
    alert_id: str,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    """
    Move alert from DRAFT → ACTIVE and trigger fan-out to all users.
    The Celery task creates individual Alert records + delivers to each user.
    """
    alert = db.query(BroadcastAlert).filter(BroadcastAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Broadcast alert not found")
    if alert.status != BroadcastAlertStatus.DRAFT:
        raise HTTPException(status_code=400, detail=f"Alert is already {alert.status.value}")

    alert.status = BroadcastAlertStatus.ACTIVE
    alert.active_from = alert.active_from or datetime.now(timezone.utc)
    db.commit()
    db.refresh(alert)

    # Enqueue fan-out task (fire-and-forget)
    celery_app.send_task("broadcast_alert_fanout", args=[alert.id])
    logger.info(f"Broadcast alert {alert_id} published by admin={admin_id}, fanout enqueued")
    return alert
