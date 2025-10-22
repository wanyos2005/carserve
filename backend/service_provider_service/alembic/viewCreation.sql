docker compose exec -T postgres psql -U AdminDb -d car_platform <<'SQL'
DROP VIEW IF EXISTS service_providers.provider_service_view CASCADE;

CREATE VIEW service_providers.provider_service_view AS
SELECT
  p.id                               AS provider_id,
  p.name                             AS provider_name,
  p.category_id                      AS provider_category_id,
  p.description                      AS provider_description,
  p.contact_info                     AS provider_contact_info,
  p.location                         AS provider_location,
  p.rating                           AS provider_rating,
  p.is_registered                    AS provider_is_registered,
  p.created_at                       AS provider_created_at,

  ps.id                              AS provider_service_id,
  ps.display_name                    AS display_name,
  ps.price                           AS price,               -- legacy
  ps.min_price                       AS min_price,
  ps.max_price                       AS max_price,
  ps.price_type                      AS price_type,
  ps.currency                        AS currency,
  ps.unit                            AS unit,
  ps.negotiable                      AS negotiable,
  ps.duration                        AS duration,
  ps.booking_required                AS booking_required,
  ps.extra_data                      AS extra_data,

  s.id                               AS service_id,
  s.name                             AS service_name,
  s.category_id                      AS service_category_id,
  s.description                      AS service_description,
  s.requirements                     AS service_requirements,

  pc.name                            AS provider_category_name,
  sc.name                            AS service_category_name
FROM service_providers.providers p
JOIN service_providers.provider_services ps ON p.id = ps.provider_id
JOIN service_providers.services s          ON ps.service_id = s.id
LEFT JOIN service_providers.provider_categories pc ON p.category_id = pc.id
LEFT JOIN service_providers.service_categories sc  ON s.category_id = sc.id;

-- Additional view: services with categories (flattened)
DROP VIEW IF EXISTS service_providers.services_with_categories CASCADE;

CREATE VIEW service_providers.services_with_categories AS
SELECT
  s.id            AS service_id,
  s.name          AS service_name,
  s.description   AS service_description,
  s.requirements  AS service_requirements,
  s.created_at    AS service_created_at,
  sc.id           AS service_category_id,
  sc.name         AS service_category_name
FROM service_providers.services s
JOIN service_providers.service_categories sc ON s.category_id = sc.id;
SQL