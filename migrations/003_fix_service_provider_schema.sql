-- Migration: 003_fix_service_provider_schema.sql
-- Description: Fix service_providers schema to match actual models
-- Created: 2025-10-18
-- Author: System

-- Drop existing tables if they exist (in correct order due to foreign keys)
DROP TABLE IF EXISTS service_providers.service_template_items CASCADE;
DROP TABLE IF EXISTS service_providers.service_templates CASCADE;
DROP TABLE IF EXISTS service_providers.provider_services CASCADE;
DROP TABLE IF EXISTS service_providers.services CASCADE;
DROP TABLE IF EXISTS service_providers.providers CASCADE;
DROP TABLE IF EXISTS service_providers.service_categories CASCADE;
DROP TABLE IF EXISTS service_providers.provider_categories CASCADE;

-- Create provider_categories table
CREATE TABLE service_providers.provider_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Create service_categories table
CREATE TABLE service_providers.service_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Create providers table
CREATE TABLE service_providers.providers (
    id VARCHAR PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id INTEGER REFERENCES service_providers.provider_categories(id),
    description TEXT,
    contact_info JSONB,
    location JSONB,
    is_registered BOOLEAN DEFAULT FALSE,
    rating NUMERIC(2,1) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create services table (with requirements column)
CREATE TABLE service_providers.services (
    id VARCHAR PRIMARY KEY,
    category_id INTEGER REFERENCES service_providers.service_categories(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    requirements JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create provider_services table
CREATE TABLE service_providers.provider_services (
    id VARCHAR PRIMARY KEY,
    provider_id VARCHAR REFERENCES service_providers.providers(id),
    service_id VARCHAR REFERENCES service_providers.services(id),
    display_name VARCHAR(255),
    price VARCHAR(50),
    duration VARCHAR(50),
    booking_required BOOLEAN DEFAULT FALSE,
    extra_data JSONB DEFAULT '{}'::jsonb
);

-- Create service_templates table
CREATE TABLE service_providers.service_templates (
    id VARCHAR PRIMARY KEY,
    provider_id VARCHAR REFERENCES service_providers.providers(id),
    name VARCHAR(255) NOT NULL
);

-- Create service_template_items table
CREATE TABLE service_providers.service_template_items (
    id VARCHAR PRIMARY KEY,
    template_id VARCHAR REFERENCES service_providers.service_templates(id),
    service_id VARCHAR REFERENCES service_providers.services(id)
);

-- Create indexes for better performance
CREATE INDEX idx_providers_category_id ON service_providers.providers(category_id);
CREATE INDEX idx_services_category_id ON service_providers.services(category_id);
CREATE INDEX idx_provider_services_provider_id ON service_providers.provider_services(provider_id);
CREATE INDEX idx_provider_services_service_id ON service_providers.provider_services(service_id);
CREATE INDEX idx_service_templates_provider_id ON service_providers.service_templates(provider_id);
CREATE INDEX idx_service_template_items_template_id ON service_providers.service_template_items(template_id);
CREATE INDEX idx_service_template_items_service_id ON service_providers.service_template_items(service_id);
