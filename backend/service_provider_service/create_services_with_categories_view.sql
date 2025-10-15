-- Create a view that joins services to their categories for simpler querying
CREATE OR REPLACE VIEW service_providers.services_with_categories AS
SELECT 
    s.id            AS service_id,
    s.name          AS service_name,
    s.description   AS service_description,
    s.requirements  AS service_requirements,
    s.created_at    AS service_created_at,
    s.category_id   AS service_category_id,
    sc.name         AS service_category_name
FROM service_providers.services s
LEFT JOIN service_providers.service_categories sc
  ON s.category_id = sc.id;

-- Helpful indexes for common filters
CREATE INDEX IF NOT EXISTS idx_services_with_categories_category_id
ON service_providers.services_with_categories (service_category_id);

CREATE INDEX IF NOT EXISTS idx_services_with_categories_service_name
ON service_providers.services_with_categories (service_name);


