#backend/service_provider_service/app/schemas/provider.py
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

# -----------------------
# Services
# -----------------------

class RequirementField(BaseModel):
    name: str
    label: str
    type: str
    options: Optional[List[str]] = None

class Requirements(BaseModel):
    fields: List[RequirementField]

class ServiceBase(BaseModel):
    name: str
    description: Optional[str] = None
    category_id: Optional[int] = None
    requirements: Optional[Requirements] = None

class ServiceCreate(ServiceBase):
    pass

class ServiceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None

class Service(ServiceBase):
    id: str
    created_at: Optional[datetime]

    class Config:
        from_attributes = True

# -----------------------
# Providers
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

# For request payload (input)
class ProviderServiceCreate(BaseModel):
    service_id: str
    price: Optional[str] = None
    duration: Optional[str] = None
    booking_required: Optional[bool] = False
    extra_data: Optional[Dict[str, Any]] = None
    class Config:
        fields = {"extra_data": "metadata"}

# For response payload (output)        
class ProviderServiceAttach(BaseModel):
    service_id: str
    price: Optional[str] = None
    duration: Optional[str] = None
    booking_required: Optional[bool] = False
    extra_data: Optional[Dict[str, Any]] = {}

    class Config:
        orm_mode = True   # ✅ important
        from_attributes = True


class Provider(ProviderBase):
    id: str
    rating: Optional[float]
    created_at: Optional[datetime]
    category_id: int
    provider_services: Optional[List[ProviderServiceAttach]] = []

    class Config:
        orm_mode = True   # ✅ important
        from_attributes = True
