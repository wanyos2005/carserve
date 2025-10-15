
from typing import List, Optional
from datetime import datetime
import enum

from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, or_

from models.alert import Alert, AlertType, AlertStatus
from schemas.alert import AlertCreate, AlertUpdate


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


def create_alert(db: Session, payload: AlertCreate) -> Alert:
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
    return alert


def get_alert(db: Session, alert_id: str) -> Optional[Alert]:
    return db.query(Alert).filter(Alert.id == alert_id).first()


def list_alerts(
    db: Session,
    user_id: Optional[int] = None,
    alert_type: Optional[AlertType] = None,
    status: Optional[AlertStatus] = None,
    limit: int = 50,
    offset: int = 0,
) -> List[Alert]:
    query = db.query(Alert)
    if user_id is not None:
        query = query.filter(Alert.user_id == user_id)
    if alert_type is not None:
        query = query.filter(Alert.type == alert_type)
    if status is not None:
        query = query.filter(Alert.status == status)
    return query.order_by(desc(Alert.created_at)).offset(offset).limit(limit).all()


def update_alert(db: Session, alert_id: str, updates: AlertUpdate) -> Optional[Alert]:
    alert = get_alert(db, alert_id)
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
    return alert


def delete_alert(db: Session, alert_id: str) -> bool:
    alert = get_alert(db, alert_id)
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

