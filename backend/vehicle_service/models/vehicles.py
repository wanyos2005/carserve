# services/vehicle_service/models/vehicles.py

import uuid
from sqlalchemy import Column, String, Integer
from core.db import Base

class Vehicle(Base):
    __tablename__ = "vehicles"
    __table_args__ = {"schema": "vehicles"}
    

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id = Column(String, index=True)
    make = Column(String, index=True)
    model = Column(String, index=True)
    plate = Column(String, unique=True, index=True)
    mileage = Column(Integer, default=0)
    yom = Column(Integer, index=True)  # Year of Manufacture
    
    fuel_type = Column(String, index=True)
    transmission = Column(String, index=True, nullable=True)
    color = Column(String, index=True,  nullable=True)

    

