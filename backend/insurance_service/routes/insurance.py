#vehicle_service/routes/vehicles.py
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from core.db import get_db
from core.security import get_current_user_id
from models.insurance import Insurance_Policy
from schemas.insurance import InsurancePolicyCreate, InsurancePolicyRead, InsurancePolicyUpdate

router = APIRouter()

@router.post("/create-insurance-policy", response_model=InsurancePolicyCreate, status_code=status.HTTP_201_CREATED)
def create_insurance_policy(
    payload: InsurancePolicyCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id),
):
    
    # We need to check if the vehicle insurance has already been captured
    # existing = db.query(Vehicle).filter(Vehicle.plate == plate).first()
    # if existing:
    #     raise HTTPException(status_code=400, detail="Plate already registered")

    insurance_policy = Insurance_Policy(
    owner_id=user_id,
    vehicle_id=payload.vehicle_id,
    insurance_type=payload.insurance_type,
    insurer_id=payload.insurer_id or 0,
    commencement_date=payload.commencement_date,
    expiry_date=payload.expiry_date,
   
    )
    db.add(insurance_policy)
    db.commit()
    db.refresh(insurance_policy)
    return insurance_policy
