-- Migration: 006_create_provider_service_view.sql
-- Description: Create comprehensive provider service view matching the SQLAlchemy model
-- Created: 2025-10-18
-- Author: System

-- Drop existing view if it exists
DROP VIEW IF EXISTS service_providers.provider_service_view;

-- Create comprehensive provider service view with all fields from the model
CREATE OR REPLACE VIEW service_providers.provider_service_view AS
SELECT 
    -- Provider fields
    p.id as provider_id,
    p.name as provider_name,
    p.category_id as provider_category_id,
    p.description as provider_description,
    p.contact_info as provider_contact_info,
    p.location as provider_location,
    p.rating as provider_rating,
    p.is_registered as provider_is_registered,
    p.created_at as provider_created_at,
    
    -- Provider service fields
    ps.id as provider_service_id,
    ps.display_name,
    ps.price,
    ps.duration,
    ps.booking_required,
    ps.extra_data,
    
    -- Service fields
    s.id as service_id,
    s.name as service_name,
    s.category_id as service_category_id,
    s.description as service_description,
    s.requirements as service_requirements,
    
    -- Category names for better readability
    pc.name as provider_category_name,
    sc.name as service_category_name
    
FROM service_providers.providers p
JOIN service_providers.provider_services ps ON p.id = ps.provider_id
JOIN service_providers.services s ON ps.service_id = s.id
LEFT JOIN service_providers.provider_categories pc ON p.category_id = pc.id
LEFT JOIN service_providers.service_categories sc ON s.category_id = sc.id;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_provider_service_view_provider_category 
ON service_providers.provider_service_view (provider_category_id);

CREATE INDEX IF NOT EXISTS idx_provider_service_view_service_category 
ON service_providers.provider_service_view (service_category_id);

CREATE INDEX IF NOT EXISTS idx_provider_service_view_provider_name 
ON service_providers.provider_service_view (provider_name);

CREATE INDEX IF NOT EXISTS idx_provider_service_view_service_name 
ON service_providers.provider_service_view (service_name);

CREATE INDEX IF NOT EXISTS idx_provider_service_view_provider_rating 
ON service_providers.provider_service_view (provider_rating);

CREATE INDEX IF NOT EXISTS idx_provider_service_view_provider_registered 
ON service_providers.provider_service_view (provider_is_registered);

-- Add comment to the view
COMMENT ON VIEW service_providers.provider_service_view IS 'Comprehensive view joining providers, services, and categories for efficient querying';
