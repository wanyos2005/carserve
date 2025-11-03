# backend/loyalty_service/routers/loyalty.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timezone
from decimal import Decimal

from core.db import get_db
from schemas.loyalty import (
    LoyaltyAccount,
    LoyaltyAccountSummary,
    LoyaltyTransaction,
    PointsAwardRequest,
    PointsAwardResponse,
    LoyaltyRule,
    LoyaltyRuleCreate,
    LoyaltyRuleUpdate,
    Reward,
    RewardCreate,
    RewardUpdate,
    LoyaltyRedemption,
    RedemptionCreate,
    TierInfo,
    ProviderLoyaltyConfig,
    ProviderLoyaltyConfigUpdate,
    ProviderOptInRequest,
    ProviderOptInResponse,
    ProviderLoyaltyUsage,
    VoucherValidateRequest,
    VoucherValidateResponse,
    ProviderSponsorRewardRequest,
)
from crud import loyalty as crud
from services.points_calculator import PointsCalculator
import hashlib

router = APIRouter(tags=["loyalty"])


# ============ Account Endpoints ============
@router.get("/account/{user_id}", response_model=LoyaltyAccount)
def get_account(user_id: int, db: Session = Depends(get_db)):
    """Get or create loyalty account for user"""
    account = crud.get_or_create_account(db, user_id)
    return account


