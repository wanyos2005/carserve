# backend/insurance_service/models/insurance.py
import uuid
from sqlalchemy import Column, String, Integer, TIMESTAMP, func
from core.db import Base

class Expense(Base):
    __tablename__ = "expenses"
    __table_args__ = {"schema": "expense"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id = Column(Integer, index=True)
    vehicle_id = Column(String, index=True)
    provider_id = Column(String, index=True)
    expense_type = Column(String, index=True)
    location = Column(String, index=True)
    cost = Column(Integer, index=True)    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
