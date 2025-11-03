# Loyalty Service

A microservice for managing loyalty points, rewards, and tier systems for the car platform.

## Features

- **Points Management**: Award and track loyalty points
- **Tier System**: Bronze → Silver → Gold → Platinum tiers with multipliers
- **Rules Engine**: Configurable rules for point calculation
- **Rewards Catalog**: Manage and redeem rewards
- **Transaction History**: Full audit trail
- **Idempotency**: Prevents duplicate point awards
- **Provider Opt‑In & Billing**: Providers choose participation tier and billing plan
- **Provider‑Funded Rewards**: Providers can sponsor or co‑fund specific rewards
- **Voucher Validation**: Providers can validate one‑time voucher codes

## Architecture

```
┌─────────────────┐
│ Booking Service │ ──┐
└─────────────────┘   │
                      ├─> POST /loyalty/points/award
┌─────────────────┐   │
│ Provider Logs   │ ──┘
└─────────────────┘
```

## API Endpoints

### Points
- `POST /loyalty/points/award` - Award points (called by booking service)
- `GET /loyalty/account/{user_id}` - Get user account
- `GET /loyalty/account/{user_id}/summary` - Get account summary

### Transactions
- `GET /loyalty/transactions/{user_id}` - Get transaction history

### Rewards
- `GET /loyalty/rewards` - List available rewards
- `POST /loyalty/redemptions` - Redeem a reward
 - `POST /loyalty/vouchers/validate` - Provider validates a voucher (one‑time use)

### Rules (Admin)
- `GET /loyalty/rules` - List all rules
- `POST /loyalty/rules` - Create new rule

### Provider Participation
- `GET /loyalty/providers/{provider_id}/config` - Get provider config
- `POST /loyalty/providers/{provider_id}/enable` - Opt‑in with tier/billing/budget
- `POST /loyalty/providers/{provider_id}/disable` - Opt‑out
- `GET /loyalty/providers/{provider_id}/usage` - Usage and estimated cost
- `POST /loyalty/providers/{provider_id}/rewards/proposals` - Provider proposes a sponsored reward (created inactive; admin approval required)

---

## Provider Billing vs Reward Funding

There are two separate money flows:

- Earn (Provider Billing): What providers pay to boost earning at their business
  - Set when provider opts in: participation tier and billing plan
  - Billing plans: `monthly_subscription`, `pay_per_point`, `free`
  - Optional `monthly_point_budget` with enforcement/capping

- Redeem (Reward Funding): Who pays when users redeem rewards
  - Default: Platform‑funded
  - Optional: Provider‑funded or co‑funded per reward
  - Admin controls funding on rewards; providers can submit proposals

This separation mirrors large platforms: providers pay for earning incentives; the platform governs the reward catalog. Sponsored rewards allow providers to fund specific redemption campaigns.

---

## Data Model Enhancements (Funding & Validation)

In `models/loyalty.py`:

- Reward (new fields)
  - `funding_model: platform | provider | co_funded`
  - `funding_provider_id: str | null`
  - `co_fund_split_pct: int | null` (provider share when co‑funded)

- LoyaltyRedemption (new fields)
  - `is_consumed: bool` (one‑time voucher use)
  - `validated_at: timestamp`, `validated_by_provider_id: str`
  - `settlement_status: pending|settled`, `settlement_provider_amount`, `settlement_platform_amount`

Migration scripts:
- `034_rename_metadata_to_extra_metadata.sql` – renames reserved columns
- `035_add_voucher_validation_and_funding.sql` – adds funding/validation/settlement columns and indexes

---

## Voucher Validation Endpoint

- `POST /loyalty/vouchers/validate`
  - Body: `{ provider_id, voucher_code }`
  - Validates voucher exists, is not consumed, within validity window
  - If reward is provider‑funded/co‑funded: enforces `funding_provider_id`
  - Marks redemption consumed and records settlement amounts

CRUD logic (excerpt):

```python
ok, redemption, message = crud.validate_voucher(db, provider_id, voucher_code)
```

Router (excerpt):

```python
@router.post("/vouchers/validate", response_model=VoucherValidateResponse)
def validate_voucher(request: VoucherValidateRequest, db: Session = Depends(get_db)):
    ok, redemption, message = crud.validate_voucher(db, request.provider_id, request.voucher_code)
    ...
```

