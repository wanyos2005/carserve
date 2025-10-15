# insurance_service/routes/insurance.py

from fastapi import APIRouter, Depends, status, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime, timedelta
import uuid

from core.db import get_db
from models.insurance import Insurance_Policy, Insurance_Partner
from schemas.insurance import (
    InsurancePolicyCreate, 
    InsurancePolicyRead, 
    InsurancePolicyUpdate,
    InsurancePartnerCreate,
    InsurancePartnerRead,
    InsurancePartnerUpdate,
    InsuranceQuoteRequest,
    InsuranceQuoteResponse,
    InsuranceQuote
)

router = APIRouter()

# Enhanced Policy Management
@router.post("/policies", response_model=InsurancePolicyRead, status_code=status.HTTP_201_CREATED)
def create_insurance_policy(
    payload: InsurancePolicyCreate,
    db: Session = Depends(get_db),
):
    """Create a new insurance policy with enhanced features"""
    
    # Generate policy number if not provided
    if not payload.policy_number:
        policy_number = f"POL-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
    else:
        policy_number = payload.policy_number
    
    insurance_policy = Insurance_Policy(
        owner_id=payload.owner_id,
        vehicle_id=payload.vehicle_id,
        insurance_type=payload.insurance_type,
        provider_id=payload.provider_id,
        commencement_date=payload.commencement_date,
        expiry_date=payload.expiry_date,
        premium_amount=payload.premium_amount,
        coverage_details=payload.coverage_details,
        deductible_amount=payload.deductible_amount,
        policy_number=policy_number,
        status="active"
    )
    
    db.add(insurance_policy)
    db.commit()
    db.refresh(insurance_policy)
    return insurance_policy

