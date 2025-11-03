# backend/loyalty_service/crud/loyalty.py
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc, func
from typing import Optional, List
from datetime import datetime, timedelta, timezone
from models.loyalty import (
    LoyaltyAccount,
    LoyaltyTransaction,
    LoyaltyRule,
    Reward,
    LoyaltyRedemption,
    ProviderLoyaltyConfig,
)
from schemas.loyalty import (
    LoyaltyAccountCreate,
    LoyaltyTransactionCreate,
    LoyaltyRuleCreate,
    LoyaltyRuleUpdate,
    RewardCreate,
    RewardUpdate,
    RedemptionCreate,
    ProviderLoyaltyConfigCreate,
    ProviderLoyaltyConfigUpdate,
    VoucherValidateRequest,
    ProviderSponsorRewardRequest,
)


# ============ Account CRUD ============
def get_or_create_account(db: Session, user_id: int) -> LoyaltyAccount:
    """Get existing account or create new one"""
    account = db.query(LoyaltyAccount).filter(LoyaltyAccount.user_id == user_id).first()
    if not account:
        account = LoyaltyAccount(user_id=user_id)
        db.add(account)
        db.commit()
        db.refresh(account)
    return account


def get_account(db: Session, user_id: int) -> Optional[LoyaltyAccount]:
    """Get account by user_id"""
    return db.query(LoyaltyAccount).filter(LoyaltyAccount.user_id == user_id).first()


def get_account_by_id(db: Session, account_id: str) -> Optional[LoyaltyAccount]:
    """Get account by account_id"""
    return db.query(LoyaltyAccount).filter(LoyaltyAccount.id == account_id).first()


def update_account_tier(db: Session, account_id: str, new_tier: str):
    """Update account tier"""
    account = get_account_by_id(db, account_id)
    if account:
        account.tier = new_tier
        account.updated_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(account)
    return account


# ============ Transaction CRUD ============
def create_transaction(
    db: Session,
    account_id: str,
    points_delta: int,
    transaction_type: str,
    reference_type: Optional[str] = None,
    reference_id: Optional[str] = None,
    idempotency_key: Optional[str] = None,
    **kwargs
) -> LoyaltyTransaction:
    """Create a transaction and update account balance"""
    
    # Check idempotency if key provided
    if idempotency_key:
        existing = db.query(LoyaltyTransaction).filter(
            LoyaltyTransaction.idempotency_key == idempotency_key
        ).first()
        if existing:
            return existing  # Idempotent - return existing transaction
    
    # Get account and update balance
    account = get_account_by_id(db, account_id)
    if not account:
        raise ValueError(f"Account {account_id} not found")
    
    # Calculate new balance
    new_balance = account.points_balance + points_delta
    if new_balance < 0:
        raise ValueError(f"Insufficient points. Balance: {account.points_balance}, Requested: {abs(points_delta)}")
    
    # Create transaction
    transaction = LoyaltyTransaction(
        account_id=account_id,
        points_delta=points_delta,
        points_balance_after=new_balance,
        transaction_type=transaction_type,
        reference_type=reference_type,
        reference_id=reference_id,
        idempotency_key=idempotency_key,
        **kwargs
    )
    db.add(transaction)
    
    # Update account
    account.points_balance = new_balance
    if points_delta > 0:
        account.lifetime_points_earned += points_delta
    else:
        account.lifetime_points_spent += abs(points_delta)
    account.last_activity_at = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(transaction)
    db.refresh(account)
    
    return transaction


def get_transactions(
    db: Session,
    account_id: Optional[str] = None,
    user_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0
) -> List[LoyaltyTransaction]:
    """Get transactions for account or user"""
    query = db.query(LoyaltyTransaction)
    
    if account_id:
        query = query.filter(LoyaltyTransaction.account_id == account_id)
    elif user_id:
        account = get_account(db, user_id)
        if account:
            query = query.filter(LoyaltyTransaction.account_id == account.id)
        else:
            return []
    
    return query.order_by(desc(LoyaltyTransaction.created_at)).offset(offset).limit(limit).all()


def check_idempotency(db: Session, idempotency_key: str) -> Optional[LoyaltyTransaction]:
    """Check if transaction with idempotency_key already exists"""
    return db.query(LoyaltyTransaction).filter(
        LoyaltyTransaction.idempotency_key == idempotency_key
    ).first()


