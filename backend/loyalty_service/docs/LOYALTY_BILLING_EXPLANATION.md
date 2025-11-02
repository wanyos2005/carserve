# Loyalty Program Billing & Budget Tracking Explained

## 🎯 What You Asked About

```
Budget Check → Enforces Monthly Limits
    ↓
Points Awarded → Tracked for Billing
```

Let me break this down step by step with actual code examples.

---

## 📊 Step-by-Step Flow

### 1. **When Points Are Awarded** (Customer uses provider)

```
Customer logs service at Provider X
Service cost: KES 5,000
    ↓
Booking Service calls: POST /loyalty/points/award
    {
        "user_id": 123,
        "provider_id": "provider-uuid-x",
        "amount_spent": 5000,
        ...
    }
    ↓
Loyalty Service processes award
```

### 2. **Budget Check** (Prevents Over-Spending)

**Location:** `backend/loyalty_service/routers/loyalty.py` (lines 150-170)

```python
# Check provider participation and budget limits
if request.provider_id:
    provider_config = crud.get_provider_config(db, request.provider_id)
    
    # Check if provider has monthly budget and if exceeded
    if provider_config:
        if provider_config.monthly_point_budget:
            # Provider has a budget limit (e.g., 50,000 points/month)
            if provider_config.points_awarded_this_month + points_to_award > provider_config.monthly_point_budget:
                # Budget exceeded!
                remaining = provider_config.monthly_point_budget - provider_config.points_awarded_this_month
                
                if remaining > 0:
                    # Award only remaining points
                    points_to_award = remaining  # e.g., only 2,000 points instead of 5,000
                else:
                    # No points remaining, reject entirely
                    return PointsAwardResponse(
                        success=False,
                        message="Provider monthly point budget exceeded"
                    )
```

**Example Scenario:**
```
Provider Budget: 50,000 points/month
Points Already Awarded This Month: 49,000 points
New Request: 5,000 points

Calculation:
49,000 + 5,000 = 54,000 > 50,000 ❌ (exceeds budget)

Action:
- Award only 1,000 points (remaining in budget)
- OR reject if 0 remaining
```

### 3. **Points Awarded** (After Budget Check Passes)

**Location:** `backend/loyalty_service/routers/loyalty.py` (lines 172-190)

```python
# Create transaction
transaction = crud.create_transaction(
    db=db,
    account_id=account.id,
    points_delta=points_to_award,  # Points awarded to user
    transaction_type="earned",
    provider_id=request.provider_id,
    amount_spent=request.amount_spent,
)

# Track points awarded to provider for billing ⬅️ THIS IS THE KEY PART
if request.provider_id and points_to_award > 0:
    crud.increment_provider_points_awarded(db, request.provider_id, points_to_award)
```

### 4. **Tracked for Billing** (Monthly Counter)

**Location:** `backend/loyalty_service/crud/loyalty.py` (lines 501-517)

```python
def increment_provider_points_awarded(db: Session, provider_id: str, points: int):
    """Increment monthly points counter for provider"""
    config = get_or_create_provider_config(db, provider_id)
    
    # Check if month has changed
    now = datetime.now(timezone.utc)
    current_month_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
    
    if config.current_month_start is None or config.current_month_start < current_month_start:
        # New month! Reset counter
        config.points_awarded_this_month = points  # Start fresh
        config.current_month_start = current_month_start
    else:
        # Same month, just add to counter
        config.points_awarded_this_month += points  # Add to total
    
    db.commit()
```

**What This Does:**
- Every time points are awarded, increment `points_awarded_this_month`
- Automatically resets to 0 when a new month starts
- Used for billing calculations

---

## 💰 How Billing Works

### Data Structure

**ProviderLoyaltyConfig Table:**
```sql
provider_id: "provider-uuid-x"
points_awarded_this_month: 1250  ← Tracked here!
monthly_point_budget: 50000      ← Budget limit
billing_plan: "monthly_subscription"
billing_rate_per_point: 0.01    ← Cost per point
```

### Billing Calculation Examples

#### **Model A: Pay-Per-Point**

```python
# Provider pays: points_awarded × rate_per_point

Example:
points_awarded_this_month = 1,250 points
billing_rate_per_point = 0.01 KES per point

Monthly Bill = 1,250 × 0.01 = KES 12.50
```

#### **Model B: Monthly Subscription**

```python
# Provider pays fixed monthly fee

Example:
monthly_subscription_fee = 3,000 KES/month
points_awarded_this_month = 50,000 points

Monthly Bill = KES 3,000 (fixed, regardless of points)
```

#### **Model C: Free (Platform-Funded)**

```python
# No billing, platform pays

billing_plan = "free"
Monthly Bill = KES 0
```

---

## 📋 Complete Example: Real Scenario

### Provider Setup

```python
POST /loyalty/providers/{provider_id}/enable
{
    "participation_tier": "premium",
    "billing_plan": "pay_per_point",
    "billing_rate_per_point": 0.01,
    "monthly_point_budget": 50000
}
```

**Result:**
- Provider gets 1.5x multiplier (premium tier)
- Budget: 50,000 points/month
- Billing: KES 0.01 per point

### Day 1: Customer Uses Provider

```
Service Log: Cost = KES 10,000
    ↓
Points Calculation: 10,000 × 0.01 × 1.5 = 150 points
    ↓
Budget Check: 0 + 150 = 150 ≤ 50,000 ✅
    ↓
Points Awarded: 150 points to customer
    ↓
Billing Tracking:
    provider_config.points_awarded_this_month = 150
```

