#backend/insurance_service/schemas/insurance.py
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class ExpenseBase(BaseModel):
    owner_id: int
    vehicle_id: str
    provider_id: Optional[str]
    expense_type: str
    location: Optional[str]
    cost:int
    

class ExpenseCreate(ExpenseBase):
    pass

class ExpenseRead(BaseModel):
    id: str
    owner_id: int
    vehicle_id: str
    provider_id: Optional[str]
    expense_type: str
    location: Optional[str]
    cost:int 
    created_at: datetime

    class Config:
        from_attributes = True

class ExpenseUpdate(BaseModel):
    expense_type: Optional[str] = None
    provider_id: Optional[str] = None
    location: Optional[str] = None
    cost: Optional[int] = None

