-- ==============================================
-- FIX USER SERVICE COMPLETE SCHEMA
-- ==============================================
-- This migration completely fixes the user service database schema
-- to match the current models and schemas

-- ==============================================
-- DROP EXISTING TABLES (if they exist with wrong structure)
-- ==============================================

-- Drop existing tables in correct order (respecting foreign keys)
DROP TABLE IF EXISTS users.tbl_auth_roles CASCADE;
DROP TABLE IF EXISTS users.tbl_roles CASCADE;
DROP TABLE IF EXISTS users.tbl_otp CASCADE;
DROP TABLE IF EXISTS users.provider_user_links CASCADE;
DROP TABLE IF EXISTS users.tbl_auth CASCADE;

-- ==============================================
-- CREATE USERS.TBL_AUTH TABLE
-- ==============================================

CREATE TABLE users.tbl_auth (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE,
    name VARCHAR,
    phone VARCHAR,
    auth_provider VARCHAR DEFAULT 'email',
    verified BOOLEAN DEFAULT false,
    
    -- NEW FIELDS
    is_guest BOOLEAN DEFAULT false,
    created_by_provider_id VARCHAR,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for tbl_auth
CREATE INDEX idx_tbl_auth_email ON users.tbl_auth(email);
CREATE INDEX idx_tbl_auth_name ON users.tbl_auth(name);
CREATE INDEX idx_tbl_auth_phone ON users.tbl_auth(phone);
CREATE INDEX idx_tbl_auth_auth_provider ON users.tbl_auth(auth_provider);
CREATE INDEX idx_tbl_auth_is_guest ON users.tbl_auth(is_guest);
CREATE INDEX idx_tbl_auth_created_by_provider_id ON users.tbl_auth(created_by_provider_id);

-- ==============================================
-- CREATE USERS.TBL_OTP TABLE
-- ==============================================

CREATE TABLE users.tbl_otp (
    id SERIAL PRIMARY KEY,
    email VARCHAR NOT NULL,
    code VARCHAR NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for tbl_otp
CREATE INDEX idx_tbl_otp_email ON users.tbl_otp(email);
CREATE INDEX idx_tbl_otp_code ON users.tbl_otp(code);
CREATE INDEX idx_tbl_otp_expires_at ON users.tbl_otp(expires_at);

-- ==============================================
-- CREATE USERS.TBL_ROLES TABLE
-- ==============================================

CREATE TABLE users.tbl_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for tbl_roles
CREATE INDEX idx_tbl_roles_name ON users.tbl_roles(name);

-- ==============================================
-- CREATE USERS.TBL_AUTH_ROLES TABLE (User_Roles)
-- ==============================================

CREATE TABLE users.tbl_auth_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INTEGER NOT NULL,
    role_id VARCHAR NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraint
    CONSTRAINT fk_tbl_auth_roles_user_id 
        FOREIGN KEY (user_id) REFERENCES users.tbl_auth(id) ON DELETE CASCADE
);

-- Add indexes for tbl_auth_roles
CREATE INDEX idx_tbl_auth_roles_user_id ON users.tbl_auth_roles(user_id);
CREATE INDEX idx_tbl_auth_roles_role_id ON users.tbl_auth_roles(role_id);
CREATE INDEX idx_tbl_auth_roles_active ON users.tbl_auth_roles(active);

-- ==============================================
-- CREATE USERS.PROVIDER_USER_LINKS TABLE
-- ==============================================

CREATE TABLE users.provider_user_links (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    provider_id VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraint
    CONSTRAINT fk_provider_user_links_user_id 
        FOREIGN KEY (user_id) REFERENCES users.tbl_auth(id) ON DELETE CASCADE
);

-- Add indexes for provider_user_links
CREATE INDEX idx_provider_user_links_user_id ON users.provider_user_links(user_id);
CREATE INDEX idx_provider_user_links_provider_id ON users.provider_user_links(provider_id);

-- ==============================================
-- CREATE DEFAULT ROLES
-- ==============================================

-- Insert default roles
INSERT INTO users.tbl_roles (id, name, created_at) VALUES 
    (gen_random_uuid(), 'admin', CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'user', CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'provider', CURRENT_TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- ==============================================
-- ADD COMMENTS FOR DOCUMENTATION
-- ==============================================

COMMENT ON TABLE users.tbl_auth IS 'Main user authentication table';
COMMENT ON TABLE users.tbl_otp IS 'One-time password codes for email verification';
COMMENT ON TABLE users.tbl_roles IS 'Available user roles in the system';
COMMENT ON TABLE users.tbl_auth_roles IS 'User role assignments';
COMMENT ON TABLE users.provider_user_links IS 'Links between users and service providers';

COMMENT ON COLUMN users.tbl_auth.is_guest IS 'True if user was created by a service provider';
COMMENT ON COLUMN users.tbl_auth.created_by_provider_id IS 'ID of provider that created this user';
COMMENT ON COLUMN users.tbl_auth.auth_provider IS 'Authentication method: email, google, facebook, etc.';
COMMENT ON COLUMN users.tbl_auth.verified IS 'Whether user email is verified';

COMMENT ON COLUMN users.tbl_otp.code IS 'OTP code sent to user for verification';
COMMENT ON COLUMN users.tbl_otp.expires_at IS 'When the OTP code expires';

COMMENT ON COLUMN users.tbl_auth_roles.role_id IS 'String reference to role (not foreign key)';
COMMENT ON COLUMN users.tbl_auth_roles.active IS 'Whether this role assignment is active';

COMMENT ON COLUMN users.provider_user_links.provider_id IS 'UUID of service provider';

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- Verify all tables were created
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_schema = 'users' 
ORDER BY table_name;

-- Verify table structures
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'users' 
ORDER BY table_name, ordinal_position;

-- Verify default roles were created
SELECT 
    id,
    name,
    created_at
FROM users.tbl_roles 
ORDER BY name;

-- ==============================================
-- SUMMARY
-- ==============================================

DO $$
DECLARE
    table_count INTEGER;
    role_count INTEGER;
BEGIN
    -- Count tables
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'users';
    
    -- Count roles
    SELECT COUNT(*) INTO role_count FROM users.tbl_roles;
    
    RAISE NOTICE '🎉 User service schema fixed successfully!';
    RAISE NOTICE '📋 Created Tables:';
    RAISE NOTICE '   - users.tbl_auth (main user table)';
    RAISE NOTICE '   - users.tbl_otp (OTP codes)';
    RAISE NOTICE '   - users.tbl_roles (available roles)';
    RAISE NOTICE '   - users.tbl_auth_roles (user role assignments)';
    RAISE NOTICE '   - users.provider_user_links (user-provider links)';
    RAISE NOTICE '📊 Statistics:';
    RAISE NOTICE '   - Total tables: %', table_count;
    RAISE NOTICE '   - Default roles: %', role_count;
    RAISE NOTICE '🚀 User service ready for admin creation!';
END $$;