# ============ Rule CRUD ============
def create_rule(db: Session, rule: LoyaltyRuleCreate) -> LoyaltyRule:
    """Create a new loyalty rule"""
    db_rule = LoyaltyRule(**rule.dict())
    db.add(db_rule)
    db.commit()
    db.refresh(db_rule)
    return db_rule


def get_active_rules(
    db: Session,
    provider_id: Optional[str] = None,
    provider_category_id: Optional[int] = None,
    service_id: Optional[str] = None,
    service_category_id: Optional[int] = None
) -> List[LoyaltyRule]:
    """Get active rules matching criteria, ordered by priority"""
    query = db.query(LoyaltyRule).filter(LoyaltyRule.is_active == True)
    
    # Apply filters
    if provider_id:
        # Check if provider is participating before including their specific rules
        provider_config = get_provider_config(db, provider_id)
        if provider_config and not provider_config.is_participating:
            # Provider opted out, exclude their provider-specific rules
            query = query.filter(LoyaltyRule.provider_id != provider_id)
        else:
            # Provider is participating or no config exists, include their rules
            query = query.filter(
                or_(
                    LoyaltyRule.provider_id == provider_id,
                    LoyaltyRule.provider_id.is_(None)
                )
            )
    
    if provider_category_id:
        query = query.filter(
            or_(
                LoyaltyRule.provider_category_id == provider_category_id,
                LoyaltyRule.provider_category_id.is_(None)
            )
        )
    
    if service_id:
        query = query.filter(
            or_(
                LoyaltyRule.service_id == service_id,
                LoyaltyRule.service_id.is_(None)
            )
        )
    
    if service_category_id:
        query = query.filter(
            or_(
                LoyaltyRule.service_category_id == service_category_id,
                LoyaltyRule.service_category_id.is_(None)
            )
        )
    
    # Date validity check
    now = datetime.now(timezone.utc)
    query = query.filter(
        or_(
            LoyaltyRule.valid_from.is_(None),
            LoyaltyRule.valid_from <= now
        )
    ).filter(
        or_(
            LoyaltyRule.valid_until.is_(None),
            LoyaltyRule.valid_until >= now
        )
    )
    
    # Order by priority (higher first)
    return query.order_by(desc(LoyaltyRule.priority)).all()


def get_rule(db: Session, rule_id: str) -> Optional[LoyaltyRule]:
    """Get rule by ID"""
    return db.query(LoyaltyRule).filter(LoyaltyRule.id == rule_id).first()


def list_rules(db: Session, is_active: Optional[bool] = None) -> List[LoyaltyRule]:
    """List all rules"""
    query = db.query(LoyaltyRule)
    if is_active is not None:
        query = query.filter(LoyaltyRule.is_active == is_active)
    return query.order_by(desc(LoyaltyRule.priority)).all()


def update_rule(db: Session, rule_id: str, rule_update: LoyaltyRuleUpdate) -> Optional[LoyaltyRule]:
    """Update a loyalty rule"""
    rule = get_rule(db, rule_id)
    if not rule:
        return None
    
    updates = rule_update.dict(exclude_unset=True)
    for key, value in updates.items():
        setattr(rule, key, value)
    
    rule.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(rule)
    return rule


def delete_rule(db: Session, rule_id: str) -> bool:
    """Delete a loyalty rule"""
    rule = get_rule(db, rule_id)
    if not rule:
        return False
    
    db.delete(rule)
    db.commit()
    return True


# ============ Reward CRUD ============
def create_reward(db: Session, reward: RewardCreate) -> Reward:
    """Create a new reward"""
    db_reward = Reward(**reward.dict())
    db.add(db_reward)
    db.commit()
    db.refresh(db_reward)
    return db_reward


def get_reward(db: Session, reward_id: str) -> Optional[Reward]:
    """Get reward by ID"""
    return db.query(Reward).filter(Reward.id == reward_id).first()


def list_rewards(db: Session, is_active: Optional[bool] = None) -> List[Reward]:
    """List rewards, optionally filter by active flag (admin view)."""
    query = db.query(Reward)
    if is_active is not None:
        query = query.filter(Reward.is_active == is_active)
    return query.order_by(Reward.points_cost).all()


