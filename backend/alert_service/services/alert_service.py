# backend/alert_service/services/alert_service.py
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc
from typing import List, Optional
from datetime import datetime

from models.alert import Alert, AlertType, AlertStatus, AlertChannel
from schemas.alert import AlertCreate, AlertUpdate, AlertResponse
import logging

class AlertService:
    def __init__(self, db: Session):
        self.db = db

    def _to_response(self, alert: Alert) -> AlertResponse:
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
            channels=[c.value if hasattr(c, "value") else c for c in (alert.channels or [])],
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

    async def create_alert(self, alert_data: AlertCreate) -> AlertResponse:
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
        return self._to_response(alert)

    def create_alert_sync(self, alert_data: AlertCreate) -> AlertResponse:
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
        return self._to_response(alert)

    async def get_alert(self, alert_id: str) -> Optional[AlertResponse]:
        """Get a specific alert by ID"""
        alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
        return self._to_response(alert) if alert else None

    async def get_alerts(
        self,
        user_id: Optional[int] = None,
        alert_type: Optional[AlertType] = None,
        status: Optional[AlertStatus] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[AlertResponse]:
        """Get alerts with optional filtering"""
        query = self.db.query(Alert)
        
        if user_id:
            query = query.filter(Alert.user_id == user_id)
        if alert_type:
            query = query.filter(Alert.type == alert_type)
        if status:
            query = query.filter(Alert.status == status)
            
        alerts = query.order_by(desc(Alert.created_at)).offset(offset).limit(limit).all()
        return [self._to_response(a) for a in alerts]

    async def update_alert(self, alert_id: str, alert_update: AlertUpdate) -> Optional[AlertResponse]:
        """Update an alert"""
        alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
        if not alert:
            return None
            
        update_data = alert_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(alert, field, value)
            
        alert.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(alert)
        return self._to_response(alert)

    async def delete_alert(self, alert_id: str) -> bool:
        """Delete an alert"""
        alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
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
        alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
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

    async def trigger_app_download_prompt(
        self, 
        user_id: int, 
        vehicle_info: str, 
        service_provider_name: str,
        service_type: str,
        discount_code: str = "FIRST10"
    ) -> Optional[AlertResponse]:
        """Trigger app download prompt when a service is logged for a user without the app"""
        try:
            
            
            # Check if user already has the app using AppDetectionService
            from services.app_detection_service import AppDetectionService
            detection_service = AppDetectionService(self.db)
            
            # Use comprehensive evaluation to determine if user has app
            should_send_prompt = await detection_service.should_send_app_prompt(user_id)
            
            # For testing enhanced vehicle/provider names - bypass detection temporarily
            # TODO: Remove this in production
            #should_send_prompt = True
            
            if not should_send_prompt:
                return None
            
            # Enhance vehicle and provider information by querying other services
            enhanced_vehicle_info = await self._get_enhanced_vehicle_info(vehicle_info)
            enhanced_provider_name = await self._get_enhanced_provider_name(service_provider_name)
            
            # Create the app download prompt alert
            alert_data = AlertCreate(
                user_id=user_id,
                type=AlertType.APP_DOWNLOAD_PROMPT,
                title=f"📱 Download Our App - Get 10% Off!",
                message=f"🎉 Great news! {enhanced_provider_name} has logged a {service_type} service for your vehicle {enhanced_vehicle_info}. Download our app to track your service history, get maintenance reminders, and access exclusive offers. Use code '{discount_code}' for 10% off your next service!",
                priority=2,
                channels=[AlertChannel.SMS, AlertChannel.EMAIL, AlertChannel.WHATSAPP],
                action_url="https://play.google.com/store/apps/details?id=com.yourcompany.carapp",
                action_text="Download App",
                alert_metadata={
                    "service_provider": enhanced_provider_name,
                    "service_type": service_type,
                    "vehicle_info": enhanced_vehicle_info,
                    "discount_code": discount_code,
                    "app_store_links": {
                        "android": "https://play.google.com/store/apps/details?id=com.yourcompany.carapp",
                        "ios": "https://apps.apple.com/app/your-car-app/id123456789"
                    }
                }
            )
            
            alert = await self.create_alert(alert_data)
            return alert
            
        except Exception as e:
            logging.getLogger(__name__).error(f"Failed to trigger app download prompt: {e}", exc_info=True)
            return None

    async def trigger_rating_request(
        self,
        user_id: int,
        provider_id: str,
        booking_id: Optional[str] = None,
        log_id: Optional[str] = None,
        title: str = "Rate your service provider",
        message: str = "How was your recent service? Please rate your provider.",
        channels: Optional[list] = None,
    ) -> AlertResponse:
        try:
            channels = channels or [AlertChannel.IN_APP, AlertChannel.PUSH]
            action_url = None
            if booking_id:
                action_url = f"/rate?provider_id={provider_id}&booking_id={booking_id}"
            elif log_id:
                action_url = f"/rate?provider_id={provider_id}&log_id={log_id}"
            else:
                action_url = f"/rate?provider_id={provider_id}"

            alert_data = AlertCreate(
                user_id=user_id,
                type=AlertType.RATING_REQUEST,
                title=title,
                message=message,
                priority=2,
                channels=channels,
                booking_id=booking_id,
                provider_id=provider_id,
                action_url=action_url,
                action_text="Rate now",
                alert_metadata={
                    "booking_id": booking_id,
                    "log_id": log_id,
                },
            )
            alert = await self.create_alert(alert_data)
            return alert
        except Exception as e:
            logging.getLogger(__name__).error(f"Failed to trigger rating request: {e}", exc_info=True)
            raise

    async def _get_enhanced_vehicle_info(self, vehicle_id: str) -> str:
        """Query vehicle service to get proper vehicle name (plate, model, make, yom)"""
        try:
            import httpx
            vehicle_service_url = "http://vehicle-service:8002"
            
            # Use the public endpoint that doesn't require authentication
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{vehicle_service_url}/vehicles/public/{vehicle_id}")
                if response.status_code == 200:
                    vehicle_data = response.json()
                    # Extract vehicle details
                    plate = vehicle_data.get('plate', 'Unknown Plate')
                    model = vehicle_data.get('model', 'Unknown Model')
                    make = vehicle_data.get('make', 'Unknown Make')
                    yom = vehicle_data.get('yom', 'Unknown Year')
                    
                    return f"{plate} ({make} {model} {yom})"
                else:
                    logging.getLogger(__name__).warning(f"Vehicle service returned {response.status_code} for vehicle {vehicle_id}")
                    return f"Vehicle {vehicle_id}"
        except Exception as e:
            logging.getLogger(__name__).error(f"Failed to get vehicle info for {vehicle_id}: {e}")
            return f"Vehicle {vehicle_id}"

    async def _get_enhanced_provider_name(self, provider_name: str) -> str:
        """Query service provider service to get proper provider name"""
        try:
            import httpx
            service_provider_url = "http://service-provider:8003"
            
            logging.getLogger(__name__).info(f"Getting enhanced provider name for: {provider_name}")
            
            # If provider_name is already a proper name (not an ID), return it
            # Check if it's a UUID (36 characters with dashes) or starts with "provider_"
            is_uuid = provider_name and len(provider_name) == 36 and provider_name.count('-') == 4
            is_provider_id = provider_name and provider_name.startswith("provider_")
            
            if provider_name and provider_name != "Service Provider" and provider_name != "Unknown Provider" and not is_uuid and not is_provider_id:
                logging.getLogger(__name__).info(f"Provider name is already proper: {provider_name}")
                return provider_name
            
            # If it's a provider ID, query the service provider service
            if provider_name and (provider_name.startswith("provider_") or len(provider_name) == 36):  # UUID format
                logging.getLogger(__name__).info(f"Provider name is UUID format, querying service: {provider_name}")
                provider_id = provider_name
                async with httpx.AsyncClient(timeout=5.0) as client:
                    response = await client.get(f"{service_provider_url}/{provider_id}")
                    logging.getLogger(__name__).info(f"Provider service response: {response.status_code}")
                    if response.status_code == 200:
                        provider_data = response.json()
                        enhanced_name = provider_data.get('name', 'Service Provider')
                        logging.getLogger(__name__).info(f"Enhanced provider name: {enhanced_name}")
                        return enhanced_name
                    else:
                        logging.getLogger(__name__).warning(f"Service provider service returned {response.status_code} for provider {provider_id}")
                        return "Service Provider"
            
            # Fallback
            logging.getLogger(__name__).info(f"Using fallback provider name: {provider_name}")
            return provider_name or "Service Provider"
        except Exception as e:
            logging.getLogger(__name__).error(f"Failed to get provider info for {provider_name}: {e}")
            return provider_name or "Service Provider"
"""a laymans explanation of all that this file does, does it handle crud? does it relate with @notifications_service.py?
Answer:

this file handles the creation, retrieval, and management of alerts. it does not handle crud operations, but it does relate with @notifications_service.py.
it is responsible for creating, retrieving, and managing alerts. it is also responsible for sending alerts to the users.
it is responsible for sending alerts to the users via the channels specified in the alert.
it is responsible for sending alerts to the users via the channels specified in the alert."""