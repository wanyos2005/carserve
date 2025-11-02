# Billing & Budget Tracking - Visual Explanation

## 🎯 Simple Answer

**Budget Check** = "Do we have enough budget left?"
**Billing Tracking** = "How much do we owe the provider?"

---

## 📊 Real Example: Step by Step

### Provider Setup
```
Provider opts in with:
- Monthly Budget: 50,000 points
- Billing Plan: Pay KES 0.01 per point
```

### Scenario: Month Progresses

#### **Transaction 1: January 5th**
```
Customer uses provider → 1,000 points should be awarded

Step 1: BUDGET CHECK
├─ Current: points_awarded_this_month = 0
├─ Budget: monthly_point_budget = 50,000
├─ Request: 1,000 points
└─ Check: 0 + 1,000 = 1,000 ≤ 50,000 ✅ APPROVED

Step 2: AWARD POINTS
├─ Award 1,000 points to customer ✅

Step 3: TRACK FOR BILLING
├─ Update: points_awarded_this_month = 0 + 1,000 = 1,000
└─ Database now shows: "This month: 1,000 points awarded"
```

#### **Transaction 2: January 10th**
```
Customer uses provider → 500 points should be awarded

Step 1: BUDGET CHECK
├─ Current: points_awarded_this_month = 1,000
├─ Budget: monthly_point_budget = 50,000
├─ Request: 500 points
└─ Check: 1,000 + 500 = 1,500 ≤ 50,000 ✅ APPROVED

Step 2: AWARD POINTS
├─ Award 500 points to customer ✅

Step 3: TRACK FOR BILLING
├─ Update: points_awarded_this_month = 1,000 + 500 = 1,500
└─ Database now shows: "This month: 1,500 points awarded"
```

#### **Transaction 3: January 30th (Budget Almost Exceeded)**
```
Customer uses provider → 50,000 points should be awarded

Step 1: BUDGET CHECK
├─ Current: points_awarded_this_month = 49,500
├─ Budget: monthly_point_budget = 50,000
├─ Request: 50,000 points
└─ Check: 49,500 + 50,000 = 99,500 > 50,000 ❌ EXCEEDS!

Step 2: HANDLE EXCEEDED BUDGET
├─ Calculate remaining: 50,000 - 49,500 = 500 points
├─ Award only 500 points (not 50,000) ✅
└─ Reject remaining 49,500 points

Step 3: TRACK FOR BILLING
├─ Update: points_awarded_this_month = 49,500 + 500 = 50,000
└─ Database now shows: "This month: 50,000 points (BUDGET FULL)"
```

#### **Transaction 4: January 31st (Budget Exceeded)**
```
Customer uses provider → 100 points should be awarded

Step 1: BUDGET CHECK
├─ Current: points_awarded_this_month = 50,000
├─ Budget: monthly_point_budget = 50,000
├─ Request: 100 points
└─ Check: 50,000 + 100 = 50,100 > 50,000 ❌ EXCEEDS!

Step 2: HANDLE EXCEEDED BUDGET
├─ Remaining: 50,000 - 50,000 = 0 points
└─ REJECT: No points awarded ❌
└─ Return error: "Provider monthly point budget exceeded"

Step 3: TRACK FOR BILLING
├─ NO UPDATE (no points awarded)
└─ Database still shows: "This month: 50,000 points"
```

### Month End: Calculate Bill

```
Provider's January Summary:
├─ Points Awarded: 50,000 points
├─ Billing Plan: pay_per_point
├─ Rate: KES 0.01 per point
└─ Calculation: 50,000 × 0.01 = KES 500.00

→ Invoice Provider: KES 500.00
→ Provider pays invoice
```

### February 1st: Auto-Reset

```
New Month Starts
├─ System detects: current_month_start < February 1st
├─ Reset: points_awarded_this_month = 0
└─ Budget resets: Can award up to 50,000 points again
```

---

## 🔍 Code Walkthrough

### **Budget Check (Lines 150-170)**

