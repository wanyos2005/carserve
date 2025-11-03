# backend/loyalty_service/schemas/loyalty.py
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from decimal import Decimal


# ============ LoyaltyAccount Schemas ============
class LoyaltyAccountBase(BaseModel):
    user_id: int

class LoyaltyAccountCreate(LoyaltyAccountBase):
    pass

class LoyaltyAccountUpdate(BaseModel):
    points_balance: Optional[int] = None
    tier: Optional[str] = None
    is_active: Optional[bool] = None

class LoyaltyAccount(LoyaltyAccountBase):
    id: str
    points_balance: int
    lifetime_points_earned: int
    lifetime_points_spent: int
    tier: str
    tier_points_threshold: Optional[int]
    is_active: bool
    joined_at: datetime
    last_activity_at: datetime
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============ LoyaltyTransaction Schemas ============
class LoyaltyTransactionBase(BaseModel):
    points_delta: int
    transaction_type: str #eg earned, redeemed, expired, adjusted, bonus
    transaction_reason: Optional[str] = None #eg Points earned from service log, Points redeemed for reward, Points expired, Points adjusted, Points bonus
    reference_type: Optional[str] = None #eg service_log, booking, redemption, referral, etc.
    reference_id: Optional[str] = None #eg service_log_id, booking_id, redemption_id, referral_id, etc.
    provider_id: Optional[str] = None
    service_id: Optional[str] = None
    amount_spent: Optional[int] = None
    expires_at: Optional[datetime] = None
    extra_metadata: Optional[Dict[str, Any]] = None

class LoyaltyTransactionCreate(LoyaltyTransactionBase):
    account_id: str
    idempotency_key: Optional[str] = None

class LoyaltyTransaction(LoyaltyTransactionBase):
    id: str
    account_id: str
    points_balance_after: int
    idempotency_key: Optional[str]
    is_expired: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ============ Points Award Request ============
class PointsAwardRequest(BaseModel):
    user_id: int
    provider_id: Optional[str] = None
    service_id: Optional[str] = None
    amount_spent: int = Field(..., gt=0, description="Amount spent in KES")
    reference_type: str = Field(default="service_log")
    reference_id: Optional[str] = None
    idempotency_key: Optional[str] = None


class PointsAwardResponse(BaseModel):
    success: bool
    account_id: str
    points_awarded: int
    points_balance: int
    transaction_id: str
    message: str


# ============ LoyaltyRule Schemas ============
class LoyaltyRuleBase(BaseModel):
    name: str
    description: Optional[str] = None
    provider_id: Optional[str] = None
    provider_category_id: Optional[int] = None
    service_id: Optional[str] = None
    service_category_id: Optional[int] = None
    base_points_per_kes: Decimal = Field(default=Decimal("0.01"))
    multiplier: Decimal = Field(default=Decimal("1.0"))
    min_amount: Optional[int] = None
    max_points_per_transaction: Optional[int] = None
    tier_multipliers: Optional[Dict[str, float]] = None
    valid_from: Optional[datetime] = None
    valid_until: Optional[datetime] = None
    is_active: bool = True
    priority: int = 0
    conditions: Optional[Dict[str, Any]] = None

class LoyaltyRuleCreate(LoyaltyRuleBase):
    pass

class LoyaltyRuleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    base_points_per_kes: Optional[Decimal] = None
    multiplier: Optional[Decimal] = None
    is_active: Optional[bool] = None
    priority: Optional[int] = None

class LoyaltyRule(LoyaltyRuleBase):
    id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============ Reward Schemas ============
class RewardBase(BaseModel):
    name: str
    description: Optional[str] = None
    reward_type: str  # discount, cashback, voucher, upgrade, gift
    points_cost: int
    discount_percentage: Optional[Decimal] = None
    discount_amount: Optional[int] = None
    cashback_amount: Optional[int] = None
    voucher_code_template: Optional[str] = None
    is_active: bool = True
    total_available: Optional[int] = None
    max_redemptions_per_user: Optional[int] = None
    min_tier_required: Optional[str] = None
    valid_from: Optional[datetime] = None
    valid_until: Optional[datetime] = None
    image_url: Optional[str] = None
    # Extra metadata (aligned with model's extra_metadata)
    extra_metadata: Optional[Dict[str, Any]] = None
    # Funding
    funding_model: Optional[str] = Field(default="platform")  # platform, provider, co_funded
    funding_provider_id: Optional[str] = None
    co_fund_split_pct: Optional[int] = None

class RewardCreate(RewardBase):
    pass

class RewardUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    points_cost: Optional[int] = None
    is_active: Optional[bool] = None

class Reward(RewardBase):
    id: str
    total_redeemed: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============ Redemption Schemas ============
class RedemptionCreate(BaseModel):
    account_id: str
    reward_id: str

