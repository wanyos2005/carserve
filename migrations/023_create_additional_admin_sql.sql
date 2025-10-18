-- ==============================================
-- CREATE ADDITIONAL ADMIN USER - SQL VERSION
-- ==============================================
-- This script mirrors the create_additional_admin() function from create_admin.py
-- Creates additional admin users (requires existing admin)

-- ==============================================
-- CONFIGURATION - MODIFY THESE VALUES
-- ==============================================

-- Set the email and name for the new admin user
-- Change these values as needed
\set new_admin_email 'john@driveon.com'
\set new_admin_name 'John Doe'

-- ==============================================
-- CREATE ADDITIONAL ADMIN
-- ==============================================

DO $$
DECLARE
    admin_role_id INTEGER;
    new_user_id INTEGER;
    existing_admin_count INTEGER;
    existing_user_role RECORD;
    new_admin_email TEXT := :'new_admin_email';
    new_admin_name TEXT := :'new_admin_name';
BEGIN
    -- Check if admin role exists
    SELECT id INTO admin_role_id FROM users.tbl_auth_roles WHERE name = 'admin';
    
    IF admin_role_id IS NULL THEN
        RAISE EXCEPTION '❌ No admin role found! Run create_admin_user_sql.sql first.';
    END IF;
    
    RAISE NOTICE '✅ Admin role found with ID: %', admin_role_id;
    
    -- Check if at least one admin exists
    SELECT COUNT(*) INTO existing_admin_count
    FROM users.tbl_user_roles 
    WHERE role_id = admin_role_id::VARCHAR AND active = true;
    
    IF existing_admin_count = 0 THEN
        RAISE EXCEPTION '❌ No existing admin found! Run create_admin_user_sql.sql first.';
    END IF;
    
    RAISE NOTICE '✅ Found % existing admin(s)', existing_admin_count;
    
    -- Create or get user
    INSERT INTO users.tbl_auth (
        email, 
        name, 
        verified, 
        auth_provider,
        is_guest,
        created_by_provider_id,
        created_at, 
        updated_at
    ) VALUES (
        new_admin_email,
        new_admin_name,
        true,
        'email',
        false,
        null,
        CURRENT_TIMESTAMP, 
        CURRENT_TIMESTAMP
    ) ON CONFLICT (email) DO UPDATE SET
        name = EXCLUDED.name,
        verified = EXCLUDED.verified,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO new_user_id;
    
    -- If user already existed, get their ID
    IF new_user_id IS NULL THEN
        SELECT id INTO new_user_id FROM users.tbl_auth WHERE email = new_admin_email;
    END IF;
    
    RAISE NOTICE '✅ Created/found user: % (ID: %)', new_admin_email, new_user_id;
    
    -- Check if user already has admin role
    SELECT * INTO existing_user_role
    FROM users.tbl_user_roles
    WHERE user_id = new_user_id AND role_id = admin_role_id::VARCHAR;
    
    IF existing_user_role IS NOT NULL THEN
        IF existing_user_role.active THEN
            RAISE NOTICE '⚠️  % is already an admin!', new_admin_email;
            RETURN;
        ELSE
            -- Reactivate admin role
            UPDATE users.tbl_user_roles 
            SET active = true, updated_at = CURRENT_TIMESTAMP
            WHERE user_id = new_user_id AND role_id = admin_role_id::VARCHAR;
            
            RAISE NOTICE '✅ Reactivated admin role for %', new_admin_email;
            RETURN;
        END IF;
    END IF;
    
    -- Assign admin role to user
    INSERT INTO users.tbl_user_roles (
        user_id, 
        role_id, 
        active, 
        created_at, 
        updated_at
    ) VALUES (
        new_user_id, 
        admin_role_id::VARCHAR, 
        true, 
        CURRENT_TIMESTAMP, 
        CURRENT_TIMESTAMP
    );
    
    RAISE NOTICE '🎉 SUCCESS: % is now an admin!', new_admin_email;
    
END $$;

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- List all current admin users
SELECT 
    u.id,
    u.email,
    u.name,
    u.verified,
    ur.active as admin_active,
    ur.created_at as admin_since
FROM users.tbl_auth u
JOIN users.tbl_user_roles ur ON u.id = ur.user_id
JOIN users.tbl_auth_roles r ON ur.role_id = r.id::VARCHAR
WHERE r.name = 'admin' AND ur.active = true
ORDER BY ur.created_at;

-- ==============================================
-- SUMMARY
-- ==============================================

DO $$
DECLARE
    total_admins INTEGER;
BEGIN
    -- Count total active admin users
    SELECT COUNT(*) INTO total_admins
    FROM users.tbl_user_roles ur
    JOIN users.tbl_auth_roles r ON ur.role_id = r.id::VARCHAR
    WHERE r.name = 'admin' AND ur.active = true;
    
    RAISE NOTICE '🎉 Additional admin created successfully!';
    RAISE NOTICE '📋 Total active admin users: %', total_admins;
    RAISE NOTICE '🚀 Admin system updated!';
END $$;
