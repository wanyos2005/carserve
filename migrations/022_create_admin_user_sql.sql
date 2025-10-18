-- ==============================================
-- CREATE ADMIN USER - SQL VERSION
-- ==============================================
-- This script mirrors the functionality of create_admin.py
-- Creates the first admin user and admin role

-- ==============================================
-- CREATE ADMIN ROLE
-- ==============================================

-- Create admin role if it doesn't exist (in tbl_roles table)
INSERT INTO users.tbl_roles (id, name, created_at)
SELECT gen_random_uuid(), 'admin', CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM users.tbl_roles WHERE name = 'admin'
);

-- Get the admin role ID for later use
DO $$
DECLARE
    admin_role_id UUID;
    admin_user_id INTEGER;
    existing_admin_count INTEGER;
BEGIN
    -- Get admin role ID
    SELECT id INTO admin_role_id FROM users.tbl_roles WHERE name = 'admin';
    
    IF admin_role_id IS NULL THEN
        RAISE EXCEPTION 'Failed to create or find admin role';
    END IF;
    
    RAISE NOTICE '✅ Admin role created/found with ID: %', admin_role_id;
    
    -- Check if any admin already exists
    SELECT COUNT(*) INTO existing_admin_count
    FROM users.tbl_auth_roles 
    WHERE role_id = admin_role_id::VARCHAR AND active = true;
    
    IF existing_admin_count > 0 THEN
        RAISE NOTICE '⚠️  Admin already exists! Use create_additional_admin.sql instead.';
        RAISE NOTICE '📋 Current admins:';
        
        -- List existing admins
        FOR admin_user_id IN 
            SELECT ur.user_id 
            FROM users.tbl_auth_roles ur 
            WHERE ur.role_id = admin_role_id::VARCHAR AND ur.active = true
        LOOP
            RAISE NOTICE '👤 User ID: %', admin_user_id;
        END LOOP;
        
        RETURN;
    END IF;
    
    -- Create the first admin user
    -- You can modify these values as needed
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
        'bictoriadonovan@gmail.com',  -- Change this email as needed
        'System Administrator',  -- Change this name as needed
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
    RETURNING id INTO admin_user_id;
    
    -- If user already existed, get their ID
    IF admin_user_id IS NULL THEN
        SELECT id INTO admin_user_id FROM users.tbl_auth WHERE email = 'bictoriadonovan@gmail.com';
    END IF;
    
    RAISE NOTICE '✅ Created/found admin user: bictoriadonovan@gmail.com (ID: %)', admin_user_id;
    
    -- Assign admin role to user
    INSERT INTO users.tbl_auth_roles (
        user_id, 
        role_id, 
        active, 
        created_at, 
        updated_at
    ) VALUES (
        admin_user_id, 
        admin_role_id::VARCHAR, 
        true, 
        CURRENT_TIMESTAMP, 
        CURRENT_TIMESTAMP
    ) ON CONFLICT (user_id, role_id) DO UPDATE SET
        active = true,
        updated_at = CURRENT_TIMESTAMP;
    
    RAISE NOTICE '🎉 SUCCESS: bictoriadonovan@gmail.com is now an admin!';
    
END $$;

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- Verify admin role was created
SELECT 
    id,
    name,
    created_at
FROM users.tbl_roles 
WHERE name = 'admin';

-- Verify admin user was created
SELECT 
    u.id,
    u.email,
    u.name,
    u.verified,
    u.created_at
FROM users.tbl_auth u
WHERE u.email = 'bictoriadonovan@gmail.com';

-- Verify admin role assignment
SELECT 
    ur.user_id,
    ur.role_id,
    ur.active,
    u.email,
    u.name,
    r.name as role_name
FROM users.tbl_auth_roles ur
JOIN users.tbl_auth u ON ur.user_id = u.id
JOIN users.tbl_roles r ON ur.role_id = r.id::VARCHAR
WHERE r.name = 'admin' AND ur.active = true;

-- ==============================================
-- SUMMARY
-- ==============================================

DO $$
DECLARE
    admin_count INTEGER;
    role_count INTEGER;
BEGIN
    -- Count admin roles
    SELECT COUNT(*) INTO role_count FROM users.tbl_roles WHERE name = 'admin';
    
    -- Count active admin users
    SELECT COUNT(*) INTO admin_count
    FROM users.tbl_auth_roles ur
    JOIN users.tbl_roles r ON ur.role_id = r.id::VARCHAR
    WHERE r.name = 'admin' AND ur.active = true;
    
    RAISE NOTICE '🎉 Admin setup completed successfully!';
    RAISE NOTICE '📋 Summary:';
    RAISE NOTICE '   - Admin roles: %', role_count;
    RAISE NOTICE '   - Active admin users: %', admin_count;
    RAISE NOTICE '🚀 Admin system ready!';
END $$;
