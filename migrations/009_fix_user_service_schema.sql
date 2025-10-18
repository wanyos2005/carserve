-- Migration: 009_fix_user_service_schema.sql
-- Description: Fix user service schema mismatches - add missing columns and fix OTP table
-- Created: 2025-10-18
-- Author: System

-- Add missing columns to users.tbl_auth table
ALTER TABLE users.tbl_auth 
ADD COLUMN IF NOT EXISTS is_guest BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS created_by_provider_id VARCHAR;

-- Create index on the new provider_id column for better performance
CREATE INDEX IF NOT EXISTS idx_users_tbl_auth_created_by_provider_id ON users.tbl_auth(created_by_provider_id);

-- Update existing users to have is_guest = false (they are not guests)
UPDATE users.tbl_auth SET is_guest = FALSE WHERE is_guest IS NULL;

-- Fix OTP table column name mismatch
-- The model expects 'code' but database has 'otp_code'
ALTER TABLE users.tbl_otp RENAME COLUMN otp_code TO code;

-- Fix provider_user_links table - model expects provider_id as VARCHAR (UUID) but DB has INTEGER
-- First, let's check if we need to change the data type
-- For now, we'll keep it as INTEGER but add a comment
COMMENT ON COLUMN users.provider_user_links.provider_id IS 'Provider ID - should be VARCHAR UUID in future migration';

-- Fix tbl_auth_roles table - model expects role_id as VARCHAR but DB has INTEGER
-- Add a comment for now, will need proper migration later
COMMENT ON COLUMN users.tbl_auth_roles.role_id IS 'Role ID - should be VARCHAR UUID in future migration';

-- Add missing 'active' column to tbl_auth_roles table
ALTER TABLE users.tbl_auth_roles 
ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT TRUE;

-- Add comments to document the new columns
COMMENT ON COLUMN users.tbl_auth.is_guest IS 'True if user was created by a service provider as a guest user';
COMMENT ON COLUMN users.tbl_auth.created_by_provider_id IS 'UUID of the service provider who created this guest user';
COMMENT ON COLUMN users.tbl_auth_roles.active IS 'Whether this role assignment is currently active';
