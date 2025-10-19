-- Migration: Add structured pricing fields to provider_services table
-- Description: Adds new pricing columns while keeping legacy price field for backward compatibility
-- Created: 2025-01-18

-- Add new structured pricing columns to provider_services table
ALTER TABLE service_providers.provider_services 
ADD COLUMN IF NOT EXISTS min_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS max_price DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS price_type VARCHAR(20) DEFAULT 'range',
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'KES',
ADD COLUMN IF NOT EXISTS unit VARCHAR(20),
ADD COLUMN IF NOT EXISTS negotiable BOOLEAN DEFAULT true;

-- Add comments for documentation
COMMENT ON COLUMN service_providers.provider_services.min_price IS 'Minimum price for the service (for ranges or fixed prices)';
COMMENT ON COLUMN service_providers.provider_services.max_price IS 'Maximum price for the service (for ranges)';
COMMENT ON COLUMN service_providers.provider_services.price_type IS 'Type of pricing: fixed, range, per_unit, free, variable';
COMMENT ON COLUMN service_providers.provider_services.currency IS 'Currency code (default: KES)';
COMMENT ON COLUMN service_providers.provider_services.unit IS 'Unit for per-unit pricing (per_liter, per_hour, etc.)';
COMMENT ON COLUMN service_providers.provider_services.negotiable IS 'Whether the price is negotiable';

-- Add constraints for data integrity
ALTER TABLE service_providers.provider_services 
ADD CONSTRAINT chk_price_type CHECK (price_type IN ('fixed', 'range', 'per_unit', 'free', 'variable')),
ADD CONSTRAINT chk_currency CHECK (currency IN ('KES', 'USD', 'EUR')),
ADD CONSTRAINT chk_price_range CHECK (
    (price_type = 'fixed' AND min_price IS NOT NULL AND max_price IS NULL) OR
    (price_type = 'range' AND min_price IS NOT NULL AND max_price IS NOT NULL AND min_price <= max_price) OR
    (price_type = 'per_unit' AND min_price IS NOT NULL AND unit IS NOT NULL) OR
    (price_type = 'free' AND min_price IS NULL AND max_price IS NULL) OR
    (price_type = 'variable' AND min_price IS NULL AND max_price IS NULL)
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_provider_services_price_type ON service_providers.provider_services(price_type);
CREATE INDEX IF NOT EXISTS idx_provider_services_negotiable ON service_providers.provider_services(negotiable);

-- Update the provider_service_view to include new fields
-- Note: This view will need to be recreated to include the new columns
DROP VIEW IF EXISTS service_providers.provider_service_view;

CREATE VIEW service_providers.provider_service_view AS
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
    
    -- Provider Service fields
    ps.id as provider_service_id,
    ps.display_name,
    ps.price,  -- Legacy field
    ps.min_price,
    ps.max_price,
    ps.price_type,
    ps.currency,
    ps.unit,
    ps.negotiable,
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
LEFT JOIN service_providers.provider_services ps ON p.id = ps.provider_id
LEFT JOIN service_providers.services s ON ps.service_id = s.id
LEFT JOIN service_providers.provider_categories pc ON p.category_id = pc.id
LEFT JOIN service_providers.service_categories sc ON s.category_id = sc.id;

-- Add comment to the view
COMMENT ON VIEW service_providers.provider_service_view IS 'Enhanced view with structured pricing fields for provider services';

-- Show success message
DO $$
BEGIN
    RAISE NOTICE '🎉 Structured pricing fields added successfully!';
    RAISE NOTICE '📋 New columns added:';
    RAISE NOTICE '  - min_price (DECIMAL)';
    RAISE NOTICE '  - max_price (DECIMAL)';
    RAISE NOTICE '  - price_type (VARCHAR)';
    RAISE NOTICE '  - currency (VARCHAR)';
    RAISE NOTICE '  - unit (VARCHAR)';
    RAISE NOTICE '  - negotiable (BOOLEAN)';
    RAISE NOTICE '📋 Legacy price field preserved for backward compatibility';
    RAISE NOTICE '📋 Provider service view updated with new fields';
    RAISE NOTICE '🚀 Ready for enhanced pricing functionality!';
END $$;
