-- ==============================================
-- FIX ADMIN ROLE ASSIGNMENT
-- ==============================================
-- This migration fixes the admin role assignment issue
-- by adding the missing unique constraint and manually assigning the role

-- ==============================================
-- ADD UNIQUE CONSTRAINT
-- ==============================================

-- Add unique constraint on (user_id, role_id) to tbl_auth_roles
ALTER TABLE users.tbl_auth_roles 
ADD CONSTRAINT unique_user_role UNIQUE (user_id, role_id);

-- ==============================================
-- MANUALLY ASSIGN ADMIN ROLE
-- ==============================================

DO $$
DECLARE
    admin_user_id INTEGER;
    admin_role_id UUID;
BEGIN
    -- Get the admin user ID
    SELECT id INTO admin_user_id FROM users.tbl_auth WHERE email = 'bictoriadonovan@gmail.com';
    
    -- Get the admin role ID
    SELECT id INTO admin_role_id FROM users.tbl_roles WHERE name = 'admin';
    
    IF admin_user_id IS NULL THEN
        RAISE EXCEPTION 'Admin user not found!';
    END IF;
    
    IF admin_role_id IS NULL THEN
        RAISE EXCEPTION 'Admin role not found!';
    END IF;
    
    RAISE NOTICE 'Found admin user ID: %', admin_user_id;
    RAISE NOTICE 'Found admin role ID: %', admin_role_id;
    
    -- Insert the admin role assignment
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
    
    RAISE NOTICE '✅ Successfully assigned admin role to user!';
    
END $$;

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- Verify admin user exists
SELECT 
    id,
    email,
    name,
    verified,
    created_at
FROM users.tbl_auth 
WHERE email = 'bictoriadonovan@gmail.com';

-- Verify admin role assignment
SELECT 
    ur.user_id,
    ur.role_id,
    ur.active,
    u.email,
    u.name,
    r.name as role_name,
    ur.created_at as role_assigned_at
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
BEGIN
    -- Count active admin users
    SELECT COUNT(*) INTO admin_count
    FROM users.tbl_auth_roles ur
    JOIN users.tbl_roles r ON ur.role_id = r.id::VARCHAR
    WHERE r.name = 'admin' AND ur.active = true;
    
    RAISE NOTICE '🎉 Admin role assignment completed!';
    RAISE NOTICE '📊 Active admin users: %', admin_count;
    RAISE NOTICE '🚀 Admin system fully operational!';
END $$;
