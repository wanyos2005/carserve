# backend/booking_service/app/schemas/booking.py
from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime
from uuid import UUID
from typing import Union

class BookingCreate(BaseModel):
    user_id: int
    vehicle_id: str
    provider_id: str
    service_id: Optional[str] = None
    scheduled_at: Optional[datetime] = None
    location: Optional[dict] = None
    meta: Optional[dict] = None
    # Pricing
    base_price: Optional[int] = None
    agreed_price: Optional[int] = None
    has_negotiated: Optional[bool] = None
    negotiation_notes: Optional[str] = None

class BookingUpdate(BaseModel):
    status: Optional[str] = None
    scheduled_at: Optional[datetime] = None
    location: Optional[dict] = None
    meta: Optional[dict] = None
    # Pricing updates
    base_price: Optional[int] = None
    agreed_price: Optional[int] = None
    has_negotiated: Optional[bool] = None
    negotiation_notes: Optional[str] = None
    # Expense flag (internal use)
    expense_recorded: Optional[bool] = None

class BookingOut(BookingCreate):
    id: str
    status: str
    created_at: Optional[datetime]
    completed_at: Optional[datetime]
    expense_recorded: Optional[bool] = False

    class Config:
        from_attributes = True

#service-logs:



class ServiceLogBase(BaseModel):
    user_id: int
    vehicle_id: Optional[str] = None
    provider_id: Optional[str] = None
    provider_name: Optional[str] = None
    provider_contact: Optional[dict] = None
    service_id: Optional[str] = None
    service_name: Optional[str] = None
    service_items: Optional[Dict[str, Any]] = None
    mileage_km: Optional[int] = None
    performed_at: Optional[datetime] = None
    next_service_km: Optional[int] = None
    next_service_date: Optional[datetime] = None
    served_by: Optional[str] = None
    served_by_contact: Optional[str] = None
    cost: Optional[int] = None
    logged_by: Optional[str] = "user"
    notes: Optional[str] = ""

class ServiceLogCreate(ServiceLogBase):
    pass

class ServiceLog(ServiceLogBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
