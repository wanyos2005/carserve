
from typing import List, Optional
from datetime import datetime
import enum

from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, or_

from models.alert import Alert, AlertType, AlertStatus
from schemas.alert import AlertCreate, AlertUpdate, AlertResponse


def _normalize_channels(raw_channels) -> list[str]:
    if not raw_channels:
        return []
    result: list[str] = []
    for c in raw_channels:
        if isinstance(c, enum.Enum):
            result.append(c.value)
        else:
            result.append(str(c))
    return result


def _alert_to_response(alert: Alert) -> AlertResponse:
    """Convert SQLAlchemy Alert model to Pydantic AlertResponse"""
    return AlertResponse(
        id=alert.id,
        user_id=alert.user_id,
        type=alert.type,
        title=alert.title,
        message=alert.message,
        priority=alert.priority,
        vehicle_id=alert.vehicle_id,
        policy_id=alert.policy_id,
        booking_id=alert.booking_id,
        provider_id=alert.provider_id,
        channels=_normalize_channels(alert.channels),
        status=alert.status,
        scheduled_at=alert.scheduled_at,
        sent_at=alert.sent_at,
        delivered_at=alert.delivered_at,
        action_url=alert.action_url,
        action_text=alert.action_text,
        alert_metadata=alert.alert_metadata,
        retry_count=alert.retry_count,
        error_message=alert.error_message,
        created_at=alert.created_at,
        updated_at=alert.updated_at,
    )


def create_alert(db: Session, payload: AlertCreate) -> AlertResponse:
    alert = Alert(
        user_id=payload.user_id,
        type=payload.type,
        title=payload.title,
        message=payload.message,
        priority=payload.priority,
        vehicle_id=payload.vehicle_id,
        policy_id=payload.policy_id,
        booking_id=payload.booking_id,
        provider_id=payload.provider_id,
        channels=_normalize_channels(payload.channels),
        scheduled_at=payload.scheduled_at,
        action_url=payload.action_url,
        action_text=payload.action_text,
        alert_metadata=payload.alert_metadata,
    )

    db.add(alert)
    db.commit()
    db.refresh(alert)
    return _alert_to_response(alert)


def get_alert(db: Session, alert_id: str) -> Optional[AlertResponse]:
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    return _alert_to_response(alert) if alert else None


def list_alerts(
    db: Session,
    user_id: Optional[int] = None,
    alert_type: Optional[AlertType] = None,
    status: Optional[AlertStatus] = None,
    limit: int = 50,
    offset: int = 0,
) -> List[AlertResponse]:
    query = db.query(Alert)
    if user_id is not None:
        query = query.filter(Alert.user_id == user_id)
    if alert_type is not None:
        query = query.filter(Alert.type == alert_type)
    if status is not None:
        query = query.filter(Alert.status == status)
    
    alerts = query.order_by(desc(Alert.created_at)).offset(offset).limit(limit).all()
    return [_alert_to_response(alert) for alert in alerts]


def update_alert(db: Session, alert_id: str, updates: AlertUpdate) -> Optional[AlertResponse]:
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        return None
    data = updates.dict(exclude_unset=True)
    if "channels" in data:
        data["channels"] = _normalize_channels(data["channels"])  # ensure strings
    for k, v in data.items():
        setattr(alert, k, v)
    alert.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(alert)
    return _alert_to_response(alert)


def delete_alert(db: Session, alert_id: str) -> bool:
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        return False
    db.delete(alert)
    db.commit()
    return True


def get_unread_count(db: Session, user_id: int) -> int:
    return db.query(Alert).filter(
        and_(
            Alert.user_id == user_id,
            Alert.status.in_([AlertStatus.PENDING, AlertStatus.SENT]),
        )
    ).count()


def mark_alert_read(db: Session, alert_id: str) -> bool:
    alert = get_alert(db, alert_id)
    if not alert:
        return False
    alert.status = AlertStatus.DELIVERED
    alert.delivered_at = datetime.utcnow()
    db.commit()
    return True

