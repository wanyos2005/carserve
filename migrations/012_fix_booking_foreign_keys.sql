-- Migration: 012_fix_booking_foreign_keys.sql
-- Description: Fix foreign key column types in booking tables to match models
-- Created: 2025-10-18
-- Author: System

-- Fix bookings.bookings table foreign key columns
ALTER TABLE bookings.bookings 
ALTER COLUMN vehicle_id TYPE VARCHAR USING vehicle_id::VARCHAR,
ALTER COLUMN provider_id TYPE VARCHAR USING provider_id::VARCHAR,
ALTER COLUMN service_id TYPE VARCHAR USING service_id::VARCHAR;

-- Fix bookings.service_logs table foreign key columns
ALTER TABLE bookings.service_logs 
ALTER COLUMN vehicle_id TYPE VARCHAR USING vehicle_id::VARCHAR,
ALTER COLUMN provider_id TYPE VARCHAR USING provider_id::VARCHAR,
ALTER COLUMN service_id TYPE VARCHAR USING service_id::VARCHAR;

-- Add comments to document the changes
COMMENT ON COLUMN bookings.bookings.vehicle_id IS 'Vehicle ID - VARCHAR UUID string';
COMMENT ON COLUMN bookings.bookings.provider_id IS 'Provider ID - VARCHAR UUID string';
COMMENT ON COLUMN bookings.bookings.service_id IS 'Service ID - VARCHAR UUID string';

COMMENT ON COLUMN bookings.service_logs.vehicle_id IS 'Vehicle ID - VARCHAR UUID string';
COMMENT ON COLUMN bookings.service_logs.provider_id IS 'Provider ID - VARCHAR UUID string';
COMMENT ON COLUMN bookings.service_logs.service_id IS 'Service ID - VARCHAR UUID string';
