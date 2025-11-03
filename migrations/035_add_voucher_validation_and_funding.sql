-- Migration: Add voucher validation fields and provider funding to loyalty
-- Created: 2025-11-03

-- Rewards funding fields
ALTER TABLE IF EXISTS loyalty.rewards
    ADD COLUMN IF NOT EXISTS funding_model VARCHAR(20) NOT NULL DEFAULT 'platform',
    ADD COLUMN IF NOT EXISTS funding_provider_id VARCHAR,
    ADD COLUMN IF NOT EXISTS co_fund_split_pct INTEGER;

-- Loyalty redemptions validation/settlement fields
ALTER TABLE IF NOT EXISTS loyalty.loyalty_redemptions
    ADD COLUMN IF NOT EXISTS is_consumed BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS validated_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS validated_by_provider_id VARCHAR,
    ADD COLUMN IF NOT EXISTS settlement_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS settlement_provider_amount INTEGER,
    ADD COLUMN IF NOT EXISTS settlement_platform_amount INTEGER;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_loyalty_redemptions_is_consumed ON loyalty.loyalty_redemptions(is_consumed);
CREATE INDEX IF NOT EXISTS idx_loyalty_redemptions_validated_provider ON loyalty.loyalty_redemptions(validated_by_provider_id);

