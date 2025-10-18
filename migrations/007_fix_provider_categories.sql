-- Migration: 007_fix_provider_categories.sql
-- Description: Insert missing provider categories
-- Created: 2025-10-18
-- Author: System

-- Insert Provider Categories (these should have been created in 004_seed_service_provider_data_correct.sql)
INSERT INTO service_providers.provider_categories (id, name) VALUES 
(1, 'Unregistered'),
(2, 'Garage / Mechanic'),
(3, 'Fuel Station'),
(4, 'Car Wash & Detailing'),
(5, 'Tyre & Wheel Center'),
(6, 'Battery & Electrical Specialist'),
(7, 'Insurance Agency'),
(8, 'Spare Parts Dealer'),
(9, 'Roadside Assistance / Towing Service'),
(10, 'Inspection & Emission Testing Center'),
(11, 'Auto Body & Paint Shop'),
(12, 'Car Accessories / Customization Shop'),
(13, 'Vehicle Registration & Documentation Agency'),
(14, 'Car Rental / Leasing Company'),
(15, 'Diagnostics & ECU Specialist'),
(16, 'Hybrid / EV Specialist'),
(17, 'Vehicle Pickup & Delivery')
ON CONFLICT (id) DO NOTHING;

-- Reset the sequence to ensure proper ID generation
SELECT setval('service_providers.provider_categories_id_seq', (SELECT MAX(id) FROM service_providers.provider_categories));
