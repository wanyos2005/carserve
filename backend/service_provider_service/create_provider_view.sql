-- Create a proper database view for better performance
CREATE OR REPLACE VIEW service_providers.provider_service_view AS
SELECT 
    p.id as provider_id,
    p.name as provider_name,
    p.category_id as provider_category_id,
    p.description as provider_description,
    p.contact_info as provider_contact_info,
    p.location as provider_location,
    p.rating as provider_rating,
    p.is_registered as provider_is_registered,
    p.created_at as provider_created_at,
    
    ps.id as provider_service_id,
    ps.display_name,
    ps.price,
    ps.duration,
    ps.booking_required,
    ps.extra_data,
    
    s.id as service_id,
    s.name as service_name,
    s.category_id as service_category_id
    
FROM service_providers.providers p
JOIN service_providers.provider_services ps ON p.id = ps.provider_id
JOIN service_providers.services s ON ps.service_id = s.id;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_provider_service_view_provider_category 
ON service_providers.provider_service_view (provider_category_id);

CREATE INDEX IF NOT EXISTS idx_provider_service_view_service_category 
ON service_providers.provider_service_view (service_category_id);

CREATE INDEX IF NOT EXISTS idx_provider_service_view_provider_name 
ON service_providers.provider_service_view (provider_name);

CREATE INDEX IF NOT EXISTS idx_provider_service_view_service_name 
ON service_providers.provider_service_view (service_name);