---

## Provider‑Sponsored Rewards Workflow

1) Provider proposes a reward
- `POST /loyalty/providers/{provider_id}/rewards/proposals`
- Creates a Reward with `is_active=false` and funding fields preset

2) Admin reviews & approves
- `PUT /loyalty/rewards/{reward_id}` to set `is_active=true`
- Optionally adjusts `funding_model`, `funding_provider_id`, `co_fund_split_pct`

UI coverage
- Provider app: “Sponsor a Reward” form posts proposals
- Admin app: reward dialogs include funding controls

---

## Billing Logic (Earn Side)

Provider Opt‑In creates/updates `ProviderLoyaltyConfig` and a provider‑specific rule (priority=100). Billing and budget:

- Billing Plans
  - `monthly_subscription`: fixed monthly fee (`monthly_subscription_fee`)
  - `pay_per_point`: variable fee (`billing_rate_per_point` × awarded points)
  - `free`: platform‑funded earn (no provider charge)

- Budget Enforcement
  - Before awarding, if `points_awarded_this_month + points_to_award > monthly_point_budget`:
    - Award only the remaining; if none remaining, award 0 and return budget message

Router (budget excerpt):

```python
if provider_config.monthly_point_budget:
    if provider_config.points_awarded_this_month + points_to_award > provider_config.monthly_point_budget:
        remaining = provider_config.monthly_point_budget - provider_config.points_awarded_this_month
        points_to_award = max(0, remaining)
```

---

## Detailed Example: Fuel Station Flow

- Provider opts in (Premium 1.5x, monthly_subscription KES 3,000, budget 50,000 pts)
- User buys fuel for KES 10,000
  - Base: 10,000 × 0.01 = 100
  - Provider multiplier: 100 × 1.5 = 150
  - User tier (Gold 2.0x): 150 × 2.0 = 300 points
  - Budget check applies; monthly counter increments

- Admin creates fuel voucher reward:
  - `name=Fuel 200 KES Off`, `points_cost=2000`, `reward_type=voucher`
  - `funding_model=provider`, `funding_provider_id={fuel_station_id}`
  - Admin activates the reward

- User redeems, receives voucher code
  - Provider validates at checkout: `POST /loyalty/vouchers/validate`
  - Redemption marked consumed; settlement amounts recorded for provider vs platform

---

## Responsible Code (Pointers)

- Router: `backend/loyalty_service/routers/loyalty.py`
  - Points: `/points/award`
  - Provider usage/config: `/providers/...`
  - Rewards CRUD: `/rewards`
  - Redemptions: `/redemptions`
  - Voucher validation: `/vouchers/validate`

- CRUD: `backend/loyalty_service/crud/loyalty.py`
  - Rule selection & participation check: `get_active_rules`
  - Provider usage counters: `increment_provider_points_awarded`
  - Redemptions & vouchers: `create_redemption`, `validate_voucher`
  - Provider proposals: `create_provider_sponsored_reward`

- Models: `backend/loyalty_service/models/loyalty.py`
  - `Reward` funding fields
  - `LoyaltyRedemption` validation & settlement fields
  - `ProviderLoyaltyConfig` billing/budget fields

---

## Admin Approval Flow (Simple)

Use existing reward update endpoint to approve proposals:

```http
PUT /loyalty/rewards/{id}
{
  "is_active": true,
  "funding_model": "provider",
  "funding_provider_id": "{provider_uuid}",
  "co_fund_split_pct": 50
}
```

This publishes the sponsored reward to users.

---

## Points Calculation Flow (Consolidated)

End-to-end from service log to points award, with key code references.

1) Service log created (booking service)

```python
# backend/booking_service/routers/service_logs.py
if log.cost and log.user_id:
    loyalty_url = os.getenv("LOYALTY_SERVICE_URL", "http://loyalty-service:8009")
    body = {
        "user_id": log.user_id,
        "provider_id": log.provider_id,
        "service_id": log.service_id,
        "amount_spent": int(log.cost),
        "reference_type": "service_log",
        "reference_id": log.id,
    }
    client.post(f"{loyalty_url}/loyalty/points/award", json=body)
```

2) Loyalty awards points (router)

