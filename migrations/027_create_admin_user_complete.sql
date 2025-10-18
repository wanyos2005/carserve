-- ==============================================
-- CREATE ADMIN USER COMPLETE
-- ==============================================
-- This migration creates the admin user and assigns the role properly

-- ==============================================
-- CREATE ADMIN USER
-- ==============================================

DO $$
DECLARE
    admin_user_id INTEGER;
    admin_role_id UUID;
    existing_user_id INTEGER;
BEGIN
    -- Check if admin user already exists
    SELECT id INTO existing_user_id FROM users.tbl_auth WHERE email = 'bictoriadonovan@gmail.com';
    
    IF existing_user_id IS NOT NULL THEN
        RAISE NOTICE 'Admin user already exists with ID: %', existing_user_id;
        admin_user_id := existing_user_id;
    ELSE
        -- Create the admin user
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
            'bictoriadonovan@gmail.com',
            'System Administrator',
            true,
            'email',
            false,
            null,
            CURRENT_TIMESTAMP, 
            CURRENT_TIMESTAMP
        ) RETURNING id INTO admin_user_id;
        
        RAISE NOTICE '✅ Created admin user: bictoriadonovan@gmail.com (ID: %)', admin_user_id;
    END IF;
    
    -- Get admin role ID
    SELECT id INTO admin_role_id FROM users.tbl_roles WHERE name = 'admin';
    
    IF admin_role_id IS NULL THEN
        RAISE EXCEPTION 'Admin role not found!';
    END IF;
    
    RAISE NOTICE 'Found admin role ID: %', admin_role_id;
    
    -- Check if role assignment already exists
    IF EXISTS (
        SELECT 1 FROM users.tbl_auth_roles 
        WHERE user_id = admin_user_id AND role_id = admin_role_id::VARCHAR
    ) THEN
        -- Update existing role assignment to active
        UPDATE users.tbl_auth_roles 
        SET active = true, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = admin_user_id AND role_id = admin_role_id::VARCHAR;
        
        RAISE NOTICE '✅ Updated existing admin role assignment';
    ELSE
        -- Create new role assignment
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
        );
        
        RAISE NOTICE '✅ Created new admin role assignment';
    END IF;
    
    RAISE NOTICE '🎉 SUCCESS: bictoriadonovan@gmail.com is now an admin!';
    
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
    auth_provider,
    is_guest,
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
    total_users INTEGER;
BEGIN
    -- Count total users
    SELECT COUNT(*) INTO total_users FROM users.tbl_auth;
    
    -- Count active admin users
    SELECT COUNT(*) INTO admin_count
    FROM users.tbl_auth_roles ur
    JOIN users.tbl_roles r ON ur.role_id = r.id::VARCHAR
    WHERE r.name = 'admin' AND ur.active = true;
    
    RAISE NOTICE '🎉 Admin user creation completed!';
    RAISE NOTICE '📊 Statistics:';
    RAISE NOTICE '   - Total users: %', total_users;
    RAISE NOTICE '   - Active admin users: %', admin_count;
    RAISE NOTICE '🚀 Admin system fully operational!';
END $$;
