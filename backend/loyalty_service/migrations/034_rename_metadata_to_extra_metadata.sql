-- Migration: Rename metadata columns to extra_metadata
-- Description: Rename metadata columns to extra_metadata to avoid SQLAlchemy reserved name conflict
-- Created: 2025-11-02

-- Rename metadata column in loyalty_transactions table
ALTER TABLE IF EXISTS loyalty.loyalty_transactions 
    RENAME COLUMN metadata TO extra_metadata;

-- Rename metadata column in rewards table
ALTER TABLE IF EXISTS loyalty.rewards 
    RENAME COLUMN metadata TO extra_metadata;

-- Note: provider_loyalty_configs.extra_metadata was already created correctly in migration 033


