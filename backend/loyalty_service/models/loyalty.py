# backend/loyalty_service/models/loyalty.py
from sqlalchemy import Column, String, Integer, TIMESTAMP, func, Numeric, Boolean, ForeignKey, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from core.db import Base


class LoyaltyAccount(Base):
    """User's loyalty account tracking points balance and tier"""
    __tablename__ = "loyalty_accounts"
    __table_args__ = {"schema": "loyalty"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, nullable=False, unique=True, index=True)  # Links to users.tbl_auth.id
    
    # Points tracking
    points_balance = Column(Integer, default=0, nullable=False)
    lifetime_points_earned = Column(Integer, default=0, nullable=False)
    lifetime_points_spent = Column(Integer, default=0, nullable=False)
    
    # Tier system
    tier = Column(String(20), default="bronze", nullable=False)  # bronze, silver, gold, platinum
    tier_points_threshold = Column(Integer, nullable=True)  # Points needed for next tier
    
    # Account status
    is_active = Column(Boolean, default=True, nullable=False)
    joined_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    last_activity_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    transactions = relationship("LoyaltyTransaction", back_populates="account", cascade="all, delete-orphan")
    redemptions = relationship("LoyaltyRedemption", back_populates="account")

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())


class LoyaltyTransaction(Base):
    """All point transactions (earned, spent, expired, adjusted)"""
    __tablename__ = "loyalty_transactions"
    __table_args__ = {"schema": "loyalty"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    account_id = Column(String, ForeignKey("loyalty.loyalty_accounts.id"), nullable=False, index=True)
    
    # Transaction details
    points_delta = Column(Integer, nullable=False)  # Positive for earned, negative for spent
    points_balance_after = Column(Integer, nullable=False)  # Balance after this transaction
    
    # Transaction metadata
    transaction_type = Column(String(50), nullable=False, index=True)  # earned, redeemed, expired, adjusted, bonus
    transaction_reason = Column(String(255), nullable=True)  # Human-readable reason
    
    # Reference tracking (for idempotency and reconciliation)
    reference_type = Column(String(50), nullable=True, index=True)  # service_log, booking, redemption, referral, etc.
    reference_id = Column(String, nullable=True, index=True)  # ID of the source record
    idempotency_key = Column(String, unique=True, nullable=True, index=True)  # Prevent duplicate processing
    
    # Provider/service context (for rule application)
    provider_id = Column(String, nullable=True, index=True)
    service_id = Column(String, nullable=True)
    amount_spent = Column(Integer, nullable=True)  # Amount that triggered this transaction
    
    # Expiration tracking
    expires_at = Column(TIMESTAMP(timezone=True), nullable=True, index=True)
    is_expired = Column(Boolean, default=False, nullable=False, index=True)
    
    # Metadata
    extra_metadata = Column(JSON, nullable=True)  # Additional flexible data (renamed from metadata)
    
    # Relationships
    account = relationship("LoyaltyAccount", back_populates="transactions")
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), index=True)


class LoyaltyRule(Base):
    """Configurable rules for earning points"""
    __tablename__ = "loyalty_rules"
    __table_args__ = {"schema": "loyalty"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Rule identification
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    
    # Rule scope
    provider_id = Column(String, nullable=True, index=True)  # None = applies to all providers
    provider_category_id = Column(Integer, nullable=True, index=True)  # e.g., garage, insurance, etc.
    service_id = Column(String, nullable=True, index=True)  # None = applies to all services
    service_category_id = Column(Integer, nullable=True, index=True)
    
    # Point calculation rules
    base_points_per_kes = Column(Numeric(10, 4), default=0.01, nullable=False)  # 0.01 = 1 point per KES 100
    multiplier = Column(Numeric(5, 2), default=1.0, nullable=False)  # Additional multiplier
    min_amount = Column(Integer, nullable=True)  # Minimum spend to trigger
    max_points_per_transaction = Column(Integer, nullable=True)  # Cap per transaction
    
    # Tier-specific multipliers (JSON: {"bronze": 1.0, "silver": 1.5, "gold": 2.0})
    tier_multipliers = Column(JSON, nullable=True)
    
    # Date validity
    valid_from = Column(TIMESTAMP(timezone=True), nullable=True)
    valid_until = Column(TIMESTAMP(timezone=True), nullable=True)
    
    # Rule status
    is_active = Column(Boolean, default=True, nullable=False)
    priority = Column(Integer, default=0, nullable=False)  # Higher priority rules evaluated first
    
    # Additional conditions (JSON for flexible rule matching)
    conditions = Column(JSON, nullable=True)  # e.g., {"day_of_week": "monday", "min_spend": 5000}
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())