class RedemptionUpdate(BaseModel):
    status: Optional[str] = None
    fulfilled_at: Optional[datetime] = None
    fulfilled_by: Optional[str] = None
    fulfilment_notes: Optional[str] = None
    cancelled_at: Optional[datetime] = None
    cancellation_reason: Optional[str] = None

class LoyaltyRedemption(BaseModel):
    id: str
    account_id: str
    reward_id: str
    points_spent: int
    status: str
    reward_name: str
    reward_type: str
    reward_value: Optional[Dict[str, Any]] = None
    voucher_code: Optional[str] = None
    is_consumed: Optional[bool] = None
    validated_at: Optional[datetime] = None
    validated_by_provider_id: Optional[str] = None
    fulfilled_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ============ Voucher Validation ============
class VoucherValidateRequest(BaseModel):
    provider_id: str
    voucher_code: str
    metadata: Optional[Dict[str, Any]] = None

class VoucherValidateResponse(BaseModel):
    success: bool
    redemption_id: Optional[str] = None
    reward_id: Optional[str] = None
    message: str


# ============ Provider Sponsor Reward Request ============
class ProviderSponsorRewardRequest(BaseModel):
    provider_id: str
    name: str
    reward_type: str  # voucher/discount/cashback
    points_cost: int
    # value
    discount_percentage: Optional[Decimal] = None
    discount_amount: Optional[int] = None
    cashback_amount: Optional[int] = None
    voucher_code_template: Optional[str] = None
    # funding
    funding_model: str  # provider or co_funded
    co_fund_split_pct: Optional[int] = None
    # availability
    total_available: Optional[int] = None
    valid_from: Optional[datetime] = None
    valid_until: Optional[datetime] = None
    min_tier_required: Optional[str] = None
    description: Optional[str] = None


# ============ Account Summary ============
class LoyaltyAccountSummary(BaseModel):
    account: LoyaltyAccount
    recent_transactions: List[LoyaltyTransaction]
    available_rewards: List[Reward]
    tier_info: Dict[str, Any]


# ============ Tier Info ============
class TierInfo(BaseModel):
    current_tier: str
    current_points: int
    next_tier: Optional[str] = None
    points_to_next_tier: Optional[int] = None
    tier_benefits: Dict[str, Any]


# ============ Provider Loyalty Config Schemas ============
class ProviderLoyaltyConfigBase(BaseModel):
    is_participating: bool = False
    point_multiplier: Decimal = Field(default=Decimal("1.0"), ge=0.5, le=5.0)
    participation_tier: Optional[str] = None  # basic, premium, elite
    monthly_point_budget: Optional[int] = None
    billing_plan: str = Field(default="free")  # free, pay_per_point, monthly_subscription
    billing_rate_per_point: Optional[Decimal] = None
    monthly_subscription_fee: Optional[int] = None
    extra_metadata: Optional[Dict[str, Any]] = None

class ProviderLoyaltyConfigCreate(ProviderLoyaltyConfigBase):
    provider_id: str

class ProviderLoyaltyConfigUpdate(BaseModel):
    is_participating: Optional[bool] = None
    point_multiplier: Optional[Decimal] = None
    participation_tier: Optional[str] = None
    monthly_point_budget: Optional[int] = None
    billing_plan: Optional[str] = None
    billing_rate_per_point: Optional[Decimal] = None
    monthly_subscription_fee: Optional[int] = None
    extra_metadata: Optional[Dict[str, Any]] = None

class ProviderLoyaltyConfig(ProviderLoyaltyConfigBase):
    provider_id: str
    points_awarded_this_month: int
    current_month_start: Optional[datetime] = None
    participation_enabled_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============ Provider Opt-In Request ============
class ProviderOptInRequest(BaseModel):
    participation_tier: str = Field(..., description="Tier: basic, premium, elite")
    billing_plan: str = Field(default="monthly_subscription", description="Billing plan")
    monthly_subscription_fee: Optional[int] = Field(None, description="Monthly fee if subscription plan")
    billing_rate_per_point: Optional[Decimal] = Field(None, description="Rate per point if pay-per-point plan")
    monthly_point_budget: Optional[int] = Field(None, description="Optional monthly point budget limit")

class ProviderOptInResponse(BaseModel):
    success: bool
    provider_id: str
    config: ProviderLoyaltyConfig
    rule_created: bool
    message: str


# ============ Provider Usage/Stats ============
class ProviderLoyaltyUsage(BaseModel):
    provider_id: str
    is_participating: bool
    points_awarded_this_month: int
    monthly_point_budget: Optional[int] = None
    points_remaining: Optional[int] = None
    billing_plan: str
    estimated_monthly_cost: Optional[Decimal] = None
    participation_tier: Optional[str] = None
    participation_enabled_at: Optional[datetime] = None

