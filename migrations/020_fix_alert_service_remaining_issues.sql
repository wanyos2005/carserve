-- ==============================================
-- FIX REMAINING ALERT SERVICE ISSUES
-- ==============================================
-- This migration fixes the remaining issues from the previous migration

-- ==============================================
-- FIX ALERT_PREFERENCES TABLE
-- ==============================================

-- Add missing columns to alert_preferences
ALTER TABLE alerts.alert_preferences 
ADD COLUMN IF NOT EXISTS frequency VARCHAR DEFAULT 'immediate',
ADD COLUMN IF NOT EXISTS quiet_hours_start VARCHAR,
ADD COLUMN IF NOT EXISTS quiet_hours_end VARCHAR,
ADD COLUMN IF NOT EXISTS timezone VARCHAR DEFAULT 'Africa/Nairobi',
ADD COLUMN IF NOT EXISTS min_priority INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS batch_alerts BOOLEAN DEFAULT false;

-- Rename 'enabled' column to 'is_enabled' to match the model
ALTER TABLE alerts.alert_preferences 
RENAME COLUMN enabled TO is_enabled;

-- ==============================================
-- FIX FOREIGN KEY CONSTRAINT
-- ==============================================

-- Drop existing foreign key if it exists
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_notification_logs_alert_id'
        AND table_schema = 'alerts'
        AND table_name = 'notification_logs'
    ) THEN
        ALTER TABLE alerts.notification_logs DROP CONSTRAINT fk_notification_logs_alert_id;
    END IF;
END $$;

-- Add the foreign key constraint properly
ALTER TABLE alerts.notification_logs 
ADD CONSTRAINT fk_notification_logs_alert_id 
FOREIGN KEY (alert_id) REFERENCES alerts.alerts(id);

-- ==============================================
-- FIX ALERT_RULES TABLE COLUMN NAMES
-- ==============================================

-- Check if 'conditions' column exists and rename it to 'trigger_conditions' if needed
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'alerts' 
        AND table_name = 'alert_rules' 
        AND column_name = 'conditions'
    ) THEN
        ALTER TABLE alerts.alert_rules RENAME COLUMN conditions TO trigger_conditions;
    END IF;
END $$;

-- ==============================================
-- ADD MISSING COMMENTS
-- ==============================================

COMMENT ON COLUMN alerts.alert_preferences.frequency IS 'How often to send alerts: immediate, daily, weekly, never';
COMMENT ON COLUMN alerts.alert_preferences.min_priority IS 'Only send alerts with this priority or higher';
COMMENT ON COLUMN alerts.alert_preferences.batch_alerts IS 'Whether to batch similar alerts together';
COMMENT ON COLUMN alerts.alert_preferences.quiet_hours_start IS 'Start time for quiet hours (e.g., "22:00")';
COMMENT ON COLUMN alerts.alert_preferences.quiet_hours_end IS 'End time for quiet hours (e.g., "08:00")';
COMMENT ON COLUMN alerts.alert_preferences.timezone IS 'User timezone for alert scheduling';

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- Verify alert_preferences table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'alerts' 
    AND table_name = 'alert_preferences'
ORDER BY ordinal_position;

-- Verify alert_rules table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'alerts' 
    AND table_name = 'alert_rules'
ORDER BY ordinal_position;

-- Verify foreign key constraint
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'alerts'
    AND tc.table_name = 'notification_logs';

-- Display summary
DO $$
BEGIN
    RAISE NOTICE '🎉 Alert service remaining issues fixed successfully!';
    RAISE NOTICE '📋 Fixed Issues:';
    RAISE NOTICE '1. Added missing columns to alert_preferences';
    RAISE NOTICE '2. Renamed enabled to is_enabled in alert_preferences';
    RAISE NOTICE '3. Fixed foreign key constraint syntax';
    RAISE NOTICE '4. Renamed conditions to trigger_conditions in alert_rules';
    RAISE NOTICE '5. Added missing column comments';
    RAISE NOTICE '🚀 Alert service schema now fully matches models!';
END $$;
