-- ==============================================
-- FIX ALERT_RULES CONDITIONS COLUMN ISSUE
-- ==============================================
-- This migration fixes the conditions/trigger_conditions column mismatch

-- ==============================================
-- CHECK CURRENT TABLE STRUCTURE
-- ==============================================

-- First, let's see what columns exist
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'alerts' 
    AND table_name = 'alert_rules'
ORDER BY ordinal_position;

-- ==============================================
-- FIX THE CONDITIONS COLUMN ISSUE
-- ==============================================

-- Drop the NOT NULL constraint from conditions column if it exists
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'alerts' 
        AND table_name = 'alert_rules' 
        AND column_name = 'conditions'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE alerts.alert_rules ALTER COLUMN conditions DROP NOT NULL;
        RAISE NOTICE 'Dropped NOT NULL constraint from conditions column';
    END IF;
END $$;

-- If conditions column exists but trigger_conditions doesn't, rename it
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'alerts' 
        AND table_name = 'alert_rules' 
        AND column_name = 'conditions'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'alerts' 
        AND table_name = 'alert_rules' 
        AND column_name = 'trigger_conditions'
    ) THEN
        ALTER TABLE alerts.alert_rules RENAME COLUMN conditions TO trigger_conditions;
        RAISE NOTICE 'Renamed conditions column to trigger_conditions';
    END IF;
END $$;

-- If both columns exist, copy data from conditions to trigger_conditions and drop conditions
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'alerts' 
        AND table_name = 'alert_rules' 
        AND column_name = 'conditions'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'alerts' 
        AND table_name = 'alert_rules' 
        AND column_name = 'trigger_conditions'
    ) THEN
        -- Copy data from conditions to trigger_conditions where trigger_conditions is null
        UPDATE alerts.alert_rules 
        SET trigger_conditions = conditions 
        WHERE trigger_conditions IS NULL AND conditions IS NOT NULL;
        
        -- Drop the old conditions column
        ALTER TABLE alerts.alert_rules DROP COLUMN conditions;
        RAISE NOTICE 'Copied data from conditions to trigger_conditions and dropped conditions column';
    END IF;
END $$;

-- ==============================================
-- VERIFY THE FIX
-- ==============================================

-- Check the final table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'alerts' 
    AND table_name = 'alert_rules'
ORDER BY ordinal_position;

-- Display summary
DO $$
BEGIN
    RAISE NOTICE '🎉 Alert rules conditions column issue fixed!';
    RAISE NOTICE '📋 Actions taken:';
    RAISE NOTICE '1. Dropped NOT NULL constraint from conditions column';
    RAISE NOTICE '2. Renamed conditions to trigger_conditions if needed';
    RAISE NOTICE '3. Copied data between columns if both existed';
    RAISE NOTICE '4. Dropped old conditions column';
    RAISE NOTICE '🚀 Ready to seed alert rules!';
END $$;