def list_available_rewards(
    db: Session,
    min_tier: Optional[str] = None,
    limit: int = 50
) -> List[Reward]:
    """Get available rewards for user tier"""
    query = db.query(Reward).filter(Reward.is_active == True)
    
    # Tier requirement
    if min_tier:
        tier_order = ["bronze", "silver", "gold", "platinum"]
        if min_tier in tier_order:
            min_index = tier_order.index(min_tier)
            allowed_tiers = tier_order[min_index:]
            query = query.filter(
                or_(
                    Reward.min_tier_required.is_(None),
                    Reward.min_tier_required.in_(allowed_tiers)
                )
            )
    
    # Availability check
    now = datetime.now(timezone.utc)
    query = query.filter(
        or_(
            Reward.valid_from.is_(None),
            Reward.valid_from <= now
        )
    ).filter(
        or_(
            Reward.valid_until.is_(None),
            Reward.valid_until >= now
        )
    )
    
    # Availability count
    query = query.filter(
        or_(
            Reward.total_available.is_(None),
            Reward.total_redeemed < Reward.total_available
        )
    )
    
    return query.order_by(Reward.points_cost).limit(limit).all()


def update_reward(db: Session, reward_id: str, reward_update: RewardUpdate) -> Optional[Reward]:
    """Update a reward"""
    reward = get_reward(db, reward_id)
    if not reward:
        return None
    
    updates = reward_update.dict(exclude_unset=True)
    for key, value in updates.items():
        setattr(reward, key, value)
    
    reward.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(reward)
    return reward


def delete_reward(db: Session, reward_id: str) -> bool:
    """Delete a reward"""
    reward = get_reward(db, reward_id)
    if not reward:
        return False
    
    db.delete(reward)
    db.commit()
    return True


def create_provider_sponsored_reward(db: Session, req: ProviderSponsorRewardRequest) -> Reward:
    """Create a provider-sponsored reward as inactive pending admin approval."""
    funding_model = req.funding_model
    if funding_model not in ("provider", "co_funded"):
        raise ValueError("Invalid funding_model for provider sponsorship")

    reward = Reward(
        name=req.name,
        description=req.description,
        reward_type=req.reward_type,
        points_cost=req.points_cost,
        discount_percentage=req.discount_percentage,
        discount_amount=req.discount_amount,
        cashback_amount=req.cashback_amount,
        voucher_code_template=req.voucher_code_template,
        is_active=False,  # Pending admin approval
        total_available=req.total_available,
        max_redemptions_per_user=None,
        min_tier_required=req.min_tier_required,
        valid_from=req.valid_from,
        valid_until=req.valid_until,
        funding_model=funding_model,
        funding_provider_id=req.provider_id,
        co_fund_split_pct=req.co_fund_split_pct,
    )
    db.add(reward)
    db.commit()
    db.refresh(reward)
    return reward


# ============ Redemption CRUD ============
def create_redemption(
    db: Session,
    account_id: str,
    reward_id: str
) -> LoyaltyRedemption:
    """Create a redemption (spend points to get reward)"""
    account = get_account_by_id(db, account_id)
    if not account:
        raise ValueError("Account not found")
    
    reward = get_reward(db, reward_id)
    if not reward:
        raise ValueError("Reward not found")
    
    if not reward.is_active:
        raise ValueError("Reward is not active")
    
    # Check availability
    if reward.total_available and reward.total_redeemed >= reward.total_available:
        raise ValueError("Reward is out of stock")
    
    # Check tier requirement
    if reward.min_tier_required:
        tier_order = ["bronze", "silver", "gold", "platinum"]
        if account.tier not in tier_order:
            raise ValueError("Account tier not recognized")
        if tier_order.index(account.tier) < tier_order.index(reward.min_tier_required):
            raise ValueError(f"Requires {reward.min_tier_required} tier or higher")
    
    # Check balance
    if account.points_balance < reward.points_cost:
        raise ValueError("Insufficient points")
    
    # Check user redemption limit
    if reward.max_redemptions_per_user:
        user_redemptions = db.query(LoyaltyRedemption).filter(
            and_(
                LoyaltyRedemption.account_id == account_id,
                LoyaltyRedemption.reward_id == reward_id,
                LoyaltyRedemption.status.in_(["pending", "fulfilled"])
            )
        ).count()
        if user_redemptions >= reward.max_redemptions_per_user:
            raise ValueError("User redemption limit reached")
    
    # Generate voucher code if needed
    voucher_code = None
    if reward.reward_type == "voucher" and reward.voucher_code_template:
        # Add a short random suffix to avoid collisions within the same second
        import uuid
        random_suffix = uuid.uuid4().hex[:6].upper()
        timestamp = datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')
        voucher_code = f"{reward.voucher_code_template}-{timestamp}-{random_suffix}"
    
    # Create redemption record
    redemption = LoyaltyRedemption(
        account_id=account_id,
        reward_id=reward_id,
        points_spent=reward.points_cost,
        status="pending",
        reward_name=reward.name,
        reward_type=reward.reward_type,
        reward_value={
            "discount_percentage": float(reward.discount_percentage) if reward.discount_percentage else None,
            "discount_amount": reward.discount_amount,
            "cashback_amount": reward.cashback_amount,
        },
        voucher_code=voucher_code,
    )
    db.add(redemption)
    
    # Update reward redemption count
    reward.total_redeemed += 1
    
    # Create transaction for points spent
    create_transaction(
        db=db,
        account_id=account_id,
        points_delta=-reward.points_cost,
        transaction_type="redeemed",
        transaction_reason=f"Redeemed: {reward.name}",
        reference_type="redemption",
        reference_id=redemption.id,
        extra_metadata={
            "voucher_code": voucher_code,
            "reward_id": reward_id,
        },
    )
    
    db.commit()
    db.refresh(redemption)
    
    return redemption


