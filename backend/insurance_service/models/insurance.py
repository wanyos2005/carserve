# backend/insurance_service/models/insurance.py
import uuid
from sqlalchemy import Column, String, Integer, TIMESTAMP, func, Boolean, JSON, ForeignKey, Text
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
    
    # Enhanced fields for insurance integration
    premium_amount = Column(Integer, nullable=True)  # Premium in cents
    coverage_details = Column(JSON, nullable=True)   # Coverage specifics
    deductible_amount = Column(Integer, nullable=True)  # Deductible in cents
    policy_number = Column(String, unique=True, index=True, nullable=True)
    status = Column(String, default="active")  # active, expired, cancelled, suspended
    renewal_reminder_sent = Column(Boolean, default=False)
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())


class Insurance_Claim(Base):
    __tablename__ = "insurance_claims"
    __table_args__ = {"schema": "insurance"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    policy_id = Column(String, ForeignKey("insurance.insurance_policies.id"), index=True)
    vehicle_id = Column(String, index=True)
    user_id = Column(Integer, index=True)
    
    # Claim details
    claim_type = Column(String, index=True)  # accident, breakdown, theft, vandalism, etc.
    incident_date = Column(TIMESTAMP(timezone=True), nullable=True)
    description = Column(Text, nullable=True)
    estimated_cost = Column(Integer, nullable=True)  # Cost in cents
    actual_cost = Column(Integer, nullable=True)     # Final cost in cents
    
    # Claim status and processing
    status = Column(String, default="submitted")  # submitted, under_review, approved, rejected, paid, closed
    claim_number = Column(String, unique=True, index=True, nullable=True)
    
    # Evidence and documentation
    evidence_files = Column(JSON, nullable=True)  # Photos, documents, receipts
    repair_quotes = Column(JSON, nullable=True)   # Repair estimates from providers
    
    # Processing details
    assigned_adjuster = Column(String, nullable=True)
    review_notes = Column(Text, nullable=True)
    approved_amount = Column(Integer, nullable=True)
    payment_date = Column(TIMESTAMP(timezone=True), nullable=True)
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())


class Risk_Score(Base):
    __tablename__ = "risk_scores"
    __table_args__ = {"schema": "insurance"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    vehicle_id = Column(String, index=True)
    user_id = Column(Integer, index=True)
    
    # Risk scores (0-100, where 100 is lowest risk)
    vehicle_risk_score = Column(Integer, nullable=True)  # Based on vehicle age, mileage, service history
    driver_risk_score = Column(Integer, nullable=True)   # Based on service punctuality, claims history
    combined_risk_score = Column(Integer, nullable=True) # Weighted combination
    
    # Risk factors breakdown
    risk_factors = Column(JSON, nullable=True)  # Detailed breakdown of risk factors
    
    # Scoring metadata
    scoring_algorithm_version = Column(String, default="1.0")
    data_points_used = Column(JSON, nullable=True)  # What data was used for scoring
    
    last_updated = Column(TIMESTAMP(timezone=True), server_default=func.now())
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class Insurance_Partner(Base):
    __tablename__ = "insurance_partners"
    __table_args__ = {"schema": "insurance"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, index=True)
    code = Column(String, unique=True, index=True)  # Partner identifier
    
    # Partner configuration
    api_endpoint = Column(String, nullable=True)
    api_key = Column(String, nullable=True)
    webhook_url = Column(String, nullable=True)
    
    # Partner capabilities
    supports_quotes = Column(Boolean, default=True)
    supports_claims = Column(Boolean, default=True)
    supports_data_feeds = Column(Boolean, default=True)
    
    # Partner status
    is_active = Column(Boolean, default=True)
    commission_rate = Column(Integer, nullable=True)  # Commission percentage (e.g., 10 for 10%)
    
    # Partner metadata
    contact_info = Column(JSON, nullable=True)
    supported_coverage_types = Column(JSON, nullable=True)
    
    # Secondary Information (Decision Factors)
    customer_rating = Column(Integer, nullable=True)  # Rating * 10 (e.g., 48 for 4.8/5.0)
    total_reviews = Column(Integer, nullable=True)
    claims_processing_time = Column(String, nullable=True)  # e.g., "24-48 hours"
    policy_validity_period = Column(String, nullable=True)  # e.g., "12 months"
    special_features = Column(JSON, nullable=True)  # List of special features
    
    # Tertiary Information (Nice to Have)
    logo_url = Column(String, nullable=True)
    website_url = Column(String, nullable=True)
    established_year = Column(Integer, nullable=True)
    market_share = Column(String, nullable=True)  # e.g., "15%"
    awards = Column(JSON, nullable=True)  # List of awards
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())


class Data_Feed_Log(Base):
    __tablename__ = "data_feed_logs"
    __table_args__ = {"schema": "insurance"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    partner_id = Column(String, ForeignKey("insurance.insurance_partners.id"), index=True)
    vehicle_id = Column(String, index=True)
    user_id = Column(Integer, index=True)
    
    # Feed details
    feed_type = Column(String, index=True)  # service_completion, risk_update, claim_submission, etc.
    data_payload = Column(JSON, nullable=True)
    
    # Delivery status
    status = Column(String, default="pending")  # pending, sent, delivered, failed
    response_data = Column(JSON, nullable=True)
    error_message = Column(Text, nullable=True)
    
    # Retry logic
    retry_count = Column(Integer, default=0)
    max_retries = Column(Integer, default=3)
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    sent_at = Column(TIMESTAMP(timezone=True), nullable=True)
