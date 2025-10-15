#backend/insurance_service/schemas/insurance.py
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any, List

# Enhanced Policy Schemas
class InsurancePolicyBase(BaseModel):
    owner_id: int
    vehicle_id: str
    provider_id: str
    insurance_type: str
    commencement_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None
    premium_amount: Optional[int] = None  # Premium in cents
    coverage_details: Optional[Dict[str, Any]] = None
    deductible_amount: Optional[int] = None  # Deductible in cents
    policy_number: Optional[str] = None

class InsurancePolicyCreate(InsurancePolicyBase):
    pass

class InsurancePolicyRead(BaseModel):
    id: str
    owner_id: int
    vehicle_id: str
    provider_id: str
    insurance_type: str
    commencement_date: Optional[datetime]
    expiry_date: Optional[datetime]
    premium_amount: Optional[int]
    coverage_details: Optional[Dict[str, Any]]
    deductible_amount: Optional[int]
    policy_number: Optional[str]
    status: str
    renewal_reminder_sent: bool
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

class InsurancePolicyUpdate(BaseModel):
    insurance_type: Optional[str] = None
    provider_id: Optional[str] = None
    commencement_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None
    premium_amount: Optional[int] = None
    coverage_details: Optional[Dict[str, Any]] = None
    deductible_amount: Optional[int] = None
    policy_number: Optional[str] = None
    status: Optional[str] = None

# Claims Schemas
class InsuranceClaimBase(BaseModel):
    policy_id: str
    vehicle_id: str
    user_id: int
    claim_type: str
    incident_date: Optional[datetime] = None
    description: Optional[str] = None
    estimated_cost: Optional[int] = None

class InsuranceClaimCreate(InsuranceClaimBase):
    evidence_files: Optional[List[str]] = None
    repair_quotes: Optional[List[Dict[str, Any]]] = None

class InsuranceClaimRead(BaseModel):
    id: str
    policy_id: str
    vehicle_id: str
    user_id: int
    claim_type: str
    incident_date: Optional[datetime]
    description: Optional[str]
    estimated_cost: Optional[int]
    actual_cost: Optional[int]
    status: str
    claim_number: Optional[str]
    evidence_files: Optional[List[str]]
    repair_quotes: Optional[List[Dict[str, Any]]]
    assigned_adjuster: Optional[str]
    review_notes: Optional[str]
    approved_amount: Optional[int]
    payment_date: Optional[datetime]
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

class InsuranceClaimUpdate(BaseModel):
    status: Optional[str] = None
    actual_cost: Optional[int] = None
    assigned_adjuster: Optional[str] = None
    review_notes: Optional[str] = None
    approved_amount: Optional[int] = None
    payment_date: Optional[datetime] = None
    evidence_files: Optional[List[str]] = None
    repair_quotes: Optional[List[Dict[str, Any]]] = None

# Risk Score Schemas
class RiskScoreBase(BaseModel):
    vehicle_id: str
    user_id: int

class RiskScoreCreate(RiskScoreBase):
    vehicle_risk_score: Optional[int] = None
    driver_risk_score: Optional[int] = None
    combined_risk_score: Optional[int] = None
    risk_factors: Optional[Dict[str, Any]] = None

class RiskScoreRead(BaseModel):
    id: str
    vehicle_id: str
    user_id: int
    vehicle_risk_score: Optional[int]
    driver_risk_score: Optional[int]
    combined_risk_score: Optional[int]
    risk_factors: Optional[Dict[str, Any]]
    scoring_algorithm_version: str
    data_points_used: Optional[Dict[str, Any]]
    last_updated: datetime
    created_at: datetime

    class Config:
        from_attributes = True

