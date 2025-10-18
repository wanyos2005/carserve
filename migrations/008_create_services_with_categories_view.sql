-- Migration: 008_create_services_with_categories_view.sql
-- Description: Create the services_with_categories view that the API expects
-- Created: 2025-10-18
-- Author: System

-- Drop the view if it exists
DROP VIEW IF EXISTS service_providers.services_with_categories CASCADE;

-- Create the services_with_categories view
CREATE VIEW service_providers.services_with_categories AS
SELECT 
    s.id as service_id,
    s.name as service_name,
    s.description as service_description,
    s.requirements as service_requirements,
    s.created_at as service_created_at,
    sc.id as service_category_id,
    sc.name as service_category_name
FROM service_providers.services s
LEFT JOIN service_providers.service_categories sc ON s.category_id = sc.id
ORDER BY sc.name NULLS LAST, s.name;
