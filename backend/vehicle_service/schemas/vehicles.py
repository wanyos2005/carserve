#vehicle_service/schemas/vehicles.py
from pydantic import BaseModel
from typing import Optional

class VehicleBase(BaseModel):
    make: str
    model: str
    plate: str
    mileage: Optional[int] = 0
    yom: int  # Year of Manufacture
    fuel_type: str
    transmission: Optional[str] = None
    color: Optional[str] = None
    # 🔹 NEW: guest vehicle metadata
    guest_owner_name: Optional[str] = None
    guest_owner_email: Optional[str] = None
    guest_owner_phone: Optional[str] = None
    created_by_provider_id: Optional[str] = None
    owner_id: Optional[int] = None  # User ID of the owner

class VehicleCreate(VehicleBase):
    pass

class VehicleUpdate(BaseModel):
    make: Optional[str] = None
    model: Optional[str] = None
    plate: Optional[str] = None
    mileage: Optional[int] = None
    yom: Optional[int] = None  # Year of Manufacture
    fuel_type: Optional[str] = None
    transmission: Optional[str] = None
    color: Optional[str] = None


class VehicleRead(VehicleBase):
    id: str
    owner_id: int

    class Config:
        from_attributes = True  # replaces orm_mode in Pydantic v2