# Insurance Partner Schemas
class InsurancePartnerBase(BaseModel):
    name: str
    code: str
    api_endpoint: Optional[str] = None
    webhook_url: Optional[str] = None
    supports_quotes: bool = True
    supports_claims: bool = True
    supports_data_feeds: bool = True
    commission_rate: Optional[int] = None
    contact_info: Optional[Dict[str, Any]] = None
    supported_coverage_types: Optional[List[str]] = None
    
    # Secondary Information (Decision Factors)
    customer_rating: Optional[float] = None  # Rating as decimal (e.g., 4.8)
    total_reviews: Optional[int] = None
    claims_processing_time: Optional[str] = None  # e.g., "24-48 hours"
    policy_validity_period: Optional[str] = None  # e.g., "12 months"
    special_features: Optional[List[str]] = None  # List of special features
    
    # Tertiary Information (Nice to Have)
    logo_url: Optional[str] = None
    website_url: Optional[str] = None
    established_year: Optional[int] = None
    market_share: Optional[str] = None  # e.g., "15%"
    awards: Optional[List[str]] = None  # List of awards

class InsurancePartnerCreate(InsurancePartnerBase):
    pass

class InsurancePartnerUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    api_endpoint: Optional[str] = None
    webhook_url: Optional[str] = None
    supports_quotes: Optional[bool] = None
    supports_claims: Optional[bool] = None
    supports_data_feeds: Optional[bool] = None
    is_active: Optional[bool] = None
    commission_rate: Optional[int] = None
    contact_info: Optional[Dict[str, Any]] = None
    supported_coverage_types: Optional[List[str]] = None
    
    # Secondary Information (Decision Factors)
    customer_rating: Optional[float] = None
    total_reviews: Optional[int] = None
    claims_processing_time: Optional[str] = None
    policy_validity_period: Optional[str] = None
    special_features: Optional[List[str]] = None
    
    # Tertiary Information (Nice to Have)
    logo_url: Optional[str] = None
    website_url: Optional[str] = None
    established_year: Optional[int] = None
    market_share: Optional[str] = None
    awards: Optional[List[str]] = None

class InsurancePartnerRead(BaseModel):
    id: str
    name: str
    code: str
    api_endpoint: Optional[str]
    webhook_url: Optional[str]
    supports_quotes: bool
    supports_claims: bool
    supports_data_feeds: bool
    is_active: bool
    commission_rate: Optional[int]
    contact_info: Optional[Dict[str, Any]]
    supported_coverage_types: Optional[List[str]]
    
    # Secondary Information (Decision Factors)
    customer_rating: Optional[float]
    total_reviews: Optional[int]
    claims_processing_time: Optional[str]
    policy_validity_period: Optional[str]
    special_features: Optional[List[str]]
    
    # Tertiary Information (Nice to Have)
    logo_url: Optional[str]
    website_url: Optional[str]
    established_year: Optional[int]
    market_share: Optional[str]
    awards: Optional[List[str]]
    
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

# Data Feed Schemas
class DataFeedLogBase(BaseModel):
    partner_id: str
    vehicle_id: str
    user_id: int
    feed_type: str
    data_payload: Optional[Dict[str, Any]] = None

class DataFeedLogCreate(DataFeedLogBase):
    pass

class DataFeedLogRead(BaseModel):
    id: str
    partner_id: str
    vehicle_id: str
    user_id: int
    feed_type: str
    data_payload: Optional[Dict[str, Any]]
    status: str
    response_data: Optional[Dict[str, Any]]
    error_message: Optional[str]
    retry_count: int
    max_retries: int
    created_at: datetime
    sent_at: Optional[datetime]

    class Config:
        from_attributes = True

# Quote and Marketplace Schemas
class InsuranceQuoteRequest(BaseModel):
    vehicle_id: str
    user_id: int
    coverage_type: str
    coverage_amount: Optional[int] = None
    deductible_amount: Optional[int] = None

class InsuranceQuote(BaseModel):
    partner_id: str
    partner_name: str
    premium_amount: int
    coverage_details: Dict[str, Any]
    deductible_amount: int
    quote_valid_until: datetime
    terms_and_conditions: Optional[str] = None

class InsuranceQuoteResponse(BaseModel):
    quotes: List[InsuranceQuote]
    request_id: str
    generated_at: datetime

