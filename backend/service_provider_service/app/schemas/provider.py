#backend/service_provider_service/app/schemas/provider.py

from pydantic import BaseModel
from typing import Optional, List, Dict
from datetime import datetime
from uuid import UUID

# -----------------------
# Service Schemas
# -----------------------
class ServiceBase(BaseModel):
    name: str
    description: Optional[str] = None
    price_range: Optional[str] = None
    category_id: Optional[int] = None   # integer foreign key


class ServiceCreate(ServiceBase):
    requirements: Optional[Dict] = None


class ServiceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price_range: Optional[str] = None
    category_id: Optional[int] = None
    requirements: Optional[Dict] = None


class Service(ServiceBase):
    id: UUID
    created_at: Optional[datetime]

    class Config:
        from_attributes = True


# -----------------------
# Provider Schemas
# -----------------------
class ProviderBase(BaseModel):
    name: str
    description: Optional[str] = None
    contact_info: Optional[Dict] = None
    location: Optional[Dict] = None
    is_registered: Optional[bool] = False


class ProviderCreate(ProviderBase):
    category_id: int
    services: Optional[List[ServiceCreate]] = []


class ProviderUpdate(BaseModel):
    name: Optional[str] = None
    category_id: Optional[int] = None
    description: Optional[str] = None
    contact_info: Optional[Dict] = None
    location: Optional[Dict] = None
    is_registered: Optional[bool] = None


class Provider(ProviderBase):
    id: UUID
    rating: Optional[float]
    created_at: Optional[datetime]
    category_id: int
    services: List[Service] = []

    class Config:
        from_attributes = True
