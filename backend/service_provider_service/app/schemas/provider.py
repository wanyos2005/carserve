#backend/service_provider_service/app/schemas/provider.py

from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID

# -----------------------
# Service Schemas
# -----------------------
class ServiceBase(BaseModel):
    name: str
    description: Optional[str] = None
    category_id: Optional[int] = None   # integer foreign key


class RequirementField(BaseModel):
    name: str
    type: str  # "string", "number", "boolean", "textarea", "select"
    label: Optional[str] = None
    options: Optional[List[str]] = None  # only for select
class Requirements(BaseModel):
    fields: List[RequirementField]
class ServiceCreate(ServiceBase):
    requirements: Optional[Requirements] = None
class ServiceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None
    requirements: Optional[Requirements] = None
    

class Service(ServiceBase):
    id: UUID
    created_at: Optional[datetime]
    requirements: Optional[Requirements] = None

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


class ProviderUpdate(BaseModel):
    name: Optional[str] = None
    category_id: Optional[int] = None
    description: Optional[str] = None
    contact_info: Optional[Dict] = None
    location: Optional[Dict] = None
    is_registered: Optional[bool] = None


class ProviderServiceBase(BaseModel):
    provider_id: UUID
    service_id: UUID
    price: Optional[str] = None
    duration: Optional[str] = None
    booking_required: Optional[bool] = False
    insurance: Optional[Dict] = None  # store provider-specific insurance details

class ProviderServiceAttach(BaseModel):
    service_id: UUID
    price: Optional[str] = None
    duration: Optional[str] = None
    booking_required: Optional[bool] = False
    extra_data: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None  # alias, deprecated

    class Config:
        fields = {
            "extra_data": "metadata"  # allow "metadata" in JSON
        }

class Provider(ProviderBase):
    id: UUID
    rating: Optional[float]
    created_at: Optional[datetime]
    category_id: int
    services: Optional[List[ProviderServiceAttach]] = []

    class Config:
        from_attributes = True
