# Loyalty Program: Provider Participation & Financing Model

## 🎯 Current Architecture Overview

### How It Works Now

Currently, the loyalty program operates with a **flexible rules engine** that supports multiple participation models:

```
Service Log Created (with cost)
    ↓
Booking Service → Loyalty Service
    ↓
Points Calculator evaluates rules
    ↓
Rule Matching Logic:
    - Global rule (all providers) OR
    - Provider-specific rule OR  
    - Provider category rule OR
    - Service-specific rule
    ↓
Points Awarded to User
```

### Key Architecture Features

1. **Rule-Based System**: Rules are stored in `loyalty.loyalty_rules` table
2. **Provider-Specific Rules**: Rules can target specific `provider_id`
3. **Category Rules**: Rules can apply to provider categories (garage, insurance, etc.)
4. **Flexible Matching**: Priority-based rule evaluation (highest priority first)

---

## 💼 Business Models: How Providers Can Participate

### **Model 1: Platform-Funded (Current Default)**

**How it works:**
- Platform pays for all loyalty points
- All providers automatically participate
- Platform sets global rules (e.g., 1 point per KES 100)
- Providers get customer retention benefits for free

**Pros:**
- Simple implementation (already works this way)
- Providers have no barrier to entry
- Platform controls marketing spend

**Cons:**
- Platform bears all costs
- No provider differentiation
- Limited provider engagement

**When to use:**
- Early stage / customer acquisition phase
- Platform has marketing budget
- Want to encourage all providers to participate

---

### **Model 2: Provider-Opt-In (Recommended)**

**How it works:**
- Providers choose to participate
- Each provider sets their own point rates (or chooses from tiers)
- Provider pays platform a fee or commission on points awarded
- Platform tracks which providers are participating

**Implementation:**
```
Provider → Settings → Enable Loyalty Program
    → Choose tier: Basic (1x), Premium (1.5x), Elite (2x)
    → Platform creates provider-specific rule
    → Points awarded only when using participating providers
```

**Pros:**
- Providers control their participation
- Platform can charge participation fees
- Providers can differentiate (higher rates = competitive advantage)
- Self-funded by providers

**Cons:**
- More complex setup
- Need provider payment/billing system
- Providers might not all opt-in

**When to use:**
- Platform wants providers to fund the program
- Providers want competitive differentiation
- Sustainable long-term model

---

### **Model 3: Hybrid (Recommended for Growth)**

**How it works:**
- Platform funds base rate (e.g., 1 point per KES 100)
- Providers can "boost" their rate (e.g., pay extra for 1.5x or 2x multiplier)
- Providers only pay for the "boost" portion
- Platform covers base rewards

**Example:**
```
Base Rule (Platform-funded): 1 point per KES 100 (all providers)
Provider Boost Rule: Additional 0.5x multiplier (provider pays)
Result: User gets 1.5 points per KES 100 at this provider
```

**Pros:**
- Best of both worlds
- Low barrier to entry (base program for all)
- Providers can compete with higher rates
- Platform controls base costs

**Cons:**
- More complex billing/accounting
- Need to track base vs. boost points

**When to use:**
- Transitioning from Model 1 to Model 2
- Want universal participation with upgrade path
- Platform + provider shared funding

---

### **Model 4: Category-Based (Current Capability)**

**How it works:**
- Different point rates by provider category
- Platform sets rates per category
- Providers automatically get their category's rate

**Example:**
```
Garages: 1 point per KES 100
Fuel Stations: 2 points per KES 100 (higher margin business)
Insurance: 5 points per KES 100 (high-value service)
```

**Implementation:**
- Already supported via `provider_category_id` in rules
- Platform can create category-specific rules
- No provider opt-in needed

**Pros:**
- Fair allocation based on business type
- Reflects different profit margins
- Simple to manage

**Cons:**
- Providers can't customize
- Platform controls all rates

---

## 🔧 Recommended Implementation: Provider Opt-In Model

### Phase 1: Add Provider Participation Tracking

**Add to Provider Model:**
```python
class Provider(Base):
    # ... existing fields ...
    
    # Loyalty program participation
    loyalty_participation_enabled = Column(Boolean, default=False)
    loyalty_rate_multiplier = Column(Numeric(5, 2), default=1.0)  # 1.0x, 1.5x, 2.0x
    loyalty_participation_tier = Column(String(20), nullable=True)  # basic, premium, elite
    loyalty_last_updated = Column(TIMESTAMP(timezone=True), nullable=True)
```

