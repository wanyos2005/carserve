-- Migration: Add fcm_token column to users.tbl_auth table
-- Description: Adds Firebase Cloud Messaging token column for push notifications
-- Created: 2025-01-27
-- Issue: Column fcm_token missing from users.tbl_auth table causing SQLAlchemy errors

-- ==============================================
-- ADD FCM_TOKEN COLUMN TO USERS.TBL_AUTH
-- ==============================================

-- Add the fcm_token column to the users.tbl_auth table
ALTER TABLE users.tbl_auth 
ADD COLUMN IF NOT EXISTS fcm_token VARCHAR;

-- Add comment for documentation
COMMENT ON COLUMN users.tbl_auth.fcm_token IS 'Firebase Cloud Messaging token for push notifications';

-- Add index for better query performance (optional, since it's nullable)
-- CREATE INDEX IF NOT EXISTS idx_users_tbl_auth_fcm_token ON users.tbl_auth(fcm_token);

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- Verify the column was added successfully
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    -- Check if the fcm_token column exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'users' 
        AND table_name = 'tbl_auth' 
        AND column_name = 'fcm_token'
    ) INTO column_exists;
    
    IF column_exists THEN
        RAISE NOTICE '✅ fcm_token column added successfully to users.tbl_auth';
    ELSE
        RAISE EXCEPTION '❌ Failed to add fcm_token column to users.tbl_auth';
    END IF;
END $$;

-- ==============================================
-- SUCCESS MESSAGE
-- ==============================================

DO $$
BEGIN
    RAISE NOTICE '🎉 FCM Token column migration completed successfully!';
    RAISE NOTICE '📋 Added column:';
    RAISE NOTICE '  - users.tbl_auth.fcm_token (VARCHAR, nullable)';
    RAISE NOTICE '📋 Purpose: Firebase Cloud Messaging token for push notifications';
    RAISE NOTICE '🚀 User service should now work without SQLAlchemy errors!';
END $$;
