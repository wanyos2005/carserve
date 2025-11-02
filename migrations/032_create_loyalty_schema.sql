-- Migration: 010_create_loyalty_schema.sql
-- Description: Create loyalty program schema and tables
-- Created: 2025-01-11
-- Author: System

-- Create loyalty schema
CREATE SCHEMA IF NOT EXISTS loyalty;

-- Loyalty Accounts Table
CREATE TABLE IF NOT EXISTS loyalty.loyalty_accounts (
    id VARCHAR PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    points_balance INTEGER NOT NULL DEFAULT 0,
    lifetime_points_earned INTEGER NOT NULL DEFAULT 0,
    lifetime_points_spent INTEGER NOT NULL DEFAULT 0,
    tier VARCHAR(20) NOT NULL DEFAULT 'bronze',
    tier_points_threshold INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_loyalty_accounts_user_id ON loyalty.loyalty_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_accounts_tier ON loyalty.loyalty_accounts(tier);

-- Loyalty Transactions Table
CREATE TABLE IF NOT EXISTS loyalty.loyalty_transactions (
    id VARCHAR PRIMARY KEY,
    account_id VARCHAR NOT NULL,
    points_delta INTEGER NOT NULL,
    points_balance_after INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    transaction_reason VARCHAR(255),
    reference_type VARCHAR(50),
    reference_id VARCHAR,
    idempotency_key VARCHAR UNIQUE,
    provider_id VARCHAR,
    service_id VARCHAR,
    amount_spent INTEGER,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_expired BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES loyalty.loyalty_accounts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_account_id ON loyalty.loyalty_transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_type ON loyalty.loyalty_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_reference ON loyalty.loyalty_transactions(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_idempotency ON loyalty.loyalty_transactions(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_provider ON loyalty.loyalty_transactions(provider_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_expires ON loyalty.loyalty_transactions(expires_at);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_expired ON loyalty.loyalty_transactions(is_expired);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_created ON loyalty.loyalty_transactions(created_at);

-- Loyalty Rules Table
CREATE TABLE IF NOT EXISTS loyalty.loyalty_rules (
    id VARCHAR PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    provider_id VARCHAR,
    provider_category_id INTEGER,
    service_id VARCHAR,
    service_category_id INTEGER,
    base_points_per_kes NUMERIC(10, 4) NOT NULL DEFAULT 0.01,
    multiplier NUMERIC(5, 2) NOT NULL DEFAULT 1.0,
    min_amount INTEGER,
    max_points_per_transaction INTEGER,
    tier_multipliers JSONB,
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    priority INTEGER NOT NULL DEFAULT 0,
    conditions JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_loyalty_rules_provider ON loyalty.loyalty_rules(provider_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_rules_provider_category ON loyalty.loyalty_rules(provider_category_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_rules_service ON loyalty.loyalty_rules(service_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_rules_service_category ON loyalty.loyalty_rules(service_category_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_rules_active ON loyalty.loyalty_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_loyalty_rules_priority ON loyalty.loyalty_rules(priority DESC);

-- Rewards Table
CREATE TABLE IF NOT EXISTS loyalty.rewards (
    id VARCHAR PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    reward_type VARCHAR(50) NOT NULL,
    points_cost INTEGER NOT NULL,
    discount_percentage NUMERIC(5, 2),
    discount_amount INTEGER,
    cashback_amount INTEGER,
    voucher_code_template VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    total_available INTEGER,
    total_redeemed INTEGER NOT NULL DEFAULT 0,
    max_redemptions_per_user INTEGER,
    min_tier_required VARCHAR(20),
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    image_url VARCHAR(512),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rewards_active ON loyalty.rewards(is_active);
CREATE INDEX IF NOT EXISTS idx_rewards_tier ON loyalty.rewards(min_tier_required);
CREATE INDEX IF NOT EXISTS idx_rewards_type ON loyalty.rewards(reward_type);
CREATE INDEX IF NOT EXISTS idx_rewards_points_cost ON loyalty.rewards(points_cost);

-- Loyalty Redemptions Table
CREATE TABLE IF NOT EXISTS loyalty.loyalty_redemptions (
    id VARCHAR PRIMARY KEY,
    account_id VARCHAR NOT NULL,
    reward_id VARCHAR NOT NULL,
    points_spent INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    reward_name VARCHAR(255) NOT NULL,
    reward_type VARCHAR(50) NOT NULL,
    reward_value JSONB,
    voucher_code VARCHAR(255) UNIQUE,
    fulfilled_at TIMESTAMP WITH TIME ZONE,
    fulfilled_by VARCHAR,
    fulfillment_notes TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES loyalty.loyalty_accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (reward_id) REFERENCES loyalty.rewards(id)
);

CREATE INDEX IF NOT EXISTS idx_redemptions_account ON loyalty.loyalty_redemptions(account_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_reward ON loyalty.loyalty_redemptions(reward_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_status ON loyalty.loyalty_redemptions(status);
CREATE INDEX IF NOT EXISTS idx_redemptions_voucher_code ON loyalty.loyalty_redemptions(voucher_code);
CREATE INDEX IF NOT EXISTS idx_redemptions_created ON loyalty.loyalty_redemptions(created_at);

-- Insert default loyalty rule (1 point per KES 100)
-- Note: gen_random_uuid() requires pgcrypto extension
-- Using a fixed UUID for the default rule
INSERT INTO loyalty.loyalty_rules (
    id,
    name,
    description,
    base_points_per_kes,
    multiplier,
    is_active,
    priority
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Default Points Rule',
    'Default rule: 1 point per KES 100 spent',
    0.01,
    1.0,
    TRUE,
    0
) ON CONFLICT DO NOTHING;

