# insurance_service/routes/claims.py

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
from datetime import datetime

from core.db import get_db
from models.insurance import Insurance_Claim, Insurance_Policy
from schemas.insurance import (
    InsuranceClaimCreate, 
    InsuranceClaimRead, 
    InsuranceClaimUpdate
)

router = APIRouter()

@router.post("/", response_model=InsuranceClaimRead, status_code=status.HTTP_201_CREATED)
def create_claim(
    payload: InsuranceClaimCreate,
    db: Session = Depends(get_db),
):
    """Create a new insurance claim"""
    
    # Verify policy exists and is active
    policy = db.query(Insurance_Policy).filter(
        Insurance_Policy.id == payload.policy_id,
        Insurance_Policy.status == "active"
    ).first()
    
    if not policy:
        raise HTTPException(
            status_code=404, 
            detail="Active insurance policy not found"
        )
    
    # Generate claim number
    claim_number = f"CLM-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
    
    # Create claim
    claim = Insurance_Claim(
        policy_id=payload.policy_id,
        vehicle_id=payload.vehicle_id,
        user_id=payload.user_id,
        claim_type=payload.claim_type,
        incident_date=payload.incident_date,
        description=payload.description,
        estimated_cost=payload.estimated_cost,
        claim_number=claim_number,
        evidence_files=payload.evidence_files,
        repair_quotes=payload.repair_quotes,
        status="submitted"
    )
    
    db.add(claim)
    db.commit()
    db.refresh(claim)
    
    return claim

@router.get("/", response_model=List[InsuranceClaimRead])
def get_claims(
    user_id: Optional[int] = None,
    vehicle_id: Optional[str] = None,
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """Get claims with optional filtering"""
    
    query = db.query(Insurance_Claim)
    
    if user_id:
        query = query.filter(Insurance_Claim.user_id == user_id)
    if vehicle_id:
        query = query.filter(Insurance_Claim.vehicle_id == vehicle_id)
    if status:
        query = query.filter(Insurance_Claim.status == status)
    
    claims = query.offset(skip).limit(limit).all()
    return claims

@router.get("/{claim_id}", response_model=InsuranceClaimRead)
def get_claim(
    claim_id: str,
    db: Session = Depends(get_db),
):
    """Get a specific claim by ID"""
    
    claim = db.query(Insurance_Claim).filter(Insurance_Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    return claim

@router.put("/{claim_id}", response_model=InsuranceClaimRead)
def update_claim(
    claim_id: str,
    payload: InsuranceClaimUpdate,
    db: Session = Depends(get_db),
):
    """Update a claim"""
    
    claim = db.query(Insurance_Claim).filter(Insurance_Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    # Update fields
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(claim, field, value)
    
    db.commit()
    db.refresh(claim)
    
    return claim

@router.post("/{claim_id}/evidence")
def upload_claim_evidence(
    claim_id: str,
    files: List[UploadFile] = File(...),
    db: Session = Depends(get_db),
):
    """Upload evidence files for a claim"""
    
    claim = db.query(Insurance_Claim).filter(Insurance_Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    # TODO: Implement file upload to cloud storage (AWS S3, etc.)
    # For now, we'll just store the filenames
    uploaded_files = []
    for file in files:
        # Generate unique filename
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else ''
        unique_filename = f"{claim_id}_{len(uploaded_files)}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.{file_extension}"
        uploaded_files.append(unique_filename)
    
    # Update claim with new evidence files
    existing_files = claim.evidence_files or []
    claim.evidence_files = existing_files + uploaded_files
    
    db.commit()
    
    return {
        "message": f"Successfully uploaded {len(files)} files",
        "uploaded_files": uploaded_files,
        "total_evidence_files": len(claim.evidence_files)
    }

@router.get("/{claim_id}/status")
def get_claim_status(
    claim_id: str,
    db: Session = Depends(get_db),
):
    """Get claim status and processing details"""
    
    claim = db.query(Insurance_Claim).filter(Insurance_Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    return {
        "claim_id": claim.id,
        "claim_number": claim.claim_number,
        "status": claim.status,
        "estimated_cost": claim.estimated_cost,
        "approved_amount": claim.approved_amount,
        "assigned_adjuster": claim.assigned_adjuster,
        "review_notes": claim.review_notes,
        "created_at": claim.created_at,
        "updated_at": claim.updated_at
    }

@router.post("/{claim_id}/approve")
def approve_claim(
    claim_id: str,
    approved_amount: int,
    review_notes: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """Approve a claim with approved amount"""
    
    claim = db.query(Insurance_Claim).filter(Insurance_Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    if claim.status != "under_review":
        raise HTTPException(
            status_code=400, 
            detail="Claim must be under review to be approved"
        )
    
    claim.status = "approved"
    claim.approved_amount = approved_amount
    claim.review_notes = review_notes
    
    db.commit()
    
    return {
        "message": "Claim approved successfully",
        "approved_amount": approved_amount,
        "claim_id": claim.id
    }

@router.post("/{claim_id}/reject")
def reject_claim(
    claim_id: str,
    review_notes: str,
    db: Session = Depends(get_db),
):
    """Reject a claim with reason"""
    
    claim = db.query(Insurance_Claim).filter(Insurance_Claim.id == claim_id).first()
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    if claim.status not in ["submitted", "under_review"]:
        raise HTTPException(
            status_code=400, 
            detail="Claim cannot be rejected in current status"
        )
    
    claim.status = "rejected"
    claim.review_notes = review_notes
    
    db.commit()
    
    return {
        "message": "Claim rejected",
        "reason": review_notes,
        "claim_id": claim.id
    }
