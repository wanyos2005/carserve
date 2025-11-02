# Metadata Field Fix Summary

## Issue
SQLAlchemy raised an error: `Attribute name 'metadata' is reserved when using the Declarative API.`

## Root Cause
SQLAlchemy uses `metadata` as a reserved attribute in the Declarative API (it's used for `Base.metadata` which contains table metadata). Using `metadata` as a column name conflicts with this.

## Solution
Renamed all `metadata` columns to `extra_metadata` in:
1. ✅ Model definitions (`models/loyalty.py`)
2. ✅ Schema definitions (`schemas/loyalty.py`)
3. ✅ Migration file (`migrations/033_add_provider_loyalty_configs.sql`)

## Files Changed

### Models (`backend/loyalty_service/models/loyalty.py`)
- `LoyaltyTransaction.metadata` → `LoyaltyTransaction.extra_metadata`
- `Reward.metadata` → `Reward.extra_metadata`
- `ProviderLoyaltyConfig.metadata` → `ProviderLoyaltyConfig.extra_metadata`

### Schemas (`backend/loyalty_service/schemas/loyalty.py`)
- `ProviderLoyaltyConfigBase.metadata` → `extra_metadata`
- `ProviderLoyaltyConfigUpdate.metadata` → `extra_metadata`

### Migration (`migrations/033_add_provider_loyalty_configs.sql`)
- Column name changed from `metadata` to `extra_metadata`

## Note
Function parameters can still use `metadata` (like in `calculate_points`), only model column names needed to change.

## Testing
After these changes, the service should start successfully without the SQLAlchemy error.