**Add to Loyalty Service:**
```python
class ProviderLoyaltyConfig(Base):
    """Provider's loyalty program configuration"""
    __tablename__ = "provider_loyalty_configs"
    __table_args__ = {"schema": "loyalty"}
    
    provider_id = Column(String, primary_key=True)
    is_participating = Column(Boolean, default=False)
    point_multiplier = Column(Numeric(5, 2), default=1.0)
    participation_tier = Column(String(20))  # basic, premium, elite
    monthly_point_budget = Column(Integer, nullable=True)  # Limit per month
    points_awarded_this_month = Column(Integer, default=0)
    billing_plan = Column(String(50))  # free, pay_per_point, monthly_fee
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
```

### Phase 2: Workflow

**1. Provider Enables Participation:**
```
Provider Dashboard → Settings → Loyalty Program
    → Toggle "Enable Loyalty Program"
    → Choose tier (Basic: 1.0x, Premium: 1.5x, Elite: 2.0x)
    → Confirm billing/payment method
    ↓
Platform creates/updates provider-specific loyalty rule
    → Rule: provider_id = X, multiplier = chosen_multiplier
    → Rule priority = 100 (high priority = provider-specific)
```

**2. Points Award Flow:**
```
Service Log Created (provider_id = X, cost = 5000 KES)
    ↓
Loyalty Service: Get active rules
    ↓
Check Provider Participation:
    - Is provider participating? → Use provider rule
    - Is provider NOT participating? → Use global/default rule
    ↓
Calculate points:
    - Participating: 5000 × 0.01 × provider_multiplier (e.g., 1.5x) = 75 points
    - Non-participating: 5000 × 0.01 × 1.0 = 50 points
```

**3. Billing/Accounting:**
```
Monthly Reconciliation:
    → Calculate total points awarded per provider
    → Calculate cost (if pay-per-point model)
    → Invoice provider or deduct from platform account
    → Reset monthly counters
```

---

## 📊 Proposed Data Model Enhancements

### Option A: Track Provider Participation in Provider Service (Recommended)

Add fields to track provider's loyalty participation:

```sql
ALTER TABLE service_providers.providers
ADD COLUMN loyalty_participation_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN loyalty_point_multiplier NUMERIC(5,2) DEFAULT 1.0,
ADD COLUMN loyalty_participation_tier VARCHAR(20);
```

### Option B: Separate Loyalty Config Table (More Flexible)

Create dedicated table for loyalty configurations:

```sql
CREATE TABLE loyalty.provider_loyalty_configs (
    provider_id VARCHAR PRIMARY KEY,
    is_participating BOOLEAN DEFAULT FALSE,
    point_multiplier NUMERIC(5,2) DEFAULT 1.0,
    participation_tier VARCHAR(20),
    monthly_point_budget INTEGER,
    points_awarded_this_month INTEGER DEFAULT 0,
    billing_plan VARCHAR(50),  -- 'free', 'pay_per_point', 'monthly_fee'
    billing_rate_per_point NUMERIC(10,4),  -- e.g., 0.01 KES per point
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## 💰 Billing Models for Providers

### **Model A: Pay-Per-Point**
- Provider pays for each point awarded
- Example: KES 0.01 per point (10 points = KES 0.10)
- Track: `points_awarded_this_month × billing_rate_per_point`
- Bill monthly

### **Model B: Monthly Subscription**
- Provider pays fixed monthly fee
- Example: KES 5,000/month for Premium tier (1.5x multiplier)
- Unlimited points up to budget (optional)
- Simpler billing

### **Model C: Commission-Based**
- Provider pays % of transaction value
- Example: 2% of service value goes to loyalty points
- Service of KES 5,000 → Provider pays KES 100 → User gets 50 points
- Self-funding model

---

## 🔄 Recommended Workflow Implementation

### Step 1: Provider Opts-In (Via Provider Dashboard)

```python
# Provider enables loyalty program
POST /api/service-providers/{provider_id}/loyalty/enable
{
    "participation_tier": "premium",  # basic, premium, elite
    "billing_plan": "monthly_subscription"
}

# Creates/updates provider-specific rule
# Rule: multiplier = 1.5x for premium tier
```

### Step 2: Points Calculation (Enhanced)

```python
# In points_calculator.py
def calculate_points(...):
    # Check if provider is participating
    provider_config = get_provider_loyalty_config(provider_id)
    
    if provider_config and provider_config.is_participating:
        # Use provider-specific multiplier
        multiplier = provider_config.point_multiplier
    else:
        # Use default/global rule
        multiplier = 1.0
    
    # Apply multiplier to base calculation
    points = base_points * multiplier
