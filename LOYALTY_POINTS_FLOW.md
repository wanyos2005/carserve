# Loyalty Points Calculation Flow

## Overview
This document explains how the system calculates and awards loyalty points when a provider has opted into the loyalty program.

---

## 🔄 Complete Flow: From Service Log to Points Awarded

### Step 1: Service Log Created
**Location:** `backend/booking_service/routers/service_logs.py:23-68`

When a service log is created (e.g., car owner uses a provider's service):
```python
@router.post("/", response_model=ServiceLog)
def create_log(payload: ServiceLogCreate, db: Session = Depends(get_db)):
    log = create_service_log(db, payload)
    
    # Award loyalty points if cost present
    if log.cost and log.user_id:
        loyalty_url = "http://loyalty-service:8009"
        body = {
            "user_id": log.user_id,
            "provider_id": log.provider_id,  # ← Provider ID passed here
            "service_id": log.service_id,
            "amount_spent": int(log.cost),
            "reference_type": "service_log",
            "reference_id": log.id,
        }
        client.post(f"{loyalty_url}/loyalty/points/award", json=body)
```

**Key Data Passed:**
- `provider_id`: The provider who performed the service
- `amount_spent`: Cost of the service (in KES)
- `service_id`: Type of service
- `user_id`: Car owner who paid

---

### Step 2: Loyalty Service Receives Award Request
**Location:** `backend/loyalty_service/routers/loyalty.py:79-211`

The `/loyalty/points/award` endpoint receives the request:

```python
@router.post("/points/award", response_model=PointsAwardResponse)
def award_points(request: PointsAwardRequest, db: Session = Depends(get_db)):
    # 1. Generate idempotency key (prevent duplicates)
    # 2. Get or create user's loyalty account
    account = crud.get_or_create_account(db, request.user_id)
    
    # 3. Calculate points using rules engine
    calculator = PointsCalculator(db)
    calculation_result = calculator.calculate_points(
        amount_spent=request.amount_spent,
        user_id=request.user_id,
        provider_id=request.provider_id,  # ← Used to find provider-specific rules
        service_id=request.service_id,
        metadata={"reference_type": request.reference_type, "reference_id": request.reference_id},
    )
    
    points_to_award = calculation_result["points"]
```

---

### Step 3: Points Calculator Finds Matching Rules
**Location:** `backend/loyalty_service/services/points_calculator.py:23-60`

The calculator looks for applicable rules based on context:

```python
def calculate_points(
    self,
    amount_spent: int,
    user_id: int,
    provider_id: Optional[str] = None,
    ...
) -> Dict[str, Any]:
    # Get applicable rules (filtered by provider_id, service_id, etc.)
    rules = crud.get_active_rules(
        db=self.db,
        provider_id=provider_id,  # ← Filters for provider-specific rules
        provider_category_id=provider_category_id,
        service_id=service_id,
        service_category_id=service_category_id,
    )
    
    # Find first matching rule (sorted by priority - highest first)
    for rule in rules:
        if self._rule_matches(rule, amount_spent, metadata):
            return self._calculate_with_rule(rule, amount_spent, user_id)
```

**Rule Priority:**
1. **Provider-specific rules** (created when provider opts in) - **Priority 100** (highest)
2. Service-specific rules
3. Category-specific rules
4. Default rule - **Priority 0** (lowest)

---

### Step 4: Rule Matching Logic
**Location:** `backend/loyalty_service/crud/loyalty.py:313-351`

The `get_active_rules` function filters rules:

```python
def get_active_rules(
    db: Session,
    provider_id: Optional[str] = None,
    provider_category_id: Optional[int] = None,
    service_id: Optional[str] = None,
    service_category_id: Optional[int] = None,
) -> List[LoyaltyRule]:
    query = db.query(LoyaltyRule).filter(LoyaltyRule.is_active == True)
    
    # Filter by provider_id if provided
    if provider_id:
        query = query.filter(
            or_(
                LoyaltyRule.provider_id == provider_id,  # ← Provider-specific rule
                LoyaltyRule.provider_id.is_(None)        # ← General rule
            )
        )
```

**Rule Matching Priority:**
1. **Exact match:** `provider_id` matches → Provider-specific rule wins
2. **General rule:** `provider_id` is NULL → Falls back to default

**Example:**
- Provider A opts in → Creates rule with `provider_id="provider-a"`, `priority=100`
- Default rule has `provider_id=None`, `priority=0`
- When transaction uses Provider A:
  - ✅ Matches Provider A's rule (priority 100) → Used
  - ❌ Default rule (priority 0) → Ignored (lower priority)

---

### Step 5: Points Calculation with Provider Tier
**Location:** `backend/loyalty_service/services/points_calculator.py:100-144`

When a provider-specific rule is found, points are calculated:

```python
def _calculate_with_rule(
    self,
    rule: Any,  # ← This is the provider-specific rule with multiplier
    amount_spent: int,
    user_id: int
) -> Dict[str, Any]:
    # Get user tier
    account = crud.get_account(self.db, user_id)
    user_tier = account.tier if account else "bronze"
    
    # Step 1: Base points (KES → points)
    base_points = float(amount_spent) * float(rule.base_points_per_kes)
    # Example: 10,000 KES × 0.01 = 100 points
    
    # Step 2: Apply provider's tier multiplier (from opt-in)
    points = base_points * float(rule.multiplier)
    # Example: 100 × 1.5 (Premium tier) = 150 points
    
    # Step 3: Apply user's loyalty tier multiplier
    tier_multiplier = self.DEFAULT_TIER_MULTIPLIERS.get(user_tier, 1.0)
    # Example: Gold tier = 2.0x
    points = points * tier_multiplier
    # Example: 150 × 2.0 = 300 points FINAL
    
    return {
        "points": points,
        "rule_id": rule.id,
        "rule_name": rule.name,
        ...
    }
```

**Complete Example:**
```
Service cost: KES 10,000
Provider: Premium tier (1.5x multiplier) ← From opt-in
User: Gold tier (2.0x multiplier) ← From lifetime points

Calculation:
1. Base: 10,000 × 0.01 = 100 points 
2. Provider tier: 100 × 1.5 = 150 points
3. User tier: 150 × 2.0 = 300 points FINAL ✅
```

---

### Step 6: Provider Budget Check
**Location:** `backend/loyalty_service/routers/loyalty.py:152-172`

Before awarding points, system checks provider's monthly budget:

```python
# Check provider participation and budget limits
if request.provider_id:
    provider_config = crud.get_provider_config(db, request.provider_id)
    
    if provider_config and provider_config.monthly_point_budget:
        if provider_config.points_awarded_this_month + points_to_award > provider_config.monthly_point_budget:
            # Budget exceeded, award only remaining points
            remaining = provider_config.monthly_point_budget - provider_config.points_awarded_this_month
            if remaining > 0:
                points_to_award = remaining
            else:
                return PointsAwardResponse(
                    success=False,
                    message="Provider monthly point budget exceeded",
                )
```

**Budget Example:**
- Provider sets monthly budget: 50,000 points
- Already awarded this month: 48,000 points
- New transaction calculates: 5,000 points
- **Result:** Only 2,000 points awarded (remaining budget)
- Points over budget: **NOT awarded** ❌

---

### Step 7: Points Awarded and Provider Tracking
**Location:** `backend/loyalty_service/routers/loyalty.py:174-208`

Finally, points are awarded and provider usage is tracked:

```python
# Create transaction
transaction = crud.create_transaction(
    db=db,
    account_id=account.id,
    points_delta=points_to_award,
    transaction_type="earned",
    provider_id=request.provider_id,
    amount_spent=request.amount_spent,
)

# Track points awarded to provider for billing
if request.provider_id and points_to_award > 0:
    crud.increment_provider_points_awarded(db, request.provider_id, points_to_award)
    # ← Updates provider_config.points_awarded_this_month
```

---

## 🎯 Key Components

### 1. Provider Opt-In Creates Rule
**Location:** `backend/loyalty_service/routers/loyalty.py:409-434`

When provider opts in, system creates a provider-specific rule:

```python
# Create provider-specific loyalty rule
rule_data = LoyaltyRuleCreate(
    name=f"Provider {provider_id} Loyalty Rule",
    provider_id=provider_id,  # ← Links rule to provider
    base_points_per_kes=Decimal("0.01"),
    multiplier=Decimal(str(multiplier)),  # ← 1.0x, 1.5x, or 2.0x
    is_active=True,
    priority=100,  # ← Highest priority
)
crud.create_rule(db, rule_data)
```

**Rule Created:**
- `provider_id`: Provider's UUID
- `multiplier`: Based on tier (Basic=1.0, Premium=1.5, Elite=2.0)
- `priority`: 100 (always selected first when provider_id matches)

---

### 2. Rule Selection Priority
**Location:** `backend/loyalty_service/crud/loyalty.py:313-351`

Rules are sorted by priority (descending):
- **Priority 100:** Provider-specific rules (when provider opted in)
- **Priority 50:** Service-specific rules
- **Priority 10:** Category-specific rules
- **Priority 0:** Default rule (fallback)

**Rule Matching:**
1. Filter active rules
2. Match by `provider_id` if provided
3. Sort by `priority` (highest first)
4. Use first matching rule

---

### 3. Provider Participation Status Check
**IMPORTANT:** The system checks if provider is participating before awarding points.

**Location:** In `award_points` endpoint, before calculation:
```python
# Currently: No explicit check, but rule won't exist if provider didn't opt in
```

**Gap Identified:** System should explicitly check `is_participating` flag before calculating points.

---

## 🐛 Identified Gap

### **Issue: No Explicit Participation Check**

**Current Behavior:**
- Provider opts in → Creates rule with `provider_id`
- Provider opts out → Deactivates rule (`is_active=False`)
- **BUT:** If provider opts out but rule still exists, points might still be awarded

**Recommendation:**
Add explicit check in `award_points`:

```python
@router.post("/points/award", response_model=PointsAwardResponse)
def award_points(request: PointsAwardRequest, db: Session = Depends(get_db)):
    # ...
    
    # Check if provider is participating
    if request.provider_id:
        provider_config = crud.get_provider_config(db, request.provider_id)
        if not provider_config or not provider_config.is_participating:
            # Provider not participating, use default rule
            # (Still award points, but without provider multiplier)
            pass  # Continue with calculation using default rule
```

**OR** Filter out inactive provider rules in `get_active_rules`:

```python
def get_active_rules(...):
    # ...
    # If provider_id provided, check if provider is participating
    if provider_id:
        provider_config = get_provider_config(db, provider_id)
        if provider_config and not provider_config.is_participating:
            # Exclude provider-specific rules if not participating
            query = query.filter(LoyaltyRule.provider_id != provider_id)
```

---

## 📊 Visual Flow

```
Service Log Created
    │
    ├─> Amount: KES 10,000
    ├─> Provider ID: "9a8b23c3-..."
    └─> User ID: 123
         │
         ▼
Booking Service Calls Loyalty Service
    POST /loyalty/points/award
    {
        "user_id": 123,
        "provider_id": "9a8b23c3-...",
        "amount_spent": 10000,
        "service_id": "oil-change"
    }
         │
         ▼
Points Calculator
    ├─> get_active_rules(provider_id="9a8b23c3-...")
    │   └─> Finds: Provider rule (priority=100, multiplier=1.5)
    │
    ├─> Calculate:
    │   ├─> Base: 10,000 × 0.01 = 100 points
    │   ├─> Provider tier: 100 × 1.5 = 150 points
    │   └─> User tier (Gold): 150 × 2.0 = 300 points
    │
    └─> Check budget:
        ├─> Monthly budget: 50,000 points
        ├─> Already used: 48,000 points
        └─> Remaining: 2,000 points ✅
         │
         ▼
Award Points
    ├─> Create transaction: +300 points
    ├─> Update account balance
    └─> Track provider usage: +300 to monthly usage
```

---

## ✅ Summary

### How System Knows What Points to Award:

1. **Provider Opt-In Creates Rule:**
   - When provider opts in, a rule is created with their `provider_id` and `multiplier` (1.0x, 1.5x, or 2.0x)
   - Rule has `priority=100` (highest priority)

2. **Service Log Triggers Calculation:**
   - Booking service calls `/loyalty/points/award` with `provider_id`
   - Points calculator looks for rules matching `provider_id`

3. **Rule Selection:**
   - Finds provider-specific rule (priority 100) if provider opted in
   - Falls back to default rule if no provider rule found

4. **Points Calculation:**
   - Base: `amount_spent × 0.01`
   - Provider multiplier: `base × provider_tier_multiplier` (from opt-in)
   - User multiplier: `result × user_tier_multiplier` (from lifetime points)

5. **Budget Check:**
   - Before awarding, checks if provider's monthly budget allows
   - Awards remaining budget if exceeded

6. **Points Awarded:**
   - Creates transaction record
   - Updates user's account balance
   - Tracks provider's monthly usage (for billing)

---

## 🔧 Recommended Enhancement

Add explicit participation check to prevent awarding points to non-participating providers:

```python
# In award_points endpoint, before calculation:
if request.provider_id:
    provider_config = crud.get_provider_config(db, request.provider_id)
    if provider_config and not provider_config.is_participating:
        # Provider opted out, don't use their rule
        # Continue with default rule calculation
        pass
```

This ensures that even if a provider-specific rule exists but provider has opted out, points are still calculated using default rules (without provider multiplier).

