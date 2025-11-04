# backend/alert_service/models/alert.py
import uuid
from sqlalchemy import Column, String, Integer, TIMESTAMP, func, Boolean, JSON, ForeignKey, Text, Enum
from sqlalchemy.dialects.postgresql import UUID
from core.db import Base
import enum

class AlertType(str, enum.Enum):
    INSURANCE_EXPIRY = "insurance_expiry"
    SERVICE_DUE = "service_due"
    PROMOTIONAL = "promotional"
    MAINTENANCE_REMINDER = "maintenance_reminder"
    CLAIM_UPDATE = "claim_update"
    PAYMENT_REMINDER = "payment_reminder"
    APP_DOWNLOAD_PROMPT = "app_download_prompt"
    RATING_REQUEST = "rating_request"

class AlertStatus(str, enum.Enum):
    PENDING = "pending"
    SENT = "sent"
    DELIVERED = "delivered"
    FAILED = "failed"
    CANCELLED = "cancelled"

class AlertChannel(str, enum.Enum):
    IN_APP = "in_app" 
    PUSH = "push"
    SMS = "sms"
    EMAIL = "email"
    WHATSAPP = "whatsapp"

#this is the basic alert model
class Alert(Base):
    __tablename__ = "alerts"
    __table_args__ = {"schema": "alerts"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, index=True, nullable=False)
    
    # Alert details
    type = Column(Enum(AlertType), index=True, nullable=False)
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    priority = Column(Integer, default=1)  # 1=low, 2=medium, 3=high, 4=urgent
    
    # Related entities
    vehicle_id = Column(String, index=True, nullable=True)
    policy_id = Column(String, index=True, nullable=True)
    booking_id = Column(String, index=True, nullable=True)
    provider_id = Column(String, index=True, nullable=True)
    
    # Delivery details
    channels = Column(JSON, nullable=False)  # List of channels to send to
    status = Column(Enum(AlertStatus), default=AlertStatus.PENDING, index=True)
    
    # Scheduling
    scheduled_at = Column(TIMESTAMP(timezone=True), nullable=True)
    sent_at = Column(TIMESTAMP(timezone=True), nullable=True)
    delivered_at = Column(TIMESTAMP(timezone=True), nullable=True)
    
    # Action data
    action_url = Column(String, nullable=True)  # Deep link or web URL
    action_text = Column(String, nullable=True)  # Button text
    alert_metadata = Column(JSON, nullable=True)  # Additional data for the alert
    
    # Retry logic
    retry_count = Column(Integer, default=0)
    max_retries = Column(Integer, default=3)
    error_message = Column(Text, nullable=True)
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

#the difference between the alert and the alert rule is that the alert rule is a rule that triggers an alert, 
#while the alert is the actual alert that is sent to the user
class AlertRule(Base):
    __tablename__ = "alert_rules"
    __table_args__ = {"schema": "alerts"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    
    # Rule configuration
    alert_type = Column(Enum(AlertType), nullable=False)
    trigger_conditions = Column(JSON, nullable=False)  # Conditions that trigger the alert
    message_template = Column(Text, nullable=False)  # Template for alert message
    title_template = Column(String(255), nullable=False)  # Template for alert title
    
    # Delivery settings
    channels = Column(JSON, nullable=False)  # Default channels for this rule
    priority = Column(Integer, default=2)  # Default priority
    
    # Scheduling
    is_active = Column(Boolean, default=True)
    schedule_expression = Column(String, nullable=True)  # Cron-like expression
    
    # Rule metadata
    created_by = Column(String, nullable=True)  # User or system that created the rule
    version = Column(String, default="1.0")
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

#on the other hand, the alert preference is a preference that the user has for the alert
#this is so that the user can customize the alert to their liking
class AlertPreference(Base):
    __tablename__ = "alert_preferences"
    __table_args__ = {"schema": "alerts"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, index=True, nullable=False)
    
    # Preference settings
    alert_type = Column(Enum(AlertType), index=True, nullable=False)
    is_enabled = Column(Boolean, default=True)
    channels = Column(JSON, nullable=False)  # Preferred channels for this alert type
    frequency = Column(String, default="immediate")  # immediate, daily, weekly, never
    
    # Timing preferences
    quiet_hours_start = Column(String, nullable=True)  # e.g., "22:00"
    quiet_hours_end = Column(String, nullable=True)    # e.g., "08:00"
    timezone = Column(String, default="Africa/Nairobi")
    
    # Advanced preferences
    min_priority = Column(Integer, default=1)  # Only send alerts with this priority or higher
    batch_alerts = Column(Boolean, default=False)  # Batch similar alerts
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

#the notification log is a log of the notification that has been sent to the user
class NotificationLog(Base):
    __tablename__ = "notification_logs"
    __table_args__ = {"schema": "alerts"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    alert_id = Column(String, ForeignKey("alerts.alerts.id"), index=True)
    user_id = Column(Integer, index=True, nullable=False)
    
    # Delivery details
    channel = Column(Enum(AlertChannel), nullable=False)
    status = Column(Enum(AlertStatus), nullable=False)
    
    # External service details
    external_id = Column(String, nullable=True)  # ID from FCM, Twilio, etc.
    external_response = Column(JSON, nullable=True)  # Response from external service
    
    # Timing
    sent_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    delivered_at = Column(TIMESTAMP(timezone=True), nullable=True)
    
    # Error handling
    error_message = Column(Text, nullable=True)
    retry_count = Column(Integer, default=0)
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
