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
    display_name: Optional[str] = None
    price: Optional[str] = None
    duration: Optional[str] = None
    booking_required: Optional[bool] = False
    extra_data: Optional[Dict[str, Any]] = None
    class Config:
        fields = {"extra_data": "metadata"}

# For response payload (output)        
class ProviderServiceAttach(BaseModel):
    service_id: str
    display_name: Optional[str] = None
    price: Optional[str] = None
    duration: Optional[str] = None
    booking_required: Optional[bool] = False
    extra_data: Optional[Dict[str, Any]] = {}

    
    # 🔹 include nested service details
    service: Optional[Service] = None   

    class Config:
        orm_mode = True   # ✅ important
        from_attributes = True

class ProviderOut(BaseModel):
    id: str
    name: str
    location: Optional[str] = None
    services: List[ProviderServiceAttach] = []

    class Config:
        orm_mode = True


class Provider(ProviderBase):
    id: str
    rating: Optional[float]
    created_at: Optional[datetime]
    category_id: int
    provider_services: Optional[List[ProviderServiceAttach]] = []

    class Config:
        orm_mode = True   # ✅ important
        from_attributes = True
# -----------------------
# Templates for Providers
# -----------------------

# A single item inside a template (links template ↔ service)
class ServiceTemplateItemBase(BaseModel):
    service_id: str


class ServiceTemplateItemCreate(ServiceTemplateItemBase):
    pass


class ServiceTemplateItemRead(ServiceTemplateItemBase):
    id: str

    class Config:
        orm_mode = True
        from_attributes = True


# The template itself
class ServiceTemplateBase(BaseModel):
    name: str  # e.g., "Standard Oil Service"


class ServiceTemplateCreate(ServiceTemplateBase):
    provider_id: str
    items: List[ServiceTemplateItemCreate]  # ✅ use item objects instead of raw strings


class ServiceTemplateRead(ServiceTemplateBase):
    id: str
    provider_id: str
    items: List[ServiceTemplateItemRead] = []  # ✅ expanded list of items

    class Config:
        orm_mode = True
        from_attributes = True