### Day 2: More Customers

```
Service Log 1: 100 points awarded
Service Log 2: 75 points awarded
Service Log 3: 200 points awarded

Total this month: 150 + 100 + 75 + 200 = 525 points

Billing Tracking:
    provider_config.points_awarded_this_month = 525
```

### Day 30: Budget Almost Exceeded

```
Service Log: Would award 50,000 points
    ↓
Budget Check:
    Current: 49,500 points
    Request: 50,000 points
    Total: 99,500 > 50,000 ❌ EXCEEDS BUDGET!
    ↓
Action: Award only 500 points (remaining in budget)
    ↓
Billing Tracking:
    provider_config.points_awarded_this_month = 50,000 (capped)
```

### Month End: Billing Invoice

```python
# Monthly reconciliation (scheduled job or manual)

GET /loyalty/providers/{provider_id}/usage

Response:
{
    "points_awarded_this_month": 50,000,
    "billing_plan": "pay_per_point",
    "billing_rate_per_point": 0.01,
    "estimated_monthly_cost": 500.00  // 50,000 × 0.01
}

→ Generate Invoice: KES 500.00
→ Provider pays invoice
→ Reset counter for next month
```

---

## 🔍 Key Database Fields Explained

### `points_awarded_this_month`
- **Purpose:** Tracks total points awarded this month
- **Updated:** Every time points are awarded
- **Reset:** Automatically at start of new month

### `monthly_point_budget`
- **Purpose:** Maximum points provider wants to award per month
- **Enforced:** Before awarding points (budget check)
- **Optional:** Can be NULL (unlimited budget)

### `current_month_start`
- **Purpose:** Tracks which month we're counting
- **Used:** To detect month changes and reset counter
- **Example:** `2025-01-01 00:00:00` = January 2025

### `billing_plan`
- **Values:** `"free"`, `"pay_per_point"`, `"monthly_subscription"`
- **Purpose:** Determines how provider is billed

### `billing_rate_per_point`
- **Purpose:** Cost per point (for pay_per_point plan)
- **Example:** 0.01 = KES 0.01 per point
- **Used:** Calculate monthly bill

---

## 💡 Why This Design?

### **1. Budget Check Prevents Overspending**
```
Without Budget Check:
- Provider sets budget: 50,000 points/month
- But system awards 100,000 points
- Provider gets unexpected bill! ❌

With Budget Check:
- System checks before awarding
- Stops at budget limit
- Provider knows exactly what they'll pay ✅
```

### **2. Monthly Tracking Enables Billing**
```
Without Tracking:
- How many points did provider award this month?
- What do we bill them?
- No data! ❌

With Tracking:
- points_awarded_this_month = 50,000
- billing_rate_per_point = 0.01
- Monthly bill = 50,000 × 0.01 = KES 500 ✅
```

### **3. Automatic Month Reset**
```
Without Auto-Reset:
- January: 50,000 points awarded
- February: Counter still shows 50,000 ❌
- Wrong billing!

With Auto-Reset:
- January: 50,000 points
- February 1st: Automatically resets to 0 ✅
- Clean billing cycle
```

---

## 🔄 Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────┐
│ Customer Uses Provider                                   │
│ Service Cost: KES 5,000                                 │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────┐
│ Booking Service → Loyalty Service                       │
│ POST /loyalty/points/award                              │
│ { provider_id: "x", amount_spent: 5000 }               │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────┐
│ Calculate Points                                         │
│ Base: 5,000 × 0.01 = 50 points                          │
│ Premium Multiplier: 50 × 1.5 = 75 points                │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────┐
│ ✅ BUDGET CHECK                                          │
│                                                          │
│ Current: points_awarded_this_month = 49,500            │
│ Budget: monthly_point_budget = 50,000                   │
│ Request: 75 points                                       │
│                                                          │
│ Calculation: 49,500 + 75 = 49,575 ≤ 50,000 ✅           │
│ Result: Approved (75 points)                            │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────┐
│ Award Points to Customer                                 │
│ Create LoyaltyTransaction:                               │
│   - account_id: customer_account                        │
│   - points_delta: +75                                    │
│   - provider_id: "x"                                     │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────┐
│ 📊 TRACK FOR BILLING                                     │
│                                                          │
│ increment_provider_points_awarded(provider_id, 75)     │
│                                                          │
│ Update ProviderLoyaltyConfig:                           │
│   points_awarded_this_month: 49,500 + 75 = 49,575      │
│   (stored in database for billing)                       │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────┐
│ Month End: Billing                                       │
│                                                          │
│ points_awarded_this_month = 50,000                      │
│ billing_rate_per_point = 0.01                           │
│                                                          │
│ Invoice Amount = 50,000 × 0.01 = KES 500                │
│                                                          │
│ Reset: points_awarded_this_month = 0 (new month)        │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Summary

**Budget Check:**
- Happens BEFORE awarding points
- Prevents exceeding monthly budget
- Protects provider from unexpected costs

**Billing Tracking:**
- Happens AFTER awarding points
- Increments `points_awarded_this_month` counter
- Used at month end to calculate invoice

**Why Both:**
- Budget check = **prevention** (stop overspending)
- Billing tracking = **accounting** (calculate what to charge)

The system ensures providers never exceed their budget AND accurately tracks usage for billing! 🎯

