from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from uuid import UUID

class InsurancePolicyBase(BaseModel):
    owner_id: int
    vehicle_id: UUID
    provider_id: UUID
    insurance_type: str
    commencement_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None

class InsurancePolicyCreate(InsurancePolicyBase):
    pass

class InsurancePolicyRead(InsurancePolicyBase):
    id: str
    owner_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class InsurancePolicyUpdate(BaseModel):    
    insurance_type: Optional[str] = None
    provider_id: Optional[str] = None
    commencement_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None