```python
# backend/loyalty_service/routers/loyalty.py
@router.post("/points/award", response_model=PointsAwardResponse)
def award_points(request: PointsAwardRequest, db: Session = Depends(get_db)):
    account = crud.get_or_create_account(db, request.user_id)
    calculator = PointsCalculator(db)
    calc = calculator.calculate_points(
        amount_spent=request.amount_spent,
        user_id=request.user_id,
        provider_id=request.provider_id,
        service_id=request.service_id,
        metadata={"reference_type": request.reference_type, "reference_id": request.reference_id},
    )
    points_to_award = calc["points"]
```

3) Rules selected by priority with participation check (CRUD)

```python
# backend/loyalty_service/crud/loyalty.py
def get_active_rules(db: Session, provider_id: Optional[str] = None, ...):
    query = db.query(LoyaltyRule).filter(LoyaltyRule.is_active == True)
    if provider_id:
        provider_config = get_provider_config(db, provider_id)
        if provider_config and not provider_config.is_participating:
            query = query.filter(LoyaltyRule.provider_id != provider_id)
        else:
            query = query.filter(or_(LoyaltyRule.provider_id == provider_id, LoyaltyRule.provider_id.is_(None)))
    return query.order_by(desc(LoyaltyRule.priority)).all()
```

4) Points calculated (provider × user multipliers) (service)

```python
# backend/loyalty_service/services/points_calculator.py
base_points = float(amount_spent) * float(rule.base_points_per_kes)
points = base_points * float(rule.multiplier)  # provider tier
tier_multiplier = DEFAULT_TIER_MULTIPLIERS.get(user_tier, 1.0)
points = int(round(points * tier_multiplier))
```

5) Budget cap enforced (router)

```python
if provider_config and provider_config.monthly_point_budget:
    if provider_config.points_awarded_this_month + points_to_award > provider_config.monthly_point_budget:
        remaining = provider_config.monthly_point_budget - provider_config.points_awarded_this_month
        if remaining > 0:
            points_to_award = remaining
        else:
            return PointsAwardResponse(success=False, ...)
```

6) Transaction created and provider usage tracked (CRUD)

```python
transaction = crud.create_transaction(..., points_delta=points_to_award, transaction_type="earned", ...)
if request.provider_id and points_to_award > 0:
    crud.increment_provider_points_awarded(db, request.provider_id, points_to_award)
```

Result: user balance updated, monthly provider usage counted for billing.

## Default Points Calculation

- **Base Rate**: 1 point per KES 100 (0.01 points/KES)
- **Tier Multipliers**:
  - Bronze: 1.0x
  - Silver: 1.5x
  - Gold: 2.0x
  - Platinum: 2.5x

## Tier Thresholds

- **Bronze**: 0 points
- **Silver**: 1,000 points
- **Gold**: 5,000 points
- **Platinum**: 20,000 points

## Database Schema

- `loyalty.loyalty_accounts` - User accounts
- `loyalty.loyalty_transactions` - All point transactions
- `loyalty.loyalty_rules` - Configurable earning rules
- `loyalty.rewards` - Available rewards
- `loyalty.loyalty_redemptions` - Redemption history

## Environment Variables

```bash
DATABASE_URL=postgresql://...
LOYALTY_SERVICE_URL=http://loyalty-service:8008
PORT=8008
```

## Running the Service

```bash
# Install dependencies
pip install -r requirements.txt

# Run migrations (one-time)
psql $DATABASE_URL -f migrations/010_create_loyalty_schema.sql

# Start service
uvicorn main:app --host 0.0.0.0 --port 8008
```

## Integration

The loyalty service is automatically called by the booking service when:
1. A service log is created with a cost
2. Bulk service logs are created

Points are awarded asynchronously (fire-and-forget) so service logging isn't blocked.

## Example: Award Points

```python
POST /loyalty/points/award
{
    "user_id": 123,
    "provider_id": "uuid",
    "service_id": "uuid",
    "amount_spent": 5000,
    "reference_type": "service_log",
    "reference_id": "log-uuid"
}

Response:
{
    "success": true,
    "account_id": "account-uuid",
    "points_awarded": 50,
    "points_balance": 1050,
    "transaction_id": "transaction-uuid",
    "message": "Awarded 50 points. Tier upgraded to silver!"
}
```

