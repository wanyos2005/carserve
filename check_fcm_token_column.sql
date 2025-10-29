-- Quick check to see if fcm_token column exists in users.tbl_auth
-- Run this to verify the current state before applying migration

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'users' 
AND table_name = 'tbl_auth' 
AND column_name = 'fcm_token';

-- If no rows returned, the column doesn't exist
-- If rows returned, the column exists with the shown properties
