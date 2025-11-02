# Loyalty Tier Systems - Clarification

## Two Separate Tier Systems

The loyalty program uses **TWO different tier systems** that should NOT be confused:

### 1. **Provider Participation Tiers** (Provider Opt-In)
**Used for:** How much MORE points providers offer when they participate

**Tiers:** `basic`, `premium`, `elite`
- **basic**: 1.0x multiplier (provider offers standard points)
- **premium**: 1.5x multiplier (provider offers 50% more points)
- **elite**: 2.0x multiplier (provider offers 100% more points)

**Backend Location:**
- `backend/loyalty_service/crud/loyalty.py` lines 583-586:
  ```python
  TIER_MULTIPLIERS = {
      "basic": 1.0,
      "premium": 1.5,
      "elite": 2.0,
  }
  ```
- Model: `ProviderLoyaltyConfig.participation_tier` (comment: `# basic, premium, elite`)
- Schema: `ProviderOptInRequest.participation_tier` (comment: `# basic, premium, elite`)

**Purpose:** Determines how generous the provider wants to be with their loyalty program participation.

---

### 2. **User Loyalty Tiers** (User Account Levels)
**Used for:** How much MORE points users earn based on their account level

**Tiers:** `bronze`, `silver`, `gold`, `platinum`
- **bronze**: 1.0x multiplier (standard earning)
- **silver**: 1.5x multiplier (at 1,000 points)
- **gold**: 2.0x multiplier (at 5,000 points)
- **platinum**: 2.5x multiplier (at 20,000 points)

**Backend Location:**
- `backend/loyalty_service/services/points_calculator.py` lines 13-18:
  ```python
  DEFAULT_TIER_MULTIPLIERS = {
      "bronze": 1.0,
      "silver": 1.5,
      "gold": 2.0,
      "platinum": 2.5,
  }
  ```
- Model: `LoyaltyAccount.tier` (values: bronze, silver, gold, platinum)

**Purpose:** Rewards loyal customers with higher earning rates based on their lifetime points.

---

## Why They're Different

### Provider Participation Tiers
- **Chosen by provider** (they select when opting in)
- **Provider pays for it** (via billing plan)
- **Affects all customers** who use that provider
- **Business decision**: "How much should we invest in customer loyalty?"

### User Loyalty Tiers
- **Earned by user** (based on lifetime points)
- **Platform-funded** (cost absorbed by platform)
- **Personal benefit**: "How loyal have I been?"
- **Incentive**: Encourages users to earn more points

---

## How They Work Together

### Example Calculation:

```
Customer (Gold tier - 2.0x user multiplier)
uses Provider (Premium tier - 1.5x provider multiplier)

Base calculation: KES 10,000 spent
- Base points: 10,000 × 0.01 = 100 points
- Provider multiplier (Premium): 100 × 1.5 = 150 points
- User tier multiplier (Gold): 150 × 2.0 = 300 points FINAL

Total: 300 points awarded
```

---

## Frontend Consistency Check

### ✅ Provider Loyalty Page (`provider_loyalty_page.dart`)
**Current:** Uses "Basic", "Premium", "Elite" ✅ CORRECT
- Matches backend: `basic`, `premium`, `elite`

### ✅ User Loyalty Page (`user_loyalty_page.dart`)
**Current:** Uses "Bronze", "Silver", "Gold", "Platinum" ✅ CORRECT
- Matches backend: `bronze`, `silver`, `gold`, `platinum`

---

## Recommendation

**✅ KEEP AS IS** - The frontend is already consistent with the backend!

- Provider page should use: **Basic, Premium, Elite** (matches backend)
- User page should use: **Bronze, Silver, Gold, Platinum** (matches backend)

These are intentionally different systems and should remain separate for clarity.

---

## Database Schema

### Provider Participation Tiers
```sql
provider_loyalty_configs.participation_tier VARCHAR(20)
-- Values: NULL, 'basic', 'premium', 'elite'
```

### User Loyalty Tiers
```sql
loyalty_accounts.tier VARCHAR(20)
-- Values: 'bronze', 'silver', 'gold', 'platinum'
```

---

## Summary

**Frontend is CORRECT** ✅
- Provider tiers: Basic/Premium/Elite ✅
- User tiers: Bronze/Silver/Gold/Platinum ✅

**No changes needed** - The current implementation is consistent and correct!

