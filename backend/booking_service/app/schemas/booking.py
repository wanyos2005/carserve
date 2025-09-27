# backend/booking_service/app/schemas/booking.py
from pydantic import BaseModel
from typing import Optional, Dict
from datetime import datetime
from uuid import UUID
from typing import Union

class BookingCreate(BaseModel):
    user_id: int
    vehicle_id: UUID
    provider_id: UUID
    service_id: Optional[UUID] = None
    scheduled_at: Optional[datetime] = None
    location: Optional[dict] = None
    meta: Optional[dict] = None

class BookingUpdate(BaseModel):
    status: Optional[str] = None
    scheduled_at: Optional[datetime] = None
    location: Optional[dict] = None
    meta: Optional[dict] = None

class BookingOut(BookingCreate):
    id: UUID   # 🔄 fix: should be UUID, not int
    status: str
    created_at: Optional[datetime]

    class Config:
        from_attributes = True

#service-logs:



class ServiceLogBase(BaseModel):
    user_id: int
    vehicle_id: Optional[UUID] = None
    provider_id: Optional[UUID] = None
    service_id: Optional[UUID] = None
    provider_name: Optional[str] = None
    provider_contact: Optional[Dict] = None
    service_name: Optional[str] = None
    service_details: Optional[Dict] = None
    performed_at: Optional[datetime] = None


class ServiceLogCreate(ServiceLogBase):
    pass


class ServiceLog(ServiceLogBase):
    id: UUID
    created_at: datetime

    class Config:
        from_attributes = True
