# vehicle_service/routes/vehicles.py

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from core.db import get_db
from models.insurance import Insurance_Policy
from schemas.insurance import InsurancePolicyCreate

router = APIRouter()

@router.post("/create-insurance-policy", response_model=InsurancePolicyCreate, status_code=status.HTTP_201_CREATED)
def create_insurance_policy(
    payload: InsurancePolicyCreate,
    db: Session = Depends(get_db),
):
    
    insurance_policy = Insurance_Policy(
        owner_id=payload.owner_id,
        vehicle_id=payload.vehicle_id,
        insurance_type=payload.insurance_type,
        provider_id=payload.provider_id, 
        commencement_date=payload.commencement_date,
        expiry_date=payload.expiry_date,
    )
    db.add(insurance_policy)
    db.commit()
    db.refresh(insurance_policy)
    return insurance_policy