def get_redemption(db: Session, redemption_id: str) -> Optional[LoyaltyRedemption]:
    """Get redemption by ID"""
    return db.query(LoyaltyRedemption).filter(LoyaltyRedemption.id == redemption_id).first()


def list_user_redemptions(
    db: Session,
    account_id: str,
    limit: int = 50
) -> List[LoyaltyRedemption]:
    """Get user's redemptions"""
    return db.query(LoyaltyRedemption).filter(
        LoyaltyRedemption.account_id == account_id
    ).order_by(desc(LoyaltyRedemption.created_at)).limit(limit).all()


# ============ Expiration Handling ============
def expire_points(db: Session, days_old: int = 365):
    """Expire points older than specified days"""
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=days_old)
    
    # Find unexpired transactions with expiration dates before cutoff
    transactions = db.query(LoyaltyTransaction).filter(
        and_(
            LoyaltyTransaction.is_expired == False,
            LoyaltyTransaction.expires_at.isnot(None),
            LoyaltyTransaction.expires_at < cutoff_date,
            LoyaltyTransaction.points_delta > 0  # Only expire earned points
        )
    ).all()
    
    expired_count = 0
    for transaction in transactions:
        if transaction.points_delta > 0:  # Only expire positive (earned) points
            account = get_account_by_id(db, transaction.account_id)
            if account and account.points_balance >= transaction.points_delta:
                # Create expiration transaction
                create_transaction(
                    db=db,
                    account_id=transaction.account_id,
                    points_delta=-transaction.points_delta,
                    transaction_type="expired",
                    transaction_reason=f"Points expired from transaction {transaction.id}",
                    reference_type="expiration",
                    reference_id=transaction.id,
                )
                transaction.is_expired = True
                expired_count += 1
    
    db.commit()
    return expired_count


# ============ Voucher Validation (Provider) ============
def validate_voucher(db: Session, provider_id: str, voucher_code: str) -> (bool, Optional[LoyaltyRedemption], str):
    """Validate and consume a voucher by providers. One-time use."""
    # Find pending redemption with matching voucher and unconsumed
    redemption = db.query(LoyaltyRedemption).filter(
        and_(
            LoyaltyRedemption.voucher_code == voucher_code,
            LoyaltyRedemption.is_consumed == False,
            LoyaltyRedemption.status.in_(["pending", "fulfilled"])  # still usable
        )
    ).first()
    if not redemption:
        return False, None, "Invalid or already used voucher"

    reward = get_reward(db, redemption.reward_id)
    if not reward or reward.reward_type != "voucher":
        return False, None, "Voucher not found or not a voucher-type reward"

    # Validity window
    now = datetime.now(timezone.utc)
    if reward.valid_from and reward.valid_from > now:
        return False, None, "Voucher not yet valid"
    if reward.valid_until and reward.valid_until < now:
        return False, None, "Voucher expired"

    # Funding constraints: if provider-funded or co-funded, provider must match
    if reward.funding_model in ("provider", "co_funded"):
        if not reward.funding_provider_id or reward.funding_provider_id != provider_id:
            return False, None, "Voucher is not funded by this provider"

    # Consume voucher
    redemption.is_consumed = True
    redemption.validated_at = now
    redemption.validated_by_provider_id = provider_id
    redemption.status = "fulfilled"

    # Settlement amounts (basic placeholder)
    provider_amount = 0
    platform_amount = 0
    if reward.funding_model == "provider":
        provider_amount = reward.discount_amount or 0
    elif reward.funding_model == "co_funded":
        pct = reward.co_fund_split_pct or 0
        base = (reward.discount_amount or 0)
        provider_amount = int(base * pct / 100)
        platform_amount = base - provider_amount
    else:
        platform_amount = reward.discount_amount or 0

    redemption.settlement_provider_amount = provider_amount
    redemption.settlement_platform_amount = platform_amount
    redemption.settlement_status = "pending"

    db.commit()
    db.refresh(redemption)
    return True, redemption, "Voucher validated successfully"


