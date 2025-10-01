# services/vehicle_service/models/vehicles.py
from sqlalchemy import Column, Integer, String, Text, JSON, Numeric, TIMESTAMP, func, ForeignKey, Boolean

import uuid
from sqlalchemy import Column, String, Integer
from sqlalchemy.dialects.postgresql import UUID

from core.db import Base

class Insurance_Policy(Base):
    __tablename__ = "insurance_policies"
    __table_args__ = {"schema": "insurance"}
    

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_id = Column(Integer, index=True)
    vehicle_id = Column(UUID(as_uuid=True), index=True)
    provider_id = Column(UUID(as_uuid=True), index=True)
    insurance_type = Column(String, index=True)
    commencement_date =  Column(TIMESTAMP(timezone=True), nullable=True)
    expiry_date = Column(TIMESTAMP(timezone=True), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    

    