class Reward(Base):
    """Available rewards that users can redeem"""
    __tablename__ = "rewards"
    __table_args__ = {"schema": "loyalty"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # Reward details
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    reward_type = Column(String(50), nullable=False)  # discount, cashback, voucher, upgrade, gift
    
    # Cost
    points_cost = Column(Integer, nullable=False)
    
    # Reward value
    discount_percentage = Column(Numeric(5, 2), nullable=True)  # For discount rewards
    discount_amount = Column(Integer, nullable=True)  # For fixed discount
    cashback_amount = Column(Integer, nullable=True)  # For cashback rewards
    voucher_code_template = Column(String(255), nullable=True)  # Template for voucher codes
    
    # Availability
    is_active = Column(Boolean, default=True, nullable=False)
    total_available = Column(Integer, nullable=True)  # None = unlimited
    total_redeemed = Column(Integer, default=0, nullable=False)
    
    # Limits
    max_redemptions_per_user = Column(Integer, nullable=True)  # None = unlimited
    min_tier_required = Column(String(20), nullable=True)  # Minimum tier to redeem
    
    # Validity
    valid_from = Column(TIMESTAMP(timezone=True), nullable=True)
    valid_until = Column(TIMESTAMP(timezone=True), nullable=True)
    
    # Image/icon
    image_url = Column(String(512), nullable=True)
    
    # Metadata
    extra_metadata = Column(JSON, nullable=True)  # Additional reward-specific data (renamed from metadata)
    
    # Relationships
    redemptions = relationship("LoyaltyRedemption", back_populates="reward")
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())


class LoyaltyRedemption(Base):
    """Records of reward redemptions"""
    __tablename__ = "loyalty_redemptions"
    __table_args__ = {"schema": "loyalty"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # References
    account_id = Column(String, ForeignKey("loyalty.loyalty_accounts.id"), nullable=False, index=True)
    reward_id = Column(String, ForeignKey("loyalty.rewards.id"), nullable=False, index=True)
    
    # Redemption details
    points_spent = Column(Integer, nullable=False)
    status = Column(String(50), default="pending", nullable=False)  # pending, fulfilled, cancelled, expired
    
    # Reward details (snapshot at redemption time)
    reward_name = Column(String(255), nullable=False)
    reward_type = Column(String(50), nullable=False)
    reward_value = Column(JSON, nullable=True)  # Snapshot of reward value (discount %, amount, etc.)
    
    # Voucher/code (for voucher-type rewards)
    voucher_code = Column(String(255), nullable=True, unique=True, index=True)
    
    # Fulfillment
    fulfilled_at = Column(TIMESTAMP(timezone=True), nullable=True)
    fulfilled_by = Column(String, nullable=True)  # Admin/system that fulfilled
    fulfillment_notes = Column(Text, nullable=True)
    
    # Expiration
    expires_at = Column(TIMESTAMP(timezone=True), nullable=True)
    
    # Cancellation
    cancelled_at = Column(TIMESTAMP(timezone=True), nullable=True)
    cancellation_reason = Column(Text, nullable=True)
    
    # Relationships
    account = relationship("LoyaltyAccount", back_populates="redemptions")
    reward = relationship("Reward", back_populates="redemptions")
    
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())


class ProviderLoyaltyConfig(Base):
    """Provider's loyalty program configuration and participation status"""
    __tablename__ = "provider_loyalty_configs"
    __table_args__ = {"schema": "loyalty"}

    provider_id = Column(String, primary_key=True, index=True)
    
    # Participation status
    is_participating = Column(Boolean, default=False, nullable=False, index=True)
    
    # Point calculation
    point_multiplier = Column(Numeric(5, 2), default=1.0, nullable=False)  # 1.0x, 1.5x, 2.0x, etc.
    participation_tier = Column(String(20), nullable=True, index=True)  # basic, premium, elite
    
    # Budget and usage tracking
    monthly_point_budget = Column(Integer, nullable=True)  # Optional limit per month
    points_awarded_this_month = Column(Integer, default=0, nullable=False)
    current_month_start = Column(TIMESTAMP(timezone=True), nullable=True)  # Track month boundaries
    
    # Billing configuration
    billing_plan = Column(String(50), default="free", nullable=False)  # free, pay_per_point, monthly_subscription
    billing_rate_per_point = Column(Numeric(10, 4), nullable=True)  # e.g., 0.01 KES per point
    monthly_subscription_fee = Column(Integer, nullable=True)  # For monthly_subscription plan
    
    # Metadata
    extra_metadata = Column(JSON, nullable=True)  # Additional configuration data (renamed from metadata due to SQLAlchemy reserved name)
    
    # Timestamps
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    participation_enabled_at = Column(TIMESTAMP(timezone=True), nullable=True)  # When they opted in

