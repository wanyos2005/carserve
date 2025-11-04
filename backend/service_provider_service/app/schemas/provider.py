#backend/service_provider_service/app/schemas/provider.py
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from app.schemas.category import ProviderCategory

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

class ProviderQuickCreate(BaseModel):
    name: str

class ProviderQuickOut(BaseModel):
    id: str
    name: str
    is_registered: bool

    class Config:
        from_attributes = True

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
    
    # Legacy price field (kept for backward compatibility)
    price: Optional[str] = None
    
    # New structured pricing fields
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    price_type: Optional[str] = "range"  # fixed, range, per_unit, free, variable
    currency: Optional[str] = "KES"
    unit: Optional[str] = None  # per_liter, per_hour, etc.
    negotiable: Optional[bool] = True
    
    duration: Optional[str] = None
    booking_required: Optional[bool] = False

    # ✅ Accept "metadata" from the frontend, store as extra_data internally
    extra_data: Dict[str, Any] = Field(default_factory=dict, alias="metadata")

    class Config:
        from_attributes = True
        populate_by_name = True  # allow both extra_data and metadata input names



# For response payload (output)        
class ProviderServiceAttach(BaseModel):
    service_id: str
    display_name: Optional[str] = None
    
    # Legacy price field (kept for backward compatibility and display)
    price: Optional[str] = None
    
    # New structured pricing fields
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    price_type: Optional[str] = None
    currency: Optional[str] = None
    unit: Optional[str] = None
    negotiable: Optional[bool] = None
    
    duration: Optional[str] = None
    booking_required: Optional[bool] = False

    # ✅ Show "metadata" in GET responses (instead of extra_data)
    metadata: Dict[str, Any] = Field(default_factory=dict, alias="extra_data")

    service: Optional[Service] = None

    class Config:
        from_attributes = True
        populate_by_name = True

class ProviderOut(BaseModel):
    id: str
    name: str
    location: Optional[str] = None
    services: List[ProviderServiceAttach] = []

    class Config:
        from_attributes = True


class Provider(ProviderBase):
    id: str
    rating: Optional[float]
    created_at: Optional[datetime]
    category_id: int
    category: Optional[ProviderCategory] = None
    provider_services: Optional[List[ProviderServiceAttach]] = []

    class Config:
        from_attributes = True   # ✅ important
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
        from_attributes = True
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
        from_attributes = True
        from_attributes = True


# -----------------------
# Provider Ratings
# -----------------------
class ProviderRatingCreate(BaseModel):
    rating: int  # 1-5
    comment: Optional[str] = None
    user_id: int
    booking_id: Optional[str] = None
    log_id: Optional[str] = None  # Service log ID this rating is for

class ProviderRatingOut(BaseModel):
    id: str
    provider_id: str
    user_id: int
    booking_id: Optional[str] = None
    log_id: Optional[str] = None
    rating: int
    comment: Optional[str] = None
    created_at: datetime | None = None
    updated_at: datetime | None = None

    class Config:
        from_attributes = True