@router.get("/account/{user_id}/summary", response_model=LoyaltyAccountSummary)
def get_account_summary(
    user_id: int,
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get account summary with recent transactions and available rewards"""
    account = crud.get_or_create_account(db, user_id)
    
    # Get recent transactions
    transactions = crud.get_transactions(db, user_id=user_id, limit=limit)
    
    # Get available rewards
    calculator = PointsCalculator(db)
    tier_info = calculator.calculate_tier(account)
    rewards = crud.list_available_rewards(db, min_tier=account.tier, limit=20)
    
    return {
        "account": account,
        "recent_transactions": transactions,
        "available_rewards": rewards,
        "tier_info": tier_info,
    }


@router.get("/account/{user_id}/tier", response_model=TierInfo)
def get_tier_info(user_id: int, db: Session = Depends(get_db)):
    """Get tier information for user"""
    account = crud.get_or_create_account(db, user_id)
    calculator = PointsCalculator(db)
    return calculator.calculate_tier(account)


# ============ Points Award Endpoint ============
@router.post("/points/award", response_model=PointsAwardResponse)
def award_points(
    request: PointsAwardRequest,
    db: Session = Depends(get_db)
):
    """
    Award points to user based on spending.
    This is the main endpoint called by booking service.
    """
    # Generate idempotency key if not provided
    idempotency_key = request.idempotency_key
    if not idempotency_key:
        # Generate from reference data
        key_parts = [
            str(request.user_id),
            request.reference_type or "unknown",
            request.reference_id or str(datetime.now(timezone.utc).timestamp()),
        ]
        idempotency_key = hashlib.md5("|".join(key_parts).encode()).hexdigest()
    
    # Check if already processed
    existing = crud.check_idempotency(db, idempotency_key)
    if existing:
        account = crud.get_account_by_id(db, existing.account_id)
        return PointsAwardResponse(
            success=True,
            account_id=existing.account_id,
            points_awarded=existing.points_delta,
            points_balance=account.points_balance if account else 0,
            transaction_id=existing.id,
            message="Points already awarded (idempotent)",
        )
    
    # Get or create account
    account = crud.get_or_create_account(db, request.user_id)
    
    # Calculate points using rules engine
    calculator = PointsCalculator(db)
    
    # Get provider category if needed (would need to query provider service)
    # For now, pass None and let rules handle it
    calculation_result = calculator.calculate_points(
        amount_spent=request.amount_spent,
        user_id=request.user_id,
        provider_id=request.provider_id,
        service_id=request.service_id,
        metadata={"reference_type": request.reference_type, "reference_id": request.reference_id},
    )
    
    points_to_award = calculation_result["points"]
    
    if points_to_award <= 0:
        return PointsAwardResponse(
            success=False,
            account_id=account.id,
            points_awarded=0,
            points_balance=account.points_balance,
            transaction_id="",
            message="No points to award",
        )
    
    # Check and update tier if needed
    old_tier = account.tier
    tier_info = calculator.calculate_tier(account)
    new_tier = tier_info["current_tier"]
    tier_changed = new_tier != old_tier
    
    if tier_changed:
        account.tier = new_tier
        account.tier_points_threshold = tier_info.get("points_to_next_tier")
        db.commit()
        db.refresh(account)
    
    # Check provider participation and budget limits
    if request.provider_id:
        provider_config = crud.get_provider_config(db, request.provider_id)
        
        # Check if provider has monthly budget and if exceeded
        if provider_config:
            if provider_config.monthly_point_budget:
                if provider_config.points_awarded_this_month + points_to_award > provider_config.monthly_point_budget:
                    # Budget exceeded, award only remaining points
                    remaining = provider_config.monthly_point_budget - provider_config.points_awarded_this_month
                    if remaining > 0:
                        points_to_award = remaining
                    else:
                        return PointsAwardResponse(
                            success=False,
                            account_id=account.id,
                            points_awarded=0,
                            points_balance=account.points_balance,
                            transaction_id="",
                            message="Provider monthly point budget exceeded",
                        )
    
    # Create transaction
    try:
        transaction = crud.create_transaction(
            db=db,
            account_id=account.id,
            points_delta=points_to_award,
            transaction_type="earned",
            transaction_reason=f"Points earned from {request.reference_type}",
            reference_type=request.reference_type,
            reference_id=request.reference_id or request.idempotency_key,
            idempotency_key=idempotency_key,
            provider_id=request.provider_id,
            service_id=request.service_id,
            amount_spent=request.amount_spent,
        )
        
        # Track points awarded to provider for billing
        if request.provider_id and points_to_award > 0:
            crud.increment_provider_points_awarded(db, request.provider_id, points_to_award)
        
        # Refresh account to get updated balance
        db.refresh(account)
        
        message = f"Awarded {points_to_award} points"
        if tier_changed:
            message += f". Tier upgraded to {account.tier}!"
        
        return PointsAwardResponse(
            success=True,
            account_id=account.id,
            points_awarded=points_to_award,
            points_balance=account.points_balance,
            transaction_id=transaction.id,
            message=message,
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to award points: {str(e)}")


# ============ Transaction Endpoints ============
@router.get("/transactions/{user_id}", response_model=List[LoyaltyTransaction])
def get_user_transactions(
    user_id: int,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Get transaction history for user"""
    return crud.get_transactions(db, user_id=user_id, limit=limit, offset=offset)


@router.get("/transactions/account/{account_id}", response_model=List[LoyaltyTransaction])
def get_account_transactions(
    account_id: str,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Get transaction history for account"""
    return crud.get_transactions(db, account_id=account_id, limit=limit, offset=offset)


# ============ Rule Endpoints (Admin) ============
@router.post("/rules", response_model=LoyaltyRule)
def create_rule(rule: LoyaltyRuleCreate, db: Session = Depends(get_db)):
    """Create a new loyalty rule"""
    return crud.create_rule(db, rule)


@router.get("/rules", response_model=List[LoyaltyRule])
def list_rules(
    is_active: Optional[bool] = Query(None),
    db: Session = Depends(get_db)
):
    """List all loyalty rules"""
    return crud.list_rules(db, is_active=is_active)


@router.get("/rules/{rule_id}", response_model=LoyaltyRule)
def get_rule(rule_id: str, db: Session = Depends(get_db)):
    """Get rule by ID"""
    rule = crud.get_rule(db, rule_id)
    if not rule:
        raise HTTPException(status_code=404, detail="Rule not found")
    return rule


@router.put("/rules/{rule_id}", response_model=LoyaltyRule)
def update_rule(rule_id: str, rule_update: LoyaltyRuleUpdate, db: Session = Depends(get_db)):
    """Update a loyalty rule"""
    rule = crud.update_rule(db, rule_id, rule_update)
    if not rule:
        raise HTTPException(status_code=404, detail="Rule not found")
    return rule


@router.delete("/rules/{rule_id}", status_code=204)
def delete_rule(rule_id: str, db: Session = Depends(get_db)):
    """Delete a loyalty rule"""
    rule = crud.get_rule(db, rule_id)
    if not rule:
        raise HTTPException(status_code=404, detail="Rule not found")
    
    # Prevent deleting default rule
    if rule.name and "default" in rule.name.lower():
        raise HTTPException(status_code=400, detail="Cannot delete default rule")
    
    crud.delete_rule(db, rule_id)
    return None


# ============ Reward Endpoints ============
@router.post("/rewards", response_model=Reward)
def create_reward(reward: RewardCreate, db: Session = Depends(get_db)):
    """Create a new reward (admin)"""
    return crud.create_reward(db, reward)


@router.get("/rewards", response_model=List[Reward])
def list_rewards(
    is_active: Optional[bool] = Query(None),
    db: Session = Depends(get_db)
):
    """List rewards (admin). If is_active is None, return all; otherwise filter."""
    return crud.list_rewards(db, is_active=is_active)


@router.get("/rewards/{reward_id}", response_model=Reward)
def get_reward(reward_id: str, db: Session = Depends(get_db)):
    """Get reward by ID"""
    reward = crud.get_reward(db, reward_id)
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")
    return reward


@router.put("/rewards/{reward_id}", response_model=Reward)
def update_reward(reward_id: str, reward_update: RewardUpdate, db: Session = Depends(get_db)):
    """Update a reward"""
    reward = crud.update_reward(db, reward_id, reward_update)
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")
    return reward


@router.delete("/rewards/{reward_id}", status_code=204)
def delete_reward(reward_id: str, db: Session = Depends(get_db)):
    """Delete a reward"""
    reward = crud.get_reward(db, reward_id)
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")
    crud.delete_reward(db, reward_id)
    return None


# ============ Redemption Endpoints ============
@router.post("/redemptions", response_model=LoyaltyRedemption)
def redeem_reward(
    redemption: RedemptionCreate,
    db: Session = Depends(get_db)
):
    """Redeem a reward (spend points)"""
    try:
        return crud.create_redemption(db, redemption.account_id, redemption.reward_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/redemptions/{user_id}", response_model=List[LoyaltyRedemption])
def get_user_redemptions(
    user_id: int,
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get user's redemption history"""
    account = crud.get_or_create_account(db, user_id)
    return crud.list_user_redemptions(db, account.id, limit=limit)


@router.get("/redemptions/account/{account_id}", response_model=List[LoyaltyRedemption])
def get_account_redemptions(
    account_id: str,
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get account's redemption history"""
    return crud.list_user_redemptions(db, account_id, limit=limit)


@router.get("/redemptions/id/{redemption_id}", response_model=LoyaltyRedemption)
def get_redemption(redemption_id: str, db: Session = Depends(get_db)):
    """Get redemption by ID"""
    redemption = crud.get_redemption(db, redemption_id)
    if not redemption:
        raise HTTPException(status_code=404, detail="Redemption not found")
    return redemption


# ============ Provider Loyalty Config Endpoints ============
@router.get("/providers/{provider_id}/config", response_model=ProviderLoyaltyConfig)
def get_provider_config(provider_id: str, db: Session = Depends(get_db)):
    """Get provider loyalty configuration"""
    config = crud.get_or_create_provider_config(db, provider_id)
    return config


@router.post("/providers/{provider_id}/enable", response_model=ProviderOptInResponse)
def enable_provider_participation(
    provider_id: str,
    request: ProviderOptInRequest,
    db: Session = Depends(get_db)
):
    """Enable provider participation in loyalty program (opt-in)"""
    
    # Get multiplier for tier
    multiplier = crud.get_multiplier_for_tier(request.participation_tier)
    
    # Get or create config
    config = crud.get_or_create_provider_config(db, provider_id)
    
    # Update config with opt-in details
    updates = ProviderLoyaltyConfigUpdate(
        is_participating=True,
        point_multiplier=Decimal(str(multiplier)),
        participation_tier=request.participation_tier,
        billing_plan=request.billing_plan,
        monthly_subscription_fee=request.monthly_subscription_fee,
        billing_rate_per_point=request.billing_rate_per_point,
        monthly_point_budget=request.monthly_point_budget,
    )
    
    config = crud.update_provider_config(db, provider_id, updates)
    
    # Create provider-specific loyalty rule
    rule_created = False
    try:
        # Check if rule already exists
        existing_rules = crud.get_active_rules(
            db=db,
            provider_id=provider_id,
        )
        provider_specific_rule = next(
            (r for r in existing_rules if r.provider_id == provider_id),
            None
        )
        
        if not provider_specific_rule:
            # Create new provider-specific rule
            rule_data = LoyaltyRuleCreate(
                name=f"Provider {provider_id} Loyalty Rule",
                description=f"Provider-specific rule for {request.participation_tier} tier",
                provider_id=provider_id,
                base_points_per_kes=Decimal("0.01"),  # 1 point per KES 100
                multiplier=Decimal(str(multiplier)),
                is_active=True,
                priority=100,  # High priority for provider-specific rules
            )
            crud.create_rule(db, rule_data)
            rule_created = True
        else:
            # Update existing rule
            existing_rule = crud.get_rule(db, provider_specific_rule.id)
            if existing_rule:
                existing_rule.multiplier = Decimal(str(multiplier))
                existing_rule.is_active = True
                existing_rule.updated_at = datetime.now(timezone.utc)
                db.commit()
                rule_created = True
    except Exception as e:
        print(f"Warning: Failed to create/update provider rule: {e}")
    
    return ProviderOptInResponse(
        success=True,
        provider_id=provider_id,
        config=config,
        rule_created=rule_created,
        message=f"Provider opted into {request.participation_tier} tier with {multiplier}x multiplier"
    )


@router.post("/providers/{provider_id}/disable", response_model=ProviderLoyaltyConfig)
def disable_provider_participation(
    provider_id: str,
    db: Session = Depends(get_db)
):
    """Disable provider participation in loyalty program (opt-out)"""
    
    config = crud.get_provider_config(db, provider_id)
    if not config:
        raise HTTPException(status_code=404, detail="Provider config not found")
    
    # Update config
    updates = ProviderLoyaltyConfigUpdate(
        is_participating=False,
        participation_tier=None,
    )
    config = crud.update_provider_config(db, provider_id, updates)
    
    # Deactivate provider-specific rules
    try:
        existing_rules = crud.get_active_rules(db=db, provider_id=provider_id)
        for rule in existing_rules:
            if rule.provider_id == provider_id:
                db_rule = crud.get_rule(db, rule.id)
                if db_rule:
                    db_rule.is_active = False
                    db_rule.updated_at = datetime.now(timezone.utc)
        db.commit()
    except Exception as e:
        print(f"Warning: Failed to deactivate provider rules: {e}")
    
    return config


@router.put("/providers/{provider_id}/config", response_model=ProviderLoyaltyConfig)
def update_provider_config(
    provider_id: str,
    updates: ProviderLoyaltyConfigUpdate,
    db: Session = Depends(get_db)
):
    """Update provider loyalty configuration"""
    config = crud.update_provider_config(db, provider_id, updates)
    if not config:
        raise HTTPException(status_code=404, detail="Provider config not found")
    return config


@router.get("/providers/{provider_id}/usage", response_model=ProviderLoyaltyUsage)
def get_provider_usage(provider_id: str, db: Session = Depends(get_db)):
    """Get provider's loyalty program usage and statistics"""
    config = crud.get_or_create_provider_config(db, provider_id)
    
    # Calculate estimated monthly cost
    estimated_cost = None
    if config.billing_plan == "pay_per_point" and config.billing_rate_per_point:
        estimated_cost = Decimal(str(config.points_awarded_this_month)) * config.billing_rate_per_point
    elif config.billing_plan == "monthly_subscription" and config.monthly_subscription_fee:
        estimated_cost = Decimal(str(config.monthly_subscription_fee))
    
    # Calculate points remaining
    points_remaining = None
    if config.monthly_point_budget:
        points_remaining = config.monthly_point_budget - config.points_awarded_this_month
    
    return ProviderLoyaltyUsage(
        provider_id=config.provider_id,
        is_participating=config.is_participating,
        points_awarded_this_month=config.points_awarded_this_month,
        monthly_point_budget=config.monthly_point_budget,
        points_remaining=points_remaining,
        billing_plan=config.billing_plan,
        estimated_monthly_cost=estimated_cost,
        participation_tier=config.participation_tier,
        participation_enabled_at=config.participation_enabled_at,
    )


@router.get("/providers/participating", response_model=List[ProviderLoyaltyConfig])
def list_participating_providers(db: Session = Depends(get_db)):
    """List all providers participating in loyalty program"""
    return crud.list_participating_providers(db)


# ============ Voucher Validation (Provider) ============
@router.post("/vouchers/validate", response_model=VoucherValidateResponse)
def validate_voucher(request: VoucherValidateRequest, db: Session = Depends(get_db)):
    """Providers validate a voucher code (one-time use)."""
    ok, redemption, message = crud.validate_voucher(db, request.provider_id, request.voucher_code)
    if not ok or not redemption:
        return VoucherValidateResponse(success=False, redemption_id=None, reward_id=None, message=message)
    return VoucherValidateResponse(success=True, redemption_id=redemption.id, reward_id=redemption.reward_id, message=message)


# ============ Provider Sponsored Rewards ============
@router.post("/providers/{provider_id}/rewards/proposals", response_model=Reward)
def sponsor_reward(provider_id: str, request: ProviderSponsorRewardRequest, db: Session = Depends(get_db)):
    """Providers propose a sponsored reward. Created inactive; admin must approve/activate."""
    if request.provider_id != provider_id:
        raise HTTPException(status_code=400, detail="provider_id mismatch")
    try:
        reward = crud.create_provider_sponsored_reward(db, request)
        return reward
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
