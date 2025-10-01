# insurance_service/routes/insurance.py

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from core.db import get_db
from models.insurance import Insurance_Policy
from schemas.insurance import InsurancePolicyCreate, InsurancePolicyRead, InsurancePolicyUpdate

router = APIRouter()

@router.post("/create-insurance-policy", response_model=InsurancePolicyRead, status_code=status.HTTP_201_CREATED)
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

#GET all insurance policies
@router.get("/get-insurance-policies", response_model=list[InsurancePolicyRead], status_code=status.HTTP_200_OK)
def get_insurance_policies(
    db: Session = Depends(get_db),
):
    insurance_policies = db.query(Insurance_Policy).all()
    return insurance_policies

#GET insurance policy by owner ID
@router.get("/get-insurance-policy-by-owner/{owner_id}", response_model=list[InsurancePolicyRead], status_code=status.HTTP_200_OK)
def get_insurance_policy_by_owner(
    owner_id: int,
    db: Session = Depends(get_db),
):
    insurance_policies = db.query(Insurance_Policy).filter(Insurance_Policy.owner_id == owner_id).all()
    return insurance_policies