# ============ Provider Loyalty Config CRUD ============
def get_provider_config(db: Session, provider_id: str) -> Optional[ProviderLoyaltyConfig]:
    """Get provider loyalty configuration"""
    return db.query(ProviderLoyaltyConfig).filter(
        ProviderLoyaltyConfig.provider_id == provider_id
    ).first()


def get_or_create_provider_config(db: Session, provider_id: str) -> ProviderLoyaltyConfig:
    """Get existing config or create default one"""
    config = get_provider_config(db, provider_id)
    if not config:
        config = ProviderLoyaltyConfig(
            provider_id=provider_id,
            is_participating=False,
            point_multiplier=1.0,
            billing_plan="free",
        )
        db.add(config)
        db.commit()
        db.refresh(config)
    return config


def create_provider_config(db: Session, config_data: ProviderLoyaltyConfigCreate) -> ProviderLoyaltyConfig:
    """Create provider loyalty configuration"""
    config = ProviderLoyaltyConfig(**config_data.dict())
    db.add(config)
    db.commit()
    db.refresh(config)
    return config


def update_provider_config(
    db: Session,
    provider_id: str,
    updates: ProviderLoyaltyConfigUpdate
) -> Optional[ProviderLoyaltyConfig]:
    """Update provider loyalty configuration"""
    config = get_provider_config(db, provider_id)
    if not config:
        return None
    
    updates_dict = updates.dict(exclude_unset=True)
    
    # Track when participation is enabled
    if "is_participating" in updates_dict:
        if updates_dict["is_participating"] and not config.is_participating:
            config.participation_enabled_at = datetime.now(timezone.utc)
        elif not updates_dict["is_participating"]:
            config.participation_enabled_at = None
    
    # Reset monthly counter if month changed
    if "current_month_start" not in updates_dict or updates_dict.get("current_month_start") is None:
        now = datetime.now(timezone.utc)
        current_month_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
        if config.current_month_start is None or config.current_month_start < current_month_start:
            config.points_awarded_this_month = 0
            config.current_month_start = current_month_start
    
    for key, value in updates_dict.items():
        setattr(config, key, value)
    
    config.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(config)
    return config


def increment_provider_points_awarded(db: Session, provider_id: str, points: int):
    """Increment monthly points counter for provider"""
    config = get_or_create_provider_config(db, provider_id)
    
    # Check if month has changed
    now = datetime.now(timezone.utc)
    current_month_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
    
    if config.current_month_start is None or config.current_month_start < current_month_start:
        # New month, reset counter
        config.points_awarded_this_month = points
        config.current_month_start = current_month_start
    else:
        config.points_awarded_this_month += points
    
    db.commit()


def list_participating_providers(db: Session) -> List[ProviderLoyaltyConfig]:
    """Get all providers participating in loyalty program"""
    return db.query(ProviderLoyaltyConfig).filter(
        ProviderLoyaltyConfig.is_participating == True
    ).all()


# ============ Tier Multiplier Mapping ============
TIER_MULTIPLIERS = {
    "basic": 1.0,
    "premium": 1.5,
    "elite": 2.0,
}

def get_multiplier_for_tier(tier: str) -> float:
    """Get point multiplier for a given tier"""
    return TIER_MULTIPLIERS.get(tier.lower(), 1.0)

