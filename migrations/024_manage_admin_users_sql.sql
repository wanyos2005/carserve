-- ==============================================
-- MANAGE ADMIN USERS - SQL VERSION
-- ==============================================
-- This script provides admin management functions similar to create_admin.py
-- Functions: list admins, remove admin privileges

-- ==============================================
-- LIST ALL ADMIN USERS
-- ==============================================

-- Function to list all admin users
DO $$
DECLARE
    admin_record RECORD;
    admin_count INTEGER := 0;
BEGIN
    RAISE NOTICE '📋 Current Admin Users:';
    RAISE NOTICE '--------------------------------------------------';
    
    FOR admin_record IN
        SELECT 
            u.id,
            u.email,
            u.name,
            u.verified,
            ur.active as admin_active,
            ur.created_at as admin_since,
            r.name as role_name
        FROM users.tbl_auth u
        JOIN users.tbl_user_roles ur ON u.id = ur.user_id
        JOIN users.tbl_auth_roles r ON ur.role_id = r.id::VARCHAR
        WHERE r.name = 'admin' AND ur.active = true
        ORDER BY ur.created_at
    LOOP
        admin_count := admin_count + 1;
        RAISE NOTICE '👤 % (%) - ID: % - Admin since: %', 
            COALESCE(admin_record.name, 'No name'), 
            admin_record.email, 
            admin_record.id,
            admin_record.admin_since;
    END LOOP;
    
    IF admin_count = 0 THEN
        RAISE NOTICE '❌ No admin users found!';
    ELSE
        RAISE NOTICE '📊 Total admin users: %', admin_count;
    END IF;
    
END $$;

-- ==============================================
-- REMOVE ADMIN PRIVILEGES
-- ==============================================

-- Function to remove admin privileges from a user
-- Change the email below to remove admin privileges from a specific user
DO $$
DECLARE
    target_email TEXT := 'john@driveon.com';  -- Change this email as needed
    target_user_id INTEGER;
    admin_role_id INTEGER;
    affected_rows INTEGER;
BEGIN
    -- Check if user exists
    SELECT id INTO target_user_id FROM users.tbl_auth WHERE email = target_email;
    
    IF target_user_id IS NULL THEN
        RAISE NOTICE '❌ User % not found!', target_email;
        RETURN;
    END IF;
    
    -- Get admin role ID
    SELECT id INTO admin_role_id FROM users.tbl_auth_roles WHERE name = 'admin';
    
    IF admin_role_id IS NULL THEN
        RAISE NOTICE '❌ No admin role found!';
        RETURN;
    END IF;
    
    -- Check if user has admin role
    IF NOT EXISTS (
        SELECT 1 FROM users.tbl_user_roles 
        WHERE user_id = target_user_id AND role_id = admin_role_id::VARCHAR
    ) THEN
        RAISE NOTICE '❌ % is not an admin!', target_email;
        RETURN;
    END IF;
    
    -- Remove admin privileges (set active = false)
    UPDATE users.tbl_user_roles 
    SET active = false, updated_at = CURRENT_TIMESTAMP
    WHERE user_id = target_user_id AND role_id = admin_role_id::VARCHAR;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    IF affected_rows > 0 THEN
        RAISE NOTICE '✅ Removed admin privileges from %', target_email;
    ELSE
        RAISE NOTICE '⚠️  No changes made for %', target_email;
    END IF;
    
END $$;

-- ==============================================
-- REACTIVATE ADMIN PRIVILEGES
-- ==============================================

-- Function to reactivate admin privileges for a user
-- Change the email below to reactivate admin privileges for a specific user
DO $$
DECLARE
    target_email TEXT := 'john@driveon.com';  -- Change this email as needed
    target_user_id INTEGER;
    admin_role_id INTEGER;
    affected_rows INTEGER;
