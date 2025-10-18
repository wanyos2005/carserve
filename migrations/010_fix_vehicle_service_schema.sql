-- Migration: 010_fix_vehicle_service_schema.sql
-- Description: Fix vehicle service schema mismatches - add missing columns and fix data types
-- Created: 2025-10-18
-- Author: System

-- Add missing columns to vehicles.vehicles table
ALTER TABLE vehicles.vehicles 
ADD COLUMN IF NOT EXISTS mileage INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS yom INTEGER,
ADD COLUMN IF NOT EXISTS guest_owner_name VARCHAR,
ADD COLUMN IF NOT EXISTS guest_owner_email VARCHAR,
ADD COLUMN IF NOT EXISTS guest_owner_phone VARCHAR,
ADD COLUMN IF NOT EXISTS created_by_provider_id VARCHAR;

-- Create indexes on new columns for better performance
CREATE INDEX IF NOT EXISTS idx_vehicles_mileage ON vehicles.vehicles(mileage);
CREATE INDEX IF NOT EXISTS idx_vehicles_yom ON vehicles.vehicles(yom);
CREATE INDEX IF NOT EXISTS idx_vehicles_guest_owner_email ON vehicles.vehicles(guest_owner_email);
CREATE INDEX IF NOT EXISTS idx_vehicles_created_by_provider_id ON vehicles.vehicles(created_by_provider_id);

-- Copy year data to yom column for existing records
UPDATE vehicles.vehicles SET yom = year WHERE yom IS NULL AND year IS NOT NULL;

-- Add comments to document the new columns
COMMENT ON COLUMN vehicles.vehicles.mileage IS 'Vehicle mileage in kilometers/miles';
COMMENT ON COLUMN vehicles.vehicles.yom IS 'Year of manufacture';
COMMENT ON COLUMN vehicles.vehicles.guest_owner_name IS 'Name of guest owner (when vehicle is not linked to registered user)';
COMMENT ON COLUMN vehicles.vehicles.guest_owner_email IS 'Email of guest owner';
COMMENT ON COLUMN vehicles.vehicles.guest_owner_phone IS 'Phone of guest owner';
COMMENT ON COLUMN vehicles.vehicles.created_by_provider_id IS 'UUID of the service provider who created this guest vehicle';

-- Fix the ID column type mismatch - change from SERIAL to VARCHAR UUID
-- First, drop the existing primary key constraint
ALTER TABLE vehicles.vehicles DROP CONSTRAINT IF EXISTS vehicles_pkey;

-- Change the id column from SERIAL to VARCHAR
ALTER TABLE vehicles.vehicles ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR;

-- Add back the primary key constraint
ALTER TABLE vehicles.vehicles ADD PRIMARY KEY (id);

-- Update the sequence to be compatible with UUID strings (we'll disable auto-increment)
-- Since we're using UUID strings, we don't need the sequence anymore
DROP SEQUENCE IF EXISTS vehicles.vehicles_id_seq CASCADE;

COMMENT ON COLUMN vehicles.vehicles.id IS 'Vehicle ID - VARCHAR UUID string';
