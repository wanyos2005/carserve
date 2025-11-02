# Provider Opt-In API Examples

## Quick Start Guide

### 1. Provider Enables Loyalty Program

```bash
POST /loyalty/providers/{provider_id}/enable
Content-Type: application/json

{
    "participation_tier": "premium",
    "billing_plan": "monthly_subscription",
    "monthly_subscription_fee": 3000,
    "monthly_point_budget": 50000
}
```

**Response:**
```json
{
    "success": true,
    "provider_id": "provider-uuid-123",
    "config": {
        "provider_id": "provider-uuid-123",
        "is_participating": true,
        "point_multiplier": 1.5,
        "participation_tier": "premium",
        "monthly_point_budget": 50000,
        "points_awarded_this_month": 0,
        "billing_plan": "monthly_subscription",
        "monthly_subscription_fee": 3000,
        "participation_enabled_at": "2025-01-11T12:00:00Z"
    },
    "rule_created": true,
    "message": "Provider opted into premium tier with 1.5x multiplier"
}
```

### 2. Check Provider Configuration

```bash
GET /loyalty/providers/{provider_id}/config
```

**Response:**
```json
{
    "provider_id": "provider-uuid-123",
    "is_participating": true,
    "point_multiplier": 1.5,
    "participation_tier": "premium",
    "monthly_point_budget": 50000,
    "points_awarded_this_month": 1250,
    "billing_plan": "monthly_subscription",
    "monthly_subscription_fee": 3000
}
```

### 3. Get Provider Usage Statistics

```bash
GET /loyalty/providers/{provider_id}/usage
```

**Response:**
```json
{
    "provider_id": "provider-uuid-123",
    "is_participating": true,
    "points_awarded_this_month": 1250,
    "monthly_point_budget": 50000,
    "points_remaining": 48750,
    "billing_plan": "monthly_subscription",
    "estimated_monthly_cost": 3000,
    "participation_tier": "premium",
    "participation_enabled_at": "2025-01-11T12:00:00Z"
}
```

### 4. Provider Opts-Out

```bash
POST /loyalty/providers/{provider_id}/disable
```

**Response:**
```json
{
    "provider_id": "provider-uuid-123",
    "is_participating": false,
    "point_multiplier": 1.0,
    "participation_tier": null,
    "points_awarded_this_month": 1250
}
```

## Tier Options

- **basic**: 1.0x multiplier (free or low-cost plan)
- **premium**: 1.5x multiplier (moderate cost)
- **elite**: 2.0x multiplier (highest cost)

## Billing Plan Options

### Monthly Subscription
```json
{
    "billing_plan": "monthly_subscription",
    "monthly_subscription_fee": 3000
}
```

### Pay Per Point
```json
{
    "billing_plan": "pay_per_point",
    "billing_rate_per_point": 0.01
}
```

### Free (Platform-Funded)
```json
{
    "billing_plan": "free"
}
```

## Example Workflow

1. **Provider signs up** → Default config created (not participating)
2. **Provider enables program** → POST `/enable` → Rule created
3. **Customer uses provider** → Points awarded with multiplier
4. **Monthly tracking** → Points counted, budget checked
5. **Billing** → Calculate costs based on usage

