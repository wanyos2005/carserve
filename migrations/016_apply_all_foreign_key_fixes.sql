-- ==============================================
-- APPLY ALL PENDING FOREIGN KEY FIXES
-- ==============================================
-- This migration applies all the foreign key column type fixes that haven't been applied yet

-- ==============================================
-- EXPENSES SERVICE FOREIGN KEY FIXES
-- ==============================================
-- Fix foreign key column types in expenses service
-- ALTER TABLE expenses.expenses ALTER COLUMN vehicle_id TYPE VARCHAR USING vehicle_id::VARCHAR;
-- ALTER TABLE expenses.expenses ALTER COLUMN provider_id TYPE VARCHAR USING provider_id::VARCHAR;

-- Add comments for clarity
-- COMMENT ON COLUMN expenses.expenses.vehicle_id IS 'Vehicle ID - VARCHAR UUID string';
-- COMMENT ON COLUMN expenses.expenses.provider_id IS 'Provider ID - VARCHAR UUID string';

-- ==============================================
-- INSURANCE SERVICE FOREIGN KEY FIXES
-- ==============================================
-- Fix foreign key column types in insurance service

-- Fix insurance.insurance_policies foreign key column types
ALTER TABLE insurance.insurance_policies ALTER COLUMN vehicle_id TYPE VARCHAR USING vehicle_id::VARCHAR;
ALTER TABLE insurance.insurance_policies ALTER COLUMN provider_id TYPE VARCHAR USING provider_id::VARCHAR;

-- Fix insurance.insurance_claims foreign key column types
ALTER TABLE insurance.insurance_claims ALTER COLUMN vehicle_id TYPE VARCHAR USING vehicle_id::VARCHAR;
ALTER TABLE insurance.insurance_claims ALTER COLUMN policy_id TYPE VARCHAR USING policy_id::VARCHAR;

-- Fix insurance.risk_scores foreign key column types
ALTER TABLE insurance.risk_scores ALTER COLUMN vehicle_id TYPE VARCHAR USING vehicle_id::VARCHAR;

-- Fix insurance.data_feed_logs foreign key column types
ALTER TABLE insurance.data_feed_logs ALTER COLUMN vehicle_id TYPE VARCHAR USING vehicle_id::VARCHAR;

-- Add comments for clarity
COMMENT ON COLUMN insurance.insurance_policies.vehicle_id IS 'Vehicle ID - VARCHAR UUID string';
COMMENT ON COLUMN insurance.insurance_policies.provider_id IS 'Provider ID - VARCHAR UUID string';
COMMENT ON COLUMN insurance.insurance_claims.vehicle_id IS 'Vehicle ID - VARCHAR UUID string';
COMMENT ON COLUMN insurance.insurance_claims.policy_id IS 'Policy ID - VARCHAR UUID string';
COMMENT ON COLUMN insurance.risk_scores.vehicle_id IS 'Vehicle ID - VARCHAR UUID string';
COMMENT ON COLUMN insurance.data_feed_logs.vehicle_id IS 'Vehicle ID - VARCHAR UUID string';

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================
-- Verify the column types have been updated correctly
SELECT 
    table_schema,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema IN ('expenses', 'insurance') 
    AND column_name IN ('vehicle_id', 'provider_id', 'policy_id')
ORDER BY table_schema, table_name, column_name;
