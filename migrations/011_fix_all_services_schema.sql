-- Migration: 011_fix_all_services_schema.sql
-- Description: Fix all service schema mismatches - comprehensive schema alignment
-- Created: 2025-10-18
-- Author: System

-- ==============================================
-- BOOKING SERVICE SCHEMA FIXES
-- ==============================================

-- Fix bookings.bookings table ID column type mismatch
-- First, drop the existing primary key constraint
ALTER TABLE bookings.bookings DROP CONSTRAINT IF EXISTS bookings_pkey;

-- Change the id column from SERIAL to VARCHAR
ALTER TABLE bookings.bookings ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;

-- Add back the primary key constraint
ALTER TABLE bookings.bookings ADD PRIMARY KEY (id);

-- Drop the sequence since we're using UUID strings
DROP SEQUENCE IF EXISTS bookings.bookings_id_seq CASCADE;

-- Add missing columns
ALTER TABLE bookings.bookings 
ADD COLUMN IF NOT EXISTS user_id INTEGER,
ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS location JSONB,
ADD COLUMN IF NOT EXISTS meta JSONB;

-- Rename booking_date to scheduled_at if it exists and scheduled_at doesn't
-- (This is a conditional rename - we'll keep both for now)
-- ALTER TABLE bookings.bookings RENAME COLUMN booking_date TO scheduled_at;

-- Fix bookings.service_logs table ID column type mismatch
-- First, drop the existing primary key constraint
ALTER TABLE bookings.service_logs DROP CONSTRAINT IF EXISTS service_logs_pkey;

-- Change the id column from SERIAL to VARCHAR
ALTER TABLE bookings.service_logs ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;

-- Add back the primary key constraint
ALTER TABLE bookings.service_logs ADD PRIMARY KEY (id);

-- Drop the sequence since we're using UUID strings
DROP SEQUENCE IF EXISTS bookings.service_logs_id_seq CASCADE;

-- Add missing columns
ALTER TABLE bookings.service_logs 
ADD COLUMN IF NOT EXISTS user_id INTEGER,
ADD COLUMN IF NOT EXISTS provider_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS provider_contact JSONB,
ADD COLUMN IF NOT EXISTS service_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS service_items JSONB,
ADD COLUMN IF NOT EXISTS mileage_km INTEGER,
ADD COLUMN IF NOT EXISTS performed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS next_service_km INTEGER,
ADD COLUMN IF NOT EXISTS next_service_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS served_by VARCHAR(255),
ADD COLUMN IF NOT EXISTS served_by_contact VARCHAR(255),
ADD COLUMN IF NOT EXISTS logged_by VARCHAR(50) DEFAULT 'user',
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Rename service_date to performed_at if needed
-- ALTER TABLE bookings.service_logs RENAME COLUMN service_date TO performed_at;

-- ==============================================
-- INSURANCE SERVICE SCHEMA FIXES
-- ==============================================

-- Fix insurance.insurance_policies table ID column type mismatch
ALTER TABLE insurance.insurance_policies DROP CONSTRAINT IF EXISTS insurance_policies_pkey;
ALTER TABLE insurance.insurance_policies ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;
ALTER TABLE insurance.insurance_policies ADD PRIMARY KEY (id);
DROP SEQUENCE IF EXISTS insurance.insurance_policies_id_seq CASCADE;

-- Add missing columns
ALTER TABLE insurance.insurance_policies 
ADD COLUMN IF NOT EXISTS commencement_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS premium_amount INTEGER,
ADD COLUMN IF NOT EXISTS coverage_details JSONB,
ADD COLUMN IF NOT EXISTS deductible_amount INTEGER,
ADD COLUMN IF NOT EXISTS renewal_reminder_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Rename columns to match model
ALTER TABLE insurance.insurance_policies RENAME COLUMN start_date TO commencement_date;
ALTER TABLE insurance.insurance_policies RENAME COLUMN end_date TO expiry_date;
ALTER TABLE insurance.insurance_policies RENAME COLUMN premium TO premium_amount;

-- Fix insurance.insurance_claims table ID column type mismatch
ALTER TABLE insurance.insurance_claims DROP CONSTRAINT IF EXISTS insurance_claims_pkey;
ALTER TABLE insurance.insurance_claims ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;
ALTER TABLE insurance.insurance_claims ADD PRIMARY KEY (id);
DROP SEQUENCE IF EXISTS insurance.insurance_claims_id_seq CASCADE;

-- Add missing columns
ALTER TABLE insurance.insurance_claims 
ADD COLUMN IF NOT EXISTS incident_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS estimated_cost INTEGER,
ADD COLUMN IF NOT EXISTS actual_cost INTEGER,
ADD COLUMN IF NOT EXISTS evidence_files JSONB,
ADD COLUMN IF NOT EXISTS repair_quotes JSONB,
ADD COLUMN IF NOT EXISTS assigned_adjuster VARCHAR,
ADD COLUMN IF NOT EXISTS review_notes TEXT,
ADD COLUMN IF NOT EXISTS approved_amount INTEGER,
ADD COLUMN IF NOT EXISTS payment_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Rename amount to actual_cost
ALTER TABLE insurance.insurance_claims RENAME COLUMN amount TO actual_cost;

-- Fix insurance.risk_scores table ID column type mismatch
ALTER TABLE insurance.risk_scores DROP CONSTRAINT IF EXISTS risk_scores_pkey;
ALTER TABLE insurance.risk_scores ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;
ALTER TABLE insurance.risk_scores ADD PRIMARY KEY (id);
DROP SEQUENCE IF EXISTS insurance.risk_scores_id_seq CASCADE;

-- Add missing columns
ALTER TABLE insurance.risk_scores 
ADD COLUMN IF NOT EXISTS vehicle_risk_score INTEGER,
ADD COLUMN IF NOT EXISTS driver_risk_score INTEGER,
ADD COLUMN IF NOT EXISTS combined_risk_score INTEGER,
ADD COLUMN IF NOT EXISTS risk_factors JSONB,
ADD COLUMN IF NOT EXISTS scoring_algorithm_version VARCHAR DEFAULT '1.0',
ADD COLUMN IF NOT EXISTS data_points_used JSONB,
ADD COLUMN IF NOT EXISTS last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Rename score to combined_risk_score
ALTER TABLE insurance.risk_scores RENAME COLUMN score TO combined_risk_score;

-- Fix insurance.insurance_partners table ID column type mismatch
ALTER TABLE insurance.insurance_partners DROP CONSTRAINT IF EXISTS insurance_partners_pkey;
ALTER TABLE insurance.insurance_partners ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;
ALTER TABLE insurance.insurance_partners ADD PRIMARY KEY (id);
DROP SEQUENCE IF EXISTS insurance.insurance_partners_id_seq CASCADE;

-- Add missing columns
ALTER TABLE insurance.insurance_partners 
ADD COLUMN IF NOT EXISTS api_endpoint VARCHAR,
ADD COLUMN IF NOT EXISTS api_key VARCHAR,
ADD COLUMN IF NOT EXISTS webhook_url VARCHAR,
ADD COLUMN IF NOT EXISTS supports_quotes BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS supports_claims BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS supports_data_feeds BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS commission_rate INTEGER,
ADD COLUMN IF NOT EXISTS supported_coverage_types JSONB,
ADD COLUMN IF NOT EXISTS customer_rating INTEGER,
ADD COLUMN IF NOT EXISTS total_reviews INTEGER,
ADD COLUMN IF NOT EXISTS claims_processing_time VARCHAR,
ADD COLUMN IF NOT EXISTS policy_validity_period VARCHAR,
ADD COLUMN IF NOT EXISTS special_features JSONB,
ADD COLUMN IF NOT EXISTS logo_url VARCHAR,
ADD COLUMN IF NOT EXISTS website_url VARCHAR,
ADD COLUMN IF NOT EXISTS established_year INTEGER,
ADD COLUMN IF NOT EXISTS market_share VARCHAR,
ADD COLUMN IF NOT EXISTS awards JSONB,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Fix insurance.data_feed_logs table ID column type mismatch
ALTER TABLE insurance.data_feed_logs DROP CONSTRAINT IF EXISTS data_feed_logs_pkey;
ALTER TABLE insurance.data_feed_logs ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;
ALTER TABLE insurance.data_feed_logs ADD PRIMARY KEY (id);
DROP SEQUENCE IF EXISTS insurance.data_feed_logs_id_seq CASCADE;

-- Add missing columns
ALTER TABLE insurance.data_feed_logs 
ADD COLUMN IF NOT EXISTS data_payload JSONB,
ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS response_data JSONB,
ADD COLUMN IF NOT EXISTS error_message TEXT,
ADD COLUMN IF NOT EXISTS retry_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS max_retries INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP WITH TIME ZONE;

-- Rename data to data_payload
ALTER TABLE insurance.data_feed_logs RENAME COLUMN data TO data_payload;

-- ==============================================
-- EXPENSES SERVICE SCHEMA FIXES
-- ==============================================

-- Fix expenses.expenses table ID column type mismatch
ALTER TABLE expenses.expenses DROP CONSTRAINT IF EXISTS expenses_pkey;
ALTER TABLE expenses.expenses ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;
ALTER TABLE expenses.expenses ADD PRIMARY KEY (id);
DROP SEQUENCE IF EXISTS expenses.expenses_id_seq CASCADE;

-- Add missing columns
ALTER TABLE expenses.expenses 
ADD COLUMN IF NOT EXISTS expense_type VARCHAR,
ADD COLUMN IF NOT EXISTS location VARCHAR;

-- Rename cost to match model (cost is already correct)
-- Rename expense_date to created_at if needed
-- ALTER TABLE expenses.expenses RENAME COLUMN expense_date TO created_at;

-- ==============================================
-- SERVICE PROVIDER SERVICE SCHEMA FIXES
-- ==============================================
-- Note: Service provider schema issues were already resolved in migrations 006, 007, and 008

-- ==============================================
-- CREATE MISSING ALERT TABLES
-- ==============================================

-- Create alerts.alerts table (if not exists)
CREATE TABLE IF NOT EXISTS alerts.alerts (
    id VARCHAR PRIMARY KEY,
    user_id INTEGER NOT NULL,
    type VARCHAR NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    priority INTEGER DEFAULT 1,
    vehicle_id VARCHAR,
    policy_id VARCHAR,
    booking_id VARCHAR,
    provider_id VARCHAR,
    channels JSONB NOT NULL,
    status VARCHAR DEFAULT 'pending',
    scheduled_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    action_url VARCHAR,
    action_text VARCHAR,
    alert_metadata JSONB,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create alerts.notification_logs table (if not exists)
CREATE TABLE IF NOT EXISTS alerts.notification_logs (
    id VARCHAR PRIMARY KEY,
    alert_id VARCHAR,
    user_id INTEGER NOT NULL,
    channel VARCHAR NOT NULL,
    status VARCHAR NOT NULL,
    external_id VARCHAR,
    external_response JSONB,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- CREATE INDEXES FOR PERFORMANCE
-- ==============================================

-- Booking service indexes
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_scheduled_at ON bookings.bookings(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_service_logs_user_id ON bookings.service_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_service_logs_performed_at ON bookings.service_logs(performed_at);

-- Insurance service indexes
CREATE INDEX IF NOT EXISTS idx_insurance_policies_commencement_date ON insurance.insurance_policies(commencement_date);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_expiry_date ON insurance.insurance_policies(expiry_date);
CREATE INDEX IF NOT EXISTS idx_insurance_claims_incident_date ON insurance.insurance_claims(incident_date);
CREATE INDEX IF NOT EXISTS idx_insurance_claims_status ON insurance.insurance_claims(status);
CREATE INDEX IF NOT EXISTS idx_risk_scores_combined_risk_score ON insurance.risk_scores(combined_risk_score);
CREATE INDEX IF NOT EXISTS idx_insurance_partners_is_active ON insurance.insurance_partners(is_active);

-- Expenses service indexes
CREATE INDEX IF NOT EXISTS idx_expenses_expense_type ON expenses.expenses(expense_type);
CREATE INDEX IF NOT EXISTS idx_expenses_location ON expenses.expenses(location);

-- Service provider indexes (already handled in previous migrations)

-- Alert service indexes
CREATE INDEX IF NOT EXISTS idx_alerts_user_id ON alerts.alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts.alerts(type);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts.alerts(status);
CREATE INDEX IF NOT EXISTS idx_alerts_scheduled_at ON alerts.alerts(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_notification_logs_alert_id ON alerts.notification_logs(alert_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON alerts.notification_logs(user_id);

-- ==============================================
-- ADD COMMENTS FOR DOCUMENTATION
-- ==============================================

COMMENT ON COLUMN bookings.bookings.user_id IS 'User who made the booking';
COMMENT ON COLUMN bookings.bookings.scheduled_at IS 'When the service is scheduled';
COMMENT ON COLUMN bookings.bookings.location IS 'Service location details';
COMMENT ON COLUMN bookings.bookings.meta IS 'Additional booking metadata';

COMMENT ON COLUMN insurance.insurance_policies.commencement_date IS 'Policy start date';
COMMENT ON COLUMN insurance.insurance_policies.expiry_date IS 'Policy end date';
COMMENT ON COLUMN insurance.insurance_policies.premium_amount IS 'Premium amount in cents';
COMMENT ON COLUMN insurance.insurance_policies.coverage_details IS 'Detailed coverage information';

COMMENT ON COLUMN expenses.expenses.expense_type IS 'Type of expense (fuel, maintenance, etc.)';
COMMENT ON COLUMN expenses.expenses.location IS 'Where the expense occurred';