```python
# Check provider participation and budget limits
if request.provider_id:
    provider_config = crud.get_provider_config(db, request.provider_id)
    
    if provider_config and provider_config.monthly_point_budget:
        # Calculate: current + requested vs budget
        if provider_config.points_awarded_this_month + points_to_award > provider_config.monthly_point_budget:
            # ❌ WOULD EXCEED BUDGET
            
            remaining = provider_config.monthly_point_budget - provider_config.points_awarded_this_month
            
            if remaining > 0:
                # Award only remaining (partial award)
                points_to_award = remaining
            else:
                # Reject entirely (no budget left)
                return error_response("Budget exceeded")
```

**What it does:**
- ✅ Checks BEFORE awarding
- ✅ Prevents going over budget
- ✅ Awards partial points if some budget remains

### **Track for Billing (Line 190)**

```python
# Track points awarded to provider for billing
if request.provider_id and points_to_award > 0:
    crud.increment_provider_points_awarded(db, request.provider_id, points_to_award)
```

**What it does:**
- ✅ Updates counter AFTER awarding
- ✅ Used for monthly billing calculation
- ✅ Automatically resets each month

### **Increment Function (Lines 501-517)**

```python
def increment_provider_points_awarded(db: Session, provider_id: str, points: int):
    config = get_or_create_provider_config(db, provider_id)
    
    # Check if new month
    now = datetime.now(timezone.utc)
    current_month_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
    
    if config.current_month_start is None or config.current_month_start < current_month_start:
        # New month → reset to 0
        config.points_awarded_this_month = points
        config.current_month_start = current_month_start
    else:
        # Same month → add to total
        config.points_awarded_this_month += points
    
    db.commit()
```

**What it does:**
- ✅ Adds points to monthly counter
- ✅ Auto-resets on new month
- ✅ Tracks total for billing

---

## 💰 Billing Calculation Examples

### Example 1: Pay-Per-Point

```python
Provider Config:
├─ points_awarded_this_month: 25,000
├─ billing_plan: "pay_per_point"
└─ billing_rate_per_point: 0.01

Monthly Bill = 25,000 × 0.01 = KES 250.00
```

### Example 2: Monthly Subscription

```python
Provider Config:
├─ points_awarded_this_month: 50,000 (unlimited)
├─ billing_plan: "monthly_subscription"
└─ monthly_subscription_fee: 3,000

Monthly Bill = KES 3,000 (fixed, regardless of points)
```

### Example 3: Free (Platform-Funded)

```python
Provider Config:
├─ points_awarded_this_month: 10,000
└─ billing_plan: "free"

Monthly Bill = KES 0 (platform pays)
```

---

## 📋 Why Both Steps Are Needed

### **Budget Check** (Before Awarding)
```
Purpose: PREVENTION
- Stops provider from exceeding their budget
- Protects provider from unexpected costs
- Enforces monthly spending limits

Without it: Provider could get 100,000 points billed when they set 50,000 limit! ❌
With it: System stops at 50,000, provider knows exact cost ✅
```

### **Billing Tracking** (After Awarding)
```
Purpose: ACCOUNTING
- Records how many points were actually awarded
- Used to calculate monthly invoice
- Provides audit trail

Without it: "How much do we bill provider?" → No data! ❌
With it: "Provider awarded 50,000 points, bill them KES 500" ✅
```

---

## 🎯 Summary

**Budget Check → Enforces Monthly Limits**
- Happens BEFORE awarding points
- Prevents exceeding `monthly_point_budget`
- Awards partial points if some budget remains
- Rejects if budget is 0

**Points Awarded → Tracked for Billing**
- Happens AFTER awarding points
- Increments `points_awarded_this_month` counter
- Used at month end to calculate invoice
- Auto-resets when new month starts

**Billing**
- Calculated from `points_awarded_this_month`
- Based on `billing_plan` and `billing_rate_per_point`
- Invoice generated monthly

**The Flow is:**
```
Check Budget → Award Points → Track Usage → Calculate Bill
   (prevent)      (execute)     (record)      (invoice)
```

Does this clarify the billing flow? 🎯