@router.get("/policies", response_model=List[InsurancePolicyRead])
def get_insurance_policies(
    owner_id: Optional[int] = None,
    user_id: Optional[int] = Query(None, description="Alias for owner_id for backward compatibility"),
    vehicle_id: Optional[str] = None,
    provider_id: Optional[str] = None,
    partner_id: Optional[str] = Query(None, description="Alias for provider_id for backward compatibility"),
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """Get insurance policies with filtering options"""
    
    query = db.query(Insurance_Policy)
    
    # Support both owner_id and legacy user_id
    owner_filter = owner_id or user_id
    if owner_filter:
        query = query.filter(Insurance_Policy.owner_id == owner_filter)
    if vehicle_id:
        query = query.filter(Insurance_Policy.vehicle_id == vehicle_id)
    # Support both provider_id and legacy partner_id
    provider_filter = provider_id or partner_id
    if provider_filter:
        query = query.filter(Insurance_Policy.provider_id == provider_filter)
    if status:
        query = query.filter(Insurance_Policy.status == status)
    
    policies = query.offset(skip).limit(limit).all()
    # Coalesce nullable fields to satisfy response schema
    for p in policies:
        if getattr(p, "status", None) is None:
            setattr(p, "status", "active")
        if getattr(p, "renewal_reminder_sent", None) is None:
            setattr(p, "renewal_reminder_sent", False)
    return policies

@router.get("/policies/{policy_id}", response_model=InsurancePolicyRead)
def get_insurance_policy(
    policy_id: str,
    db: Session = Depends(get_db),
):
    """Get a specific insurance policy by ID"""
    
    policy = db.query(Insurance_Policy).filter(Insurance_Policy.id == policy_id).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Insurance policy not found")
    
    # Coalesce nullable fields to satisfy response schema
    if getattr(policy, "status", None) is None:
        setattr(policy, "status", "active")
    if getattr(policy, "renewal_reminder_sent", None) is None:
        setattr(policy, "renewal_reminder_sent", False)
    return policy

@router.put("/policies/{policy_id}", response_model=InsurancePolicyRead)
def update_insurance_policy(
    policy_id: str,
    payload: InsurancePolicyUpdate,
    db: Session = Depends(get_db),
):
    """Update an insurance policy"""
    
    policy = db.query(Insurance_Policy).filter(Insurance_Policy.id == policy_id).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Insurance policy not found")
    
    # Update fields
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(policy, field, value)
    
    db.commit()
    db.refresh(policy)
    return policy

@router.delete("/policies/{policy_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_insurance_policy(
    policy_id: str,
    db: Session = Depends(get_db),
):
    """Delete an insurance policy"""
    
    policy = db.query(Insurance_Policy).filter(Insurance_Policy.id == policy_id).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Insurance policy not found")
    
    db.delete(policy)
    db.commit()
    return None

# Policy Renewal Management
@router.get("/policies/expiring", response_model=List[InsurancePolicyRead])
def get_expiring_policies(
    days_ahead: int = 30,
    db: Session = Depends(get_db),
):
    """Get policies expiring within specified days"""
    
    expiry_threshold = datetime.now() + timedelta(days=days_ahead)
    
    policies = db.query(Insurance_Policy).filter(
        Insurance_Policy.expiry_date <= expiry_threshold,
        Insurance_Policy.status == "active"
    ).all()
    
    return policies

@router.post("/policies/{policy_id}/renew")
def renew_insurance_policy(
    policy_id: str,
    new_expiry_date: datetime,
    new_premium_amount: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """Renew an insurance policy"""
    
    policy = db.query(Insurance_Policy).filter(Insurance_Policy.id == policy_id).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Insurance policy not found")
    
    if policy.status != "active":
        raise HTTPException(status_code=400, detail="Only active policies can be renewed")
    
    # Update policy with new expiry date and premium
    policy.expiry_date = new_expiry_date
    if new_premium_amount:
        policy.premium_amount = new_premium_amount
    policy.renewal_reminder_sent = False  # Reset reminder flag
    
    db.commit()
    db.refresh(policy)
    
    return {
        "message": "Policy renewed successfully",
        "policy_id": policy.id,
        "new_expiry_date": new_expiry_date,
        "new_premium_amount": policy.premium_amount
    }

@router.post("/policies/{policy_id}/cancel")
def cancel_insurance_policy(
    policy_id: str,
    cancellation_reason: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """Cancel an insurance policy"""
    
    policy = db.query(Insurance_Policy).filter(Insurance_Policy.id == policy_id).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Insurance policy not found")
    
    if policy.status not in ["active", "suspended"]:
        raise HTTPException(status_code=400, detail="Policy cannot be cancelled in current status")
    
    policy.status = "cancelled"
    # Store cancellation reason in coverage_details if needed
    if cancellation_reason:
        coverage_details = policy.coverage_details or {}
        coverage_details["cancellation_reason"] = cancellation_reason
        policy.coverage_details = coverage_details
    
    db.commit()
    
    return {
        "message": "Policy cancelled successfully",
        "policy_id": policy.id,
        "cancellation_reason": cancellation_reason
    }

# Insurance Partner Management
@router.post("/partners", response_model=InsurancePartnerRead, status_code=status.HTTP_201_CREATED)
def create_insurance_partner(
    payload: InsurancePartnerCreate,
    db: Session = Depends(get_db),
):
    """Create a new insurance partner with enhanced information"""
    
    # Check if partner code already exists
    existing_partner = db.query(Insurance_Partner).filter(
        Insurance_Partner.code == payload.code
    ).first()
    
    if existing_partner:
        raise HTTPException(status_code=400, detail="Partner code already exists")
    
    # Convert customer_rating from float to int (multiply by 10 for storage)
    partner_data = payload.dict()
    if partner_data.get('customer_rating') is not None:
        partner_data['customer_rating'] = int(partner_data['customer_rating'] * 10)
    
    partner = Insurance_Partner(**partner_data)
    db.add(partner)
    db.commit()
    db.refresh(partner)
    return partner

@router.get("/partners", response_model=List[InsurancePartnerRead])
def get_insurance_partners(
    active_only: bool = True,
    db: Session = Depends(get_db),
):
    """Get insurance partners with enhanced information"""
    
    query = db.query(Insurance_Partner)
    
    if active_only:
        query = query.filter(Insurance_Partner.is_active == True)
    
    partners = query.all()
    
    # Convert customer_rating from int to float for response
    for partner in partners:
        if partner.customer_rating is not None:
            partner.customer_rating = partner.customer_rating / 10.0
    
    return partners

@router.get("/partners/{partner_id}", response_model=InsurancePartnerRead)
def get_insurance_partner(
    partner_id: str,
    db: Session = Depends(get_db),
):
    """Get a specific insurance partner with enhanced information"""
    
    partner = db.query(Insurance_Partner).filter(Insurance_Partner.id == partner_id).first()
    if not partner:
        raise HTTPException(status_code=404, detail="Insurance partner not found")
    
    # Convert customer_rating from int to float for response
    if partner.customer_rating is not None:
        partner.customer_rating = partner.customer_rating / 10.0
    
    return partner

@router.put("/partners/{partner_id}", response_model=InsurancePartnerRead)
def update_insurance_partner(
    partner_id: str,
    payload: InsurancePartnerUpdate,
    db: Session = Depends(get_db),
):
    """Update an insurance partner with enhanced information"""
    
    partner = db.query(Insurance_Partner).filter(Insurance_Partner.id == partner_id).first()
    if not partner:
        raise HTTPException(status_code=404, detail="Insurance partner not found")
    
    # Check if new code conflicts with existing partners
    if payload.code and payload.code != partner.code:
        existing_partner = db.query(Insurance_Partner).filter(
            Insurance_Partner.code == payload.code,
            Insurance_Partner.id != partner_id
        ).first()
        if existing_partner:
            raise HTTPException(status_code=400, detail="Partner code already exists")
    
    # Update fields
    update_data = payload.dict(exclude_unset=True)
    
    # Convert customer_rating from float to int for storage
    if 'customer_rating' in update_data and update_data['customer_rating'] is not None:
        update_data['customer_rating'] = int(update_data['customer_rating'] * 10)
    
    for field, value in update_data.items():
        setattr(partner, field, value)
    
    db.commit()
    db.refresh(partner)
    
    # Convert customer_rating back to float for response
    if partner.customer_rating is not None:
        partner.customer_rating = partner.customer_rating / 10.0
    
    return partner

# Insurance Marketplace (Quote System)
@router.post("/quotes", response_model=InsuranceQuoteResponse)
def get_insurance_quotes(
    request: InsuranceQuoteRequest,
    db: Session = Depends(get_db),
):
    """Get insurance quotes from multiple partners"""
    
    # Get active partners that support quotes
    partners = db.query(Insurance_Partner).filter(
        Insurance_Partner.is_active == True,
        Insurance_Partner.supports_quotes == True
    ).all()
    
    if not partners:
        raise HTTPException(status_code=404, detail="No active insurance partners found")
    
    # TODO: Implement actual quote generation logic
    # For now, return mock quotes
    quotes = []
    for partner in partners:
        # Mock quote generation - in reality, this would call partner APIs
        mock_quote = InsuranceQuote(
            partner_id=partner.id,
            partner_name=partner.name,
            premium_amount=50000,  # Mock premium in cents
            coverage_details={
                "coverage_type": request.coverage_type,
                "coverage_amount": request.coverage_amount or 1000000,
                "deductible": request.deductible_amount or 10000
            },
            deductible_amount=request.deductible_amount or 10000,
            quote_valid_until=datetime.now() + timedelta(days=30),
            terms_and_conditions="Standard terms and conditions apply"
        )
        quotes.append(mock_quote)
    
    return InsuranceQuoteResponse(
        quotes=quotes,
        request_id=str(uuid.uuid4()),
        generated_at=datetime.now()
    )

# Legacy endpoints for backward compatibility
@router.post("/create-insurance-policy", response_model=InsurancePolicyRead, status_code=status.HTTP_201_CREATED)
def create_insurance_policy_legacy(
    payload: InsurancePolicyCreate,
    db: Session = Depends(get_db),
):
    """Legacy endpoint for creating insurance policies"""
    return create_insurance_policy(payload, db)

@router.get("/get-insurance-policies", response_model=List[InsurancePolicyRead])
def get_insurance_policies_legacy(
    db: Session = Depends(get_db),
):
    """Legacy endpoint for getting all insurance policies"""
    return get_insurance_policies(db=db)

@router.get("/get-insurance-policy-by-owner/{owner_id}", response_model=List[InsurancePolicyRead])
def get_insurance_policy_by_owner_legacy(
    owner_id: int,
    db: Session = Depends(get_db),
):
    """Legacy endpoint for getting policies by owner"""
    return get_insurance_policies(owner_id=owner_id, db=db)

# Alert System Integration Endpoints
@router.get("/policies/expiring")
def get_expiring_insurance_policies(
    days_ahead: int = Query(30, description="Number of days ahead to check for expiry"),
    db: Session = Depends(get_db)
):
    """Get insurance policies expiring within specified days (for alert system)"""
    expiry_threshold = datetime.utcnow() + timedelta(days=days_ahead)
    
    policies = db.query(Insurance_Policy).filter(
        Insurance_Policy.expiry_date <= expiry_threshold,
        Insurance_Policy.status == "active"
    ).all()
    
    # Format response for alert system
    result = []
    for policy in policies:
        # Get partner info
        partner = db.query(Insurance_Partner).filter(
            Insurance_Partner.id == policy.provider_id
        ).first()
        
        result.append({
            "id": policy.id,
            "owner_id": policy.owner_id,
            "vehicle_id": policy.vehicle_id,
            "provider_id": policy.provider_id,
            "provider_name": partner.name if partner else "Unknown Provider",
            "policy_number": policy.policy_number,
            "expiry_date": policy.expiry_date.isoformat() if policy.expiry_date else None,
            "premium_amount": policy.premium_amount,
            "insurance_type": policy.insurance_type
        })
    
    return result