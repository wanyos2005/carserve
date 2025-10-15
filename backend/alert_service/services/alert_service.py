# backend/alert_service/services/alert_service.py
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc
from typing import List, Optional
from datetime import datetime

from models.alert import Alert, AlertType, AlertStatus
from schemas.alert import AlertCreate, AlertUpdate
import logging

class AlertService:
    def __init__(self, db: Session):
        self.db = db

    async def create_alert(self, alert_data: AlertCreate) -> Alert:
        """Create a new alert"""
        channels_as_strings = [
            c.value if hasattr(c, "value") else c
            for c in (alert_data.channels or [])
        ]
        alert = Alert(
            user_id=alert_data.user_id,
            type=alert_data.type,
            title=alert_data.title,
            message=alert_data.message,
            priority=alert_data.priority,
            vehicle_id=alert_data.vehicle_id,
            policy_id=alert_data.policy_id,
            booking_id=alert_data.booking_id,
            provider_id=alert_data.provider_id,
            channels=channels_as_strings,
            scheduled_at=alert_data.scheduled_at,
            action_url=alert_data.action_url,
            action_text=alert_data.action_text,
            alert_metadata=alert_data.alert_metadata
        )
        
        try:
            self.db.add(alert)
            self.db.commit()
            self.db.refresh(alert)
        except Exception as e:
            self.db.rollback()
            logging.getLogger(__name__).error(f"Failed to create alert: {e}")
            raise
        return alert

    def create_alert_sync(self, alert_data: AlertCreate) -> Alert:
        """Synchronous version: create a new alert (for use in threadpool)."""
        channels_as_strings = [
            c.value if hasattr(c, "value") else c
            for c in (alert_data.channels or [])
        ]
        alert = Alert(
            user_id=alert_data.user_id,
            type=alert_data.type,
            title=alert_data.title,
            message=alert_data.message,
            priority=alert_data.priority,
            vehicle_id=alert_data.vehicle_id,
            policy_id=alert_data.policy_id,
            booking_id=alert_data.booking_id,
            provider_id=alert_data.provider_id,
            channels=channels_as_strings,
            scheduled_at=alert_data.scheduled_at,
            action_url=alert_data.action_url,
            action_text=alert_data.action_text,
            alert_metadata=alert_data.alert_metadata
        )

        try:
            self.db.add(alert)
            self.db.commit()
            self.db.refresh(alert)
        except Exception as e:
            self.db.rollback()
            logging.getLogger(__name__).error(f"Failed to create alert: {e}")
            raise
        return alert

    async def get_alert(self, alert_id: str) -> Optional[Alert]:
        """Get a specific alert by ID"""
        return self.db.query(Alert).filter(Alert.id == alert_id).first()

    async def get_alerts(
        self,
        user_id: Optional[int] = None,
        alert_type: Optional[AlertType] = None,
        status: Optional[AlertStatus] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[Alert]:
        """Get alerts with optional filtering"""
        query = self.db.query(Alert)
        
        if user_id:
            query = query.filter(Alert.user_id == user_id)
        if alert_type:
            query = query.filter(Alert.type == alert_type)
        if status:
            query = query.filter(Alert.status == status)
            
        return query.order_by(desc(Alert.created_at)).offset(offset).limit(limit).all()

    async def update_alert(self, alert_id: str, alert_update: AlertUpdate) -> Optional[Alert]:
        """Update an alert"""
        alert = await self.get_alert(alert_id)
        if not alert:
            return None
            
        update_data = alert_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(alert, field, value)
            
        alert.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(alert)
        return alert

    async def delete_alert(self, alert_id: str) -> bool:
        """Delete an alert"""
        alert = await self.get_alert(alert_id)
        if not alert:
            return False
            
        self.db.delete(alert)
        self.db.commit()
        return True

    async def get_unread_count(self, user_id: int) -> int:
        """Get count of unread alerts for a user"""
        return self.db.query(Alert).filter(
            and_(
                Alert.user_id == user_id,
                Alert.status.in_([AlertStatus.PENDING, AlertStatus.SENT])
            )
        ).count()

    async def mark_alert_read(self, alert_id: str) -> bool:
        """Mark an alert as read (update status to delivered)"""
        alert = await self.get_alert(alert_id)
        if not alert:
            return False
            
        alert.status = AlertStatus.DELIVERED
        alert.delivered_at = datetime.utcnow()
        self.db.commit()
        return True

    async def get_pending_alerts(self, limit: int = 100) -> List[Alert]:
        """Get alerts that are pending delivery"""
        return self.db.query(Alert).filter(
            and_(
                Alert.status == AlertStatus.PENDING,
                or_(
                    Alert.scheduled_at.is_(None),
                    Alert.scheduled_at <= datetime.utcnow()
                )
            )
        ).limit(limit).all()

    async def update_alert_status(
        self, 
        alert_id: str, 
        status: AlertStatus, 
        error_message: Optional[str] = None
    ) -> bool:
        """Update alert status and delivery timestamps"""
        alert = await self.get_alert(alert_id)
        if not alert:
            return False
            
        alert.status = status
        if status == AlertStatus.SENT:
            alert.sent_at = datetime.utcnow()
        elif status == AlertStatus.DELIVERED:
            alert.delivered_at = datetime.utcnow()
        elif status == AlertStatus.FAILED:
            alert.error_message = error_message
            alert.retry_count += 1
            
        self.db.commit()
        return True