```

### Step 3: Monthly Billing (Scheduled Job)

```python
# Monthly cron job
def reconcile_provider_loyalty_billing():
    for provider in participating_providers:
        points_awarded = get_monthly_points(provider_id)
        if billing_plan == "pay_per_point":
            amount = points_awarded * billing_rate_per_point
            create_invoice(provider_id, amount)
        elif billing_plan == "monthly_subscription":
            # Already paid, just verify usage within limits
            check_monthly_budget(provider_id, points_awarded)
```

---

## 📋 Current State vs. Recommended Enhancement

### ✅ What Works Now:
- Rules can be provider-specific (via `provider_id` field)
- Rules can be category-specific (via `provider_category_id`)
- Priority-based rule matching
- Flexible multipliers

### 🚧 What's Missing:
- Provider participation opt-in/opt-out tracking
- Provider billing/accounting
- Monthly point budgets/limits
- Provider dashboard UI for loyalty settings
- Automated rule creation when provider opts-in

### 🎯 Recommended Next Steps:

1. **Add Provider Participation Table** (Option B above)
2. **Create Provider Loyalty API Endpoints**:
   - `GET /loyalty/providers/{provider_id}/config` - Get participation status
   - `POST /loyalty/providers/{provider_id}/enable` - Opt-in to program
   - `POST /loyalty/providers/{provider_id}/disable` - Opt-out
   - `GET /loyalty/providers/{provider_id}/usage` - Monthly points awarded
3. **Enhance Points Calculator** to check participation status
4. **Create Admin Dashboard** for managing provider billing
5. **Add Provider Dashboard UI** for loyalty program settings

---

## 🎨 Example Workflow: Provider Opts-In

```
Day 1: Provider Signs Up
    → Provider account created
    → Loyalty participation: DISABLED (default)
    → Points awarded at base rate (1.0x) if any service logs

Day 2: Provider Enables Loyalty Program
    → Provider goes to Settings → Loyalty Program
    → Selects "Premium Tier" (1.5x multiplier, KES 3,000/month)
    → Provides payment method
    ↓
Backend:
    → Create ProviderLoyaltyConfig record
    → Create/update LoyaltyRule: provider_id = X, multiplier = 1.5
    → Set rule priority = 100 (high priority)
    → Set billing_plan = "monthly_subscription"
    ↓
Day 3: Customer logs service at this provider
    → Service cost: KES 5,000
    → Points calculation:
        - Base: 5,000 × 0.01 = 50 points
        - Provider multiplier: 50 × 1.5 = 75 points ✅
    → Customer receives 75 points (instead of 50)

Month End: Billing
    → Total points awarded: 1,500 points
    → Provider already paid monthly fee (KES 3,000)
    → No additional charge (within budget limits)
    → Report sent to provider
```

---

## 🤔 Recommendation: Start with Model 1, Migrate to Model 2

**Phase 1 (Now)**: Platform-funded, all providers participate
- No provider opt-in needed
- Platform controls all costs
- Simple to manage

**Phase 2 (3-6 months)**: Add opt-in capability
- Build provider participation tracking
- Add provider settings UI
- Keep base program for all, premium for opt-in providers

**Phase 3 (6-12 months)**: Full provider-funded
- Providers choose to participate
- Platform charges fees/subscriptions
- Self-sustaining program

This gives you time to:
- Validate the loyalty program value
- Build provider demand for participation
- Develop billing infrastructure
- Test different pricing models

---

## 📝 Summary

**Current Architecture Supports:**
- ✅ Provider-specific rules (via `provider_id` in rules table)
- ✅ Category-specific rules (via `provider_category_id`)
- ✅ Flexible multipliers and conditions
- ✅ Priority-based rule matching

**What You Need to Add for Provider Financing:**
1. Provider participation tracking (opt-in/opt-out)
2. Provider billing/accounting system
3. Provider dashboard UI for loyalty settings
4. Automated rule creation when provider opts-in
5. Monthly reconciliation and billing

**Recommended Approach:**
- Start with platform-funded (current default)
- Add provider opt-in capability
- Build billing system incrementally
- Let providers choose their participation level

The architecture is flexible enough to support any of these models! 🚀

