# backend/alert_service/schemas/alert.py
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime
from models.alert import AlertType, AlertStatus, AlertChannel, BroadcastAlertStatus, IncidentType, IncidentStatus

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

class AppDownloadPromptRequest(BaseModel):
    user_id: int
    vehicle_info: str
    service_provider_name: str
    service_type: str
    discount_code: str = "FIRST10"

class AppDownloadPromptResponse(BaseModel):
    message: str
    alert_id: Optional[str] = None
    user_id: int
    discount_code: str
    success: bool = True


# ─────────────────────────────────────────────────────────────────────────────
# Drivon Alerts – BroadcastAlert schemas
# ─────────────────────────────────────────────────────────────────────────────

class BroadcastAlertCreate(BaseModel):
    title: str
    message: str
    type: AlertType
    priority: int = 2
    channels: List[AlertChannel] = [AlertChannel.IN_APP, AlertChannel.PUSH]
    target_audience: str = "all"
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    radius_km: Optional[int] = None
    active_from: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    source: Optional[str] = None
    action_url: Optional[str] = None
    action_text: Optional[str] = None

class BroadcastAlertUpdate(BaseModel):
    title: Optional[str] = None
    message: Optional[str] = None
    priority: Optional[int] = None
    channels: Optional[List[AlertChannel]] = None
    target_audience: Optional[str] = None
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    radius_km: Optional[int] = None
    active_from: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    source: Optional[str] = None
    action_url: Optional[str] = None
    action_text: Optional[str] = None
    status: Optional[BroadcastAlertStatus] = None

class BroadcastAlertResponse(BaseModel):
    id: str
    title: str
    message: str
    type: AlertType
    priority: int
    channels: List[str]
    target_audience: str
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    radius_km: Optional[int] = None
    status: BroadcastAlertStatus
    active_from: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    created_by_admin: Optional[str] = None
    source: Optional[str] = None
    action_url: Optional[str] = None
    action_text: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────────────────────────────────────
# Drivon Alerts – IncidentReport schemas
# ─────────────────────────────────────────────────────────────────────────────

class IncidentReportCreate(BaseModel):
    user_id: int
    incident_type: IncidentType
    title: str
    description: str
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    location_text: Optional[str] = None
    media_urls: List[str] = []

class IncidentReportUpdate(BaseModel):
    status: Optional[IncidentStatus] = None
    admin_notes: Optional[str] = None

class IncidentReportResponse(BaseModel):
    id: str
    user_id: int
    incident_type: IncidentType
    title: str
    description: str
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    location_text: Optional[str] = None
    media_urls: List[str]
    status: IncidentStatus
    admin_notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
