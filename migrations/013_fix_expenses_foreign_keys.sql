-- ==============================================
-- EXPENSES SERVICE FOREIGN KEY FIXES
-- ==============================================
-- Fix foreign key column types in expenses service

-- Fix expenses.expenses foreign key column types
ALTER TABLE expenses.expenses ALTER COLUMN vehicle_id TYPE VARCHAR USING vehicle_id::VARCHAR;
ALTER TABLE expenses.expenses ALTER COLUMN provider_id TYPE VARCHAR USING provider_id::VARCHAR;

-- Add comments for clarity
COMMENT ON COLUMN expenses.expenses.vehicle_id IS 'Vehicle ID - VARCHAR UUID string';
COMMENT ON COLUMN expenses.expenses.provider_id IS 'Provider ID - VARCHAR UUID string';
