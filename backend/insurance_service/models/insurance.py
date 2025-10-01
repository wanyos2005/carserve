# backend/insurance_service/models/insurance.py
import uuid
from sqlalchemy import Column, String, Integer, TIMESTAMP, func
from core.db import Base

class Insurance_Policy(Base):
    __tablename__ = "insurance_policies"
    __table_args__ = {"schema": "insurance"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id = Column(Integer, index=True)
    vehicle_id = Column(String, index=True)
    provider_id = Column(String, index=True)
    insurance_type = Column(String, index=True)
    commencement_date = Column(TIMESTAMP(timezone=True), nullable=True)
    expiry_date = Column(TIMESTAMP(timezone=True), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
