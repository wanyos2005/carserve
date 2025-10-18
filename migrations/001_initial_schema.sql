-- Migration: 001_initial_schema.sql
-- Description: Create initial database schema for all services
-- Created: 2025-10-18
-- Author: System

-- Create all schemas
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS vehicles;
CREATE SCHEMA IF NOT EXISTS bookings;
CREATE SCHEMA IF NOT EXISTS insurance;
CREATE SCHEMA IF NOT EXISTS expenses;
CREATE SCHEMA IF NOT EXISTS service_providers;
CREATE SCHEMA IF NOT EXISTS alerts;

-- Users schema tables
CREATE TABLE IF NOT EXISTS users.tbl_auth (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE,
    name VARCHAR,
    phone VARCHAR,
    auth_provider VARCHAR DEFAULT 'email',
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users.tbl_otp (
    id SERIAL PRIMARY KEY,
    email VARCHAR,
    otp_code VARCHAR,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users.tbl_roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users.provider_user_links (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    provider_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users.tbl_auth_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    role_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vehicles schema tables
CREATE TABLE IF NOT EXISTS vehicles.vehicles (
    id SERIAL PRIMARY KEY,
    make VARCHAR,
    model VARCHAR,
    year INTEGER,
    color VARCHAR,
    plate VARCHAR UNIQUE,
    vin VARCHAR UNIQUE,
    fuel_type VARCHAR,
    transmission VARCHAR,
    owner_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bookings schema tables
CREATE TABLE IF NOT EXISTS bookings.bookings (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER,
    service_id INTEGER,
    provider_id INTEGER,
    booking_date TIMESTAMP,
    status VARCHAR DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bookings.service_logs (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER,
    service_id INTEGER,
    provider_id INTEGER,
    service_date TIMESTAMP,
    cost DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insurance schema tables
CREATE TABLE IF NOT EXISTS insurance.insurance_partners (
    id SERIAL PRIMARY KEY,
    name VARCHAR,
    code VARCHAR UNIQUE,
    contact_info JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS insurance.insurance_policies (
    id SERIAL PRIMARY KEY,
    policy_number VARCHAR UNIQUE,
    insurance_type VARCHAR,
    provider_id INTEGER,
    vehicle_id INTEGER,
    owner_id INTEGER,
    premium DECIMAL(10,2),
    start_date DATE,
    end_date DATE,
    status VARCHAR DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS insurance.risk_scores (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    vehicle_id INTEGER,
    score DECIMAL(5,2),
    factors JSONB,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS insurance.data_feed_logs (
    id SERIAL PRIMARY KEY,
    feed_type VARCHAR,
    partner_id INTEGER,
    user_id INTEGER,
    vehicle_id INTEGER,
    data JSONB,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS insurance.insurance_claims (
    id SERIAL PRIMARY KEY,
    claim_number VARCHAR UNIQUE,
    policy_id INTEGER,
    claim_type VARCHAR,
    user_id INTEGER,
    vehicle_id INTEGER,
    amount DECIMAL(10,2),
    status VARCHAR DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Expenses schema tables
CREATE TABLE IF NOT EXISTS expenses.expenses (
    id SERIAL PRIMARY KEY,
    vehicle_id INTEGER,
    owner_id INTEGER,
    provider_id INTEGER,
    expense_type VARCHAR,
    cost DECIMAL(10,2),
    location VARCHAR,
    description TEXT,
    expense_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Service Providers schema tables
CREATE TABLE IF NOT EXISTS service_providers.provider_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS service_providers.service_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS service_providers.providers (
    id SERIAL PRIMARY KEY,
    name VARCHAR,
    contact_info JSONB,
    location VARCHAR,
    rating DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS service_providers.services (
    id SERIAL PRIMARY KEY,
    name VARCHAR,
    description TEXT,
    category_id INTEGER,
    base_price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS service_providers.provider_services (
    id SERIAL PRIMARY KEY,
    provider_id INTEGER,
    service_id INTEGER,
    price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS service_providers.service_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS service_providers.service_template_items (
    id SERIAL PRIMARY KEY,
    template_id INTEGER,
    service_id INTEGER,
    quantity INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alerts schema tables (these already exist)
CREATE TABLE IF NOT EXISTS alerts.alert_preferences (
    id VARCHAR PRIMARY KEY,
    user_id INTEGER NOT NULL,
    alert_type VARCHAR NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    channels JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alerts.alert_rules (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    alert_type VARCHAR NOT NULL,
    conditions JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alerts.alert_history (
    id VARCHAR PRIMARY KEY,
    user_id INTEGER NOT NULL,
    alert_type VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR NOT NULL,
    channel VARCHAR NOT NULL,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alerts.notification_templates (
    id VARCHAR PRIMARY KEY,
    alert_type VARCHAR NOT NULL,
    channel VARCHAR NOT NULL,
    subject VARCHAR,
    template TEXT NOT NULL,
    variables JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_tbl_auth_email ON users.tbl_auth(email);
CREATE INDEX IF NOT EXISTS idx_users_tbl_auth_phone ON users.tbl_auth(phone);
CREATE INDEX IF NOT EXISTS idx_vehicles_plate ON vehicles.vehicles(plate);
CREATE INDEX IF NOT EXISTS idx_vehicles_owner_id ON vehicles.vehicles(owner_id);
CREATE INDEX IF NOT EXISTS idx_bookings_vehicle_id ON bookings.bookings(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_bookings_provider_id ON bookings.bookings(provider_id);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_vehicle_id ON insurance.insurance_policies(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_expenses_vehicle_id ON expenses.expenses(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_expenses_owner_id ON expenses.expenses(owner_id);

-- Insert some basic data
INSERT INTO users.tbl_roles (name, description) VALUES 
('admin', 'Administrator role'),
('user', 'Regular user role'),
('provider', 'Service provider role')
ON CONFLICT (name) DO NOTHING;

INSERT INTO service_providers.provider_categories (name, description) VALUES 
('Mechanical', 'Mechanical services'),
('Electrical', 'Electrical services'),
('Bodywork', 'Bodywork and paint services'),
('Tire', 'Tire services')
ON CONFLICT (name) DO NOTHING;

INSERT INTO service_providers.service_categories (name, description) VALUES 
('Maintenance', 'Regular maintenance services'),
('Repair', 'Repair services'),
('Inspection', 'Vehicle inspection services'),
('Emergency', 'Emergency services')
ON CONFLICT (name) DO NOTHING;
