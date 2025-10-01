#backend/insurance_service/schemas/insurance.py
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class InsurancePolicyBase(BaseModel):
    owner_id: int
    vehicle_id: str
    provider_id: str
    insurance_type: str
    commencement_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None

class InsurancePolicyCreate(InsurancePolicyBase):
    pass

class InsurancePolicyRead(BaseModel):
    id: str
    owner_id: int
    vehicle_id: str
    provider_id: str
    insurance_type: str
    commencement_date: Optional[datetime]
    expiry_date: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True

class InsurancePolicyUpdate(BaseModel):
    insurance_type: Optional[str] = None
    provider_id: Optional[str] = None
    commencement_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None

