-- Migration: 033_add_provider_loyalty_configs.sql
-- Description: Add provider loyalty participation tracking table
-- Created: 2025-01-11
-- Author: System

-- Provider Loyalty Configs Table
CREATE TABLE IF NOT EXISTS loyalty.provider_loyalty_configs (
    provider_id VARCHAR PRIMARY KEY,
    
    -- Participation status
    is_participating BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Point calculation
    point_multiplier NUMERIC(5, 2) NOT NULL DEFAULT 1.0,
    participation_tier VARCHAR(20),
    
    -- Budget and usage tracking
    monthly_point_budget INTEGER,
    points_awarded_this_month INTEGER NOT NULL DEFAULT 0,
    current_month_start TIMESTAMP WITH TIME ZONE,
    
    -- Billing configuration
    billing_plan VARCHAR(50) NOT NULL DEFAULT 'free',
    billing_rate_per_point NUMERIC(10, 4),
    monthly_subscription_fee INTEGER,
    
    -- Metadata (renamed to extra_metadata to avoid SQLAlchemy reserved name conflict)
    extra_metadata JSONB,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    participation_enabled_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_provider_loyalty_configs_participating ON loyalty.provider_loyalty_configs(is_participating);
CREATE INDEX IF NOT EXISTS idx_provider_loyalty_configs_tier ON loyalty.provider_loyalty_configs(participation_tier);
CREATE INDEX IF NOT EXISTS idx_provider_loyalty_configs_billing ON loyalty.provider_loyalty_configs(billing_plan);

-- Add comments for documentation
COMMENT ON TABLE loyalty.provider_loyalty_configs IS 'Tracks provider participation in loyalty program';
COMMENT ON COLUMN loyalty.provider_loyalty_configs.is_participating IS 'Whether provider has opted into the loyalty program';
COMMENT ON COLUMN loyalty.provider_loyalty_configs.point_multiplier IS 'Multiplier for points awarded (1.0x, 1.5x, 2.0x, etc.)';
COMMENT ON COLUMN loyalty.provider_loyalty_configs.participation_tier IS 'Tier level: basic, premium, elite';
COMMENT ON COLUMN loyalty.provider_loyalty_configs.billing_plan IS 'Billing model: free, pay_per_point, monthly_subscription';

