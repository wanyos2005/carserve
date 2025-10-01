#vehicle_service/schemas/vehicles.py
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class InsurancePolicyBase(BaseModel):
    owner_id: str
    vehicle_id: str
    insurance_type: str
    insurer_id: str
    commencement_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None


class InsurancePolicyCreate(InsurancePolicyBase):
    pass

class InsurancePolicyUpdate(BaseModel):

    owner_id:  Optional[str] = None
    vehicle_id:  Optional[str] = None
    insurance_type:  Optional[str] = None
    insurer_id:  Optional[str] = None
    commencement_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None


class InsurancePolicyRead(InsurancePolicyBase):
    id: str
    owner_id: str
    vehicle_id: str

    class Config:
        from_attributes = True  # replaces orm_mode in Pydantic v2
