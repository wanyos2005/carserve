-- ==============================================
-- Delete User: pwsimeon@gmail.com
-- ==============================================
-- This script safely deletes a user and all related records
-- Run this in psql: \i DELETE_USER_COMMANDS.sql
-- Or copy-paste the commands below

-- Step 1: Check if user exists and get user ID
SELECT id, email, name, created_at 
FROM users.tbl_auth 
WHERE email = 'pwsimeon@gmail.com';

-- Step 2: Delete related records first (if CASCADE is not set up)
-- Delete user roles
DELETE FROM users.tbl_auth_roles 
WHERE user_id IN (
    SELECT id FROM users.tbl_auth WHERE email = 'pwsimeon@gmail.com'
);

-- Delete provider user links (this should cascade automatically, but being safe)
DELETE FROM users.provider_user_links 
WHERE user_id IN (
    SELECT id FROM users.tbl_auth WHERE email = 'pwsimeon@gmail.com'
);

-- Delete OTP records for this email
DELETE FROM users.tbl_otp 
WHERE email = 'pwsimeon@gmail.com';

-- Step 3: Delete the user
DELETE FROM users.tbl_auth 
WHERE email = 'pwsimeon@gmail.com';

-- Step 4: Verify deletion
SELECT id, email, name 
FROM users.tbl_auth 
WHERE email = 'pwsimeon@gmail.com';
-- Should return 0 rows

-- ==============================================
-- ALTERNATIVE: Single command with CASCADE (if foreign keys support it)
-- ==============================================
-- This will work if foreign keys have ON DELETE CASCADE
-- DELETE FROM users.tbl_auth WHERE email = 'pwsimeon@gmail.com' CASCADE;

-- ==============================================
-- QUICK ONE-LINER (if you're confident)
-- ==============================================
-- DELETE FROM users.tbl_auth WHERE email = 'pwsimeon@gmail.com';

