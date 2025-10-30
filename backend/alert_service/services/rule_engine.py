# backend/alert_service/services/rule_engine.py
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from datetime import datetime, timedelta
import requests
import logging

from models.alert import Alert, AlertType, AlertChannel, AlertStatus
from schemas.alert import AlertCreate
from services.alert_service import AlertService
from celery_app import celery_app
from services.metrics import inc

logger = logging.getLogger(__name__)

class RuleEngine:
    def __init__(self, db: Session):
        self.db = db
        self.alert_service = AlertService(db)

    async def check_insurance_expiry(self):
        """Check for insurance policies expiring soon and create alerts"""
        try:
            import aiohttp
            # Get insurance policies expiring in next 30 days
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self._get_insurance_service_url()}/insurance/policies/expiring", timeout=10) as response:
                    if response.status != 200:
                        logger.error(f"Failed to fetch expiring policies: {response.status}")
                        return
                        
                    expiring_policies = await response.json()
                    
                    for policy in expiring_policies:
                        days_until_expiry = self._calculate_days_until_expiry(policy['expiry_date'])
                        
                        # Create alerts based on days until expiry
                        if days_until_expiry in [30, 7, 1]:
                            await self._create_insurance_expiry_alert(policy, days_until_expiry)
                            inc("alerts_created")
                    
        except Exception as e:
            logger.error(f"Error checking insurance expiry: {str(e)}")

    async def check_service_due(self):
        """Check for vehicles with service due and create alerts"""
        try:
            import aiohttp
            # Get service logs with next service due
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self._get_booking_service_url()}/service-logs/due", timeout=10) as response:
                    if response.status != 200:
                        logger.error(f"Failed to fetch service logs: {response.status}")
                        return
                        
                    due_services = await response.json()
                    
                    for service in due_services:
                        days_until_service = self._calculate_days_until_service(service)
                        
                        # Create alerts based on days until service
                        if days_until_service in [30, 14, 7, 1]:
                            await self._create_service_due_alert(service, days_until_service)
                            inc("alerts_created")
                    
        except Exception as e:
            logger.error(f"Error checking service due: {str(e)}")

    async def process_alert(self, alert_id: str):
        """Process a specific alert for delivery"""
        try:
            alert = await self.alert_service.get_alert(alert_id)
            if not alert:
                logger.error(f"Alert {alert_id} not found")
                return
                
            # Check if alert should be sent now
            if alert.scheduled_at and alert.scheduled_at > datetime.utcnow():
                logger.info(f"Alert {alert_id} scheduled for future delivery")
                return
                
            # Enqueue delivery via Celery worker
            celery_app.send_task("deliver_alert", args=[alert.id])
                
        except Exception as e:
            logger.error(f"Error processing alert {alert_id}: {str(e)}")
            db_alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
            if db_alert:
                db_alert.status = AlertStatus.FAILED
                db_alert.error_message = str(e)
                self.db.commit()

    async def _create_insurance_expiry_alert(self, policy: Dict[str, Any], days_until_expiry: int):
        """Create insurance expiry alert"""
        title = f"Insurance Expires in {days_until_expiry} day{'s' if days_until_expiry != 1 else ''}"
        
        if days_until_expiry == 1:
            message = f"⚠️ URGENT: Your insurance policy expires TOMORROW! Renew now to avoid penalties."
            priority = 4  # Urgent
        elif days_until_expiry == 7:
            message = f"Your insurance policy expires in 7 days. Don't forget to renew!"
            priority = 3  # High
        else:
            message = f"Your insurance policy expires in {days_until_expiry} days. Consider renewing soon."
            priority = 2  # Medium
            
        alert_data = AlertCreate(
            user_id=policy['owner_id'],
            type=AlertType.INSURANCE_EXPIRY,
            title=title,
            message=message,
            priority=priority,
            vehicle_id=policy['vehicle_id'],
            policy_id=policy['id'],
            channels=[AlertChannel.EMAIL, AlertChannel.IN_APP],
            action_url=f"/insurance/renew/{policy['id']}",
            action_text="Renew Now",
            alert_metadata={
                "policy_number": policy.get('policy_number'),
                "provider": policy.get('provider_name'),
                "expiry_date": policy['expiry_date'],
                "premium_amount": policy.get('premium_amount')
            }
        )
        # Use AlertService instead of direct CRUD
        alert = await self.alert_service.create_alert(alert_data)
        # Enqueue delivery; worker updates status
        celery_app.send_task("deliver_alert", args=[alert.id])
        inc("alerts_enqueued")

    async def _create_service_due_alert(self, service: Dict[str, Any], days_until_service: int):
        """Create service due alert"""
        title = f"Service Due in {days_until_service} day{'s' if days_until_service != 1 else ''}"
        
        if days_until_service == 1:
            message = f"🚗 Your vehicle service is due TODAY! Book now to keep your car running smoothly."
            priority = 3  # High
        elif days_until_service == 7:
            message = f"Your vehicle service is due in 7 days. Book your appointment now."
            priority = 2  # Medium
        else:
            message = f"Your vehicle service is due in {days_until_service} days. Plan ahead and book your appointment."
            priority = 2  # Medium
            
        alert_data = AlertCreate(
            user_id=service['user_id'],
            type=AlertType.SERVICE_DUE,
            title=title,
            message=message,
            priority=priority,
            vehicle_id=service['vehicle_id'],
            channels=[AlertChannel.EMAIL, AlertChannel.IN_APP],
            action_url=f"/bookings/create?vehicle_id={service['vehicle_id']}",
            action_text="Book Service",
            alert_metadata={
                "current_mileage": service.get('current_mileage'),
                "next_service_mileage": service.get('next_service_km'),
                "last_service_date": service.get('last_service_date'),
                "service_type": service.get('service_type', 'Regular Maintenance')
            }
        )
        # Use AlertService instead of direct CRUD
        alert = await self.alert_service.create_alert(alert_data)
        # Enqueue delivery; worker updates status
        celery_app.send_task("deliver_alert", args=[alert.id])
        inc("alerts_enqueued")

    def _calculate_days_until_expiry(self, expiry_date_str: str) -> int:
        """Calculate days until insurance expiry"""
        expiry_date = datetime.fromisoformat(expiry_date_str.replace('Z', '+00:00'))
        now = datetime.utcnow()
        delta = expiry_date - now
        return delta.days

    def _calculate_days_until_service(self, service: Dict[str, Any]) -> int:
        """Calculate days until next service"""
        next_service_date = service.get('next_service_date')
        if next_service_date:
            service_date = datetime.fromisoformat(next_service_date.replace('Z', '+00:00'))
            now = datetime.utcnow()
            delta = service_date - now
            return delta.days
        
        # Fallback to mileage-based calculation
        current_mileage = service.get('current_mileage', 0)
        next_service_mileage = service.get('next_service_km', 0)
        if next_service_mileage > current_mileage:
            remaining_km = next_service_mileage - current_mileage
            # Estimate days based on average daily driving (assume 50km/day)
            return max(1, remaining_km // 50)
        
        return 0

    def _get_insurance_service_url(self) -> str:
        """Get insurance service URL from config"""
        from core.config import settings
        return settings.INSURANCE_SERVICE_URL

    def _get_booking_service_url(self) -> str:
        """Get booking service URL from config"""
        from core.config import settings
        return settings.BOOKING_SERVICE_URL
