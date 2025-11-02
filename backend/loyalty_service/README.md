# Loyalty Service

A microservice for managing loyalty points, rewards, and tier systems for the car platform.

## Features

- **Points Management**: Award and track loyalty points
- **Tier System**: Bronze → Silver → Gold → Platinum tiers with multipliers
- **Rules Engine**: Configurable rules for point calculation
- **Rewards Catalog**: Manage and redeem rewards
- **Transaction History**: Full audit trail
- **Idempotency**: Prevents duplicate point awards

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

### Rules (Admin)
- `GET /loyalty/rules` - List all rules
- `POST /loyalty/rules` - Create new rule

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