BEGIN
    -- Check if user exists
    SELECT id INTO target_user_id FROM users.tbl_auth WHERE email = target_email;
    
    IF target_user_id IS NULL THEN
        RAISE NOTICE '❌ User % not found!', target_email;
        RETURN;
    END IF;
    
    -- Get admin role ID
    SELECT id INTO admin_role_id FROM users.tbl_auth_roles WHERE name = 'admin';
    
    IF admin_role_id IS NULL THEN
        RAISE NOTICE '❌ No admin role found!';
        RETURN;
    END IF;
    
    -- Check if user has admin role (even if inactive)
    IF NOT EXISTS (
        SELECT 1 FROM users.tbl_user_roles 
        WHERE user_id = target_user_id AND role_id = admin_role_id::VARCHAR
    ) THEN
        RAISE NOTICE '❌ % has never been an admin!', target_email;
        RETURN;
    END IF;
    
    -- Reactivate admin privileges
    UPDATE users.tbl_user_roles 
    SET active = true, updated_at = CURRENT_TIMESTAMP
    WHERE user_id = target_user_id AND role_id = admin_role_id::VARCHAR;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    IF affected_rows > 0 THEN
        RAISE NOTICE '✅ Reactivated admin privileges for %', target_email;
    ELSE
        RAISE NOTICE '⚠️  No changes made for %', target_email;
    END IF;
    
END $$;

-- ==============================================
-- DETAILED ADMIN REPORT
-- ==============================================

-- Generate a detailed report of all admin users
SELECT 
    'ADMIN USERS REPORT' as report_title,
    CURRENT_TIMESTAMP as generated_at;

-- Active admin users
SELECT 
    'ACTIVE ADMINS' as section,
    u.id,
    u.email,
    u.name,
    u.verified,
    u.created_at as user_created,
    ur.created_at as admin_since,
    ur.updated_at as last_updated
FROM users.tbl_auth u
JOIN users.tbl_user_roles ur ON u.id = ur.user_id
JOIN users.tbl_auth_roles r ON ur.role_id = r.id::VARCHAR
WHERE r.name = 'admin' AND ur.active = true
ORDER BY ur.created_at;

-- Inactive admin users (removed admins)
SELECT 
    'INACTIVE ADMINS' as section,
    u.id,
    u.email,
    u.name,
    u.verified,
    u.created_at as user_created,
    ur.created_at as admin_since,
    ur.updated_at as last_updated
FROM users.tbl_auth u
JOIN users.tbl_user_roles ur ON u.id = ur.user_id
JOIN users.tbl_auth_roles r ON ur.role_id = r.id::VARCHAR
WHERE r.name = 'admin' AND ur.active = false
ORDER BY ur.updated_at DESC;

-- ==============================================
-- SUMMARY STATISTICS
-- ==============================================

DO $$
DECLARE
    total_users INTEGER;
    active_admins INTEGER;
    inactive_admins INTEGER;
    admin_role_count INTEGER;
BEGIN
    -- Count total users
    SELECT COUNT(*) INTO total_users FROM users.tbl_auth;
    
    -- Count active admins
    SELECT COUNT(*) INTO active_admins
    FROM users.tbl_user_roles ur
    JOIN users.tbl_auth_roles r ON ur.role_id = r.id::VARCHAR
    WHERE r.name = 'admin' AND ur.active = true;
    
    -- Count inactive admins
    SELECT COUNT(*) INTO inactive_admins
    FROM users.tbl_user_roles ur
    JOIN users.tbl_auth_roles r ON ur.role_id = r.id::VARCHAR
    WHERE r.name = 'admin' AND ur.active = false;
    
    -- Count admin roles
    SELECT COUNT(*) INTO admin_role_count FROM users.tbl_auth_roles WHERE name = 'admin';
    
    RAISE NOTICE '📊 ADMIN SYSTEM STATISTICS:';
    RAISE NOTICE '   - Total users: %', total_users;
    RAISE NOTICE '   - Active admins: %', active_admins;
    RAISE NOTICE '   - Inactive admins: %', inactive_admins;
    RAISE NOTICE '   - Admin roles: %', admin_role_count;
    
END $$;
