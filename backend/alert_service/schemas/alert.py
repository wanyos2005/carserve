# backend/alert_service/schemas/alert.py
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime
from models.alert import AlertType, AlertStatus, AlertChannel

class AlertCreate(BaseModel):
    user_id: int
    type: AlertType
    title: str
    message: str
    priority: int = 2
    vehicle_id: Optional[str] = None
    policy_id: Optional[str] = None
    booking_id: Optional[str] = None
    provider_id: Optional[str] = None
    channels: List[AlertChannel] = [AlertChannel.IN_APP]
    scheduled_at: Optional[datetime] = None
    action_url: Optional[str] = None
    action_text: Optional[str] = None
    alert_metadata: Optional[Dict[str, Any]] = None

class AlertUpdate(BaseModel):
    title: Optional[str] = None
    message: Optional[str] = None
    priority: Optional[int] = None
    channels: Optional[List[AlertChannel]] = None
    scheduled_at: Optional[datetime] = None
    action_url: Optional[str] = None
    action_text: Optional[str] = None
    alert_metadata: Optional[Dict[str, Any]] = None

class AlertResponse(BaseModel):
    id: str
    user_id: int
    type: AlertType
    title: str
    message: str
    priority: int
    vehicle_id: Optional[str] = None
    policy_id: Optional[str] = None
    booking_id: Optional[str] = None
    provider_id: Optional[str] = None
    # Stored as JSON list of strings in DB; expose as strings to avoid enum coercion issues
    channels: List[str]
    status: AlertStatus
    scheduled_at: Optional[datetime] = None
    sent_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    action_url: Optional[str] = None
    action_text: Optional[str] = None
    alert_metadata: Optional[Dict[str, Any]] = None
    retry_count: int
    error_message: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class AlertPreferenceCreate(BaseModel):
    user_id: int
    alert_type: AlertType
    is_enabled: bool = True
    channels: List[AlertChannel] = [AlertChannel.IN_APP]
    frequency: str = "immediate"
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    timezone: str = "Africa/Nairobi"
    min_priority: int = 1
    batch_alerts: bool = False

class AlertPreferenceResponse(BaseModel):
    id: str
    user_id: int
    alert_type: AlertType
    is_enabled: bool
    channels: List[AlertChannel]
    frequency: str
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    timezone: str
    min_priority: int
    batch_alerts: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class AlertRuleCreate(BaseModel):
    name: str
    description: Optional[str] = None
    alert_type: AlertType
    trigger_conditions: Dict[str, Any]
    message_template: str
    title_template: str
    channels: List[AlertChannel] = [AlertChannel.IN_APP]
    priority: int = 2
    is_active: bool = True
    schedule_expression: Optional[str] = None
    created_by: Optional[str] = None

class AlertRuleResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    alert_type: AlertType
    trigger_conditions: Dict[str, Any]
    message_template: str
    title_template: str
    channels: List[AlertChannel]
    priority: int
    is_active: bool
    schedule_expression: Optional[str] = None
    created_by: Optional[str] = None
    version: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
