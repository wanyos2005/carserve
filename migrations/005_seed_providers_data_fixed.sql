-- Migration: 005_seed_providers_data_fixed.sql
-- Description: Populate service_providers with realistic Nairobi-based providers and their services
-- Created: 2025-10-18
-- Author: System
-- Fixed: Uses gen_random_uuid() for provider_service IDs and relies on subqueries for service lookups

-- Insert realistic Nairobi-based providers with their services
-- This matches the data from seed_providers_final.py

-- AutoCare Kenya - Westlands
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440100', 
 'AutoCare Kenya - Westlands',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Garage / Mechanic'),
 'Full-service automotive repair center specializing in European and Japanese vehicles. 15+ years experience with certified technicians.',
 '{"phone": "+254 700 123 456", "email": "info@autocarekenya.co.ke", "website": "www.autocarekenya.co.ke"}',
 '{"name": "Westlands", "lat": -1.2657, "lng": 36.8065}',
 true, 4.5);

-- Attach services to AutoCare Kenya
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440100', 
 (SELECT id FROM service_providers.services WHERE name = 'Engine Oil Change'),
 'Engine Oil Change', 'KSh 3,500 - 8,000', '30-45 mins', true, 
 '{"oil_types": ["Synthetic", "Semi-Synthetic"], "warranty": "3 months"}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440100', 
 (SELECT id FROM service_providers.services WHERE name = 'Brake Pad Replacement'),
 'Brake Pad Replacement', 'KSh 8,000 - 15,000', '1-2 hours', true, 
 '{"parts_warranty": "6 months"}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440100', 
 (SELECT id FROM service_providers.services WHERE name = 'Engine Tune-Up'),
 'Engine Tune-Up', 'KSh 12,000 - 25,000', '2-3 hours', true, 
 '{"includes_diagnostics": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440100', 
 (SELECT id FROM service_providers.services WHERE name = 'AC Gas Refill'),
 'AC Gas Refill', 'KSh 4,500 - 7,000', '45 mins', false, 
 '{"gas_type": "R134a"}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440100', 
 (SELECT id FROM service_providers.services WHERE name = 'General Vehicle Inspection'),
 'General Vehicle Inspection', 'KSh 2,500 - 4,000', '1 hour', true, 
 '{"report_included": true}');

-- QuickFix Motors - Industrial Area
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440200', 
 'QuickFix Motors - Industrial Area',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Garage / Mechanic'),
 'Fast and reliable car repair services. Open 7 days a week with emergency services available.',
 '{"phone": "+254 722 987 654", "email": "quickfix@motors.co.ke", "whatsapp": "+254 722 987 654"}',
 '{"name": "Industrial Area", "lat": -1.3000, "lng": 36.8167}',
 true, 4.2);

-- Attach services to QuickFix Motors
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440200', 
 (SELECT id FROM service_providers.services WHERE name = 'Engine Oil Change'),
 'Engine Oil Change', 'KSh 2,800 - 6,500', '25 mins', false, 
 '{"express_service": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440200', 
 (SELECT id FROM service_providers.services WHERE name = 'Tyre Replacement'),
 'Tyre Replacement', 'KSh 8,000 - 25,000', '30 mins', false, 
 '{"brands": ["Michelin", "Bridgestone", "Goodyear"]}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440200', 
 (SELECT id FROM service_providers.services WHERE name = 'Battery Testing & Replacement'),
 'Battery Testing & Replacement', 'KSh 15,000 - 35,000', '20 mins', false, 
 '{"battery_warranty": "2 years"}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440200', 
 (SELECT id FROM service_providers.services WHERE name = 'Jump Start'),
 'Jump Start', 'KSh 1,500', '10 mins', false, 
 '{"mobile_service": true}');

-- Premium Auto Services - Karen
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440300', 
 'Premium Auto Services - Karen',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Garage / Mechanic'),
 'Luxury car specialists with state-of-the-art equipment. Authorized service center for premium brands.',
 '{"phone": "+254 20 123 4567", "email": "premium@autoservices.co.ke", "website": "www.premiumautoservices.co.ke"}',
 '{"name": "Karen", "lat": -1.3197, "lng": 36.6788}',
 true, 4.8);

-- Attach services to Premium Auto Services
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440300', 
 (SELECT id FROM service_providers.services WHERE name = 'Engine Oil Change'),
 'Engine Oil Change', 'KSh 8,000 - 18,000', '45 mins', true, 
 '{"premium_oils_only": true, "complementary_wash": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440300', 
 (SELECT id FROM service_providers.services WHERE name = 'Full Body Paint'),
 'Full Body Paint', 'KSh 80,000 - 200,000', '5-7 days', true, 
 '{"color_matching": true, "warranty": "2 years"}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440300', 
 (SELECT id FROM service_providers.services WHERE name = 'Engine Overhaul / Rebuild'),
 'Engine Overhaul / Rebuild', 'KSh 150,000 - 500,000', '1-2 weeks', true, 
 '{"genuine_parts_only": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440300', 
 (SELECT id FROM service_providers.services WHERE name = 'Ceramic Coating / Waxing'),
 'Ceramic Coating / Waxing', 'KSh 25,000 - 50,000', '1 day', true, 
 '{"premium_coating": true}');

-- Shell Westlands
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440400', 
 'Shell Westlands',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Fuel Station'),
 'Full-service fuel station with convenience store, car wash, and basic maintenance services.',
 '{"phone": "+254 700 555 123", "email": "westlands@shell.co.ke"}',
 '{"name": "Westlands", "lat": -1.2657, "lng": 36.8065}',
 true, 4.0);

-- Attach services to Shell Westlands
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440400', 
 (SELECT id FROM service_providers.services WHERE name = 'Petrol Refuel'),
 'Petrol Refuel', 'KSh 180-200/liter', '5-10 mins', false, 
 '{"fuel_types": ["Regular", "Premium", "Super"]}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440400', 
 (SELECT id FROM service_providers.services WHERE name = 'Diesel Refuel'),
 'Diesel Refuel', 'KSh 160-180/liter', '5-10 mins', false, 
 '{"bulk_discounts": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440400', 
 (SELECT id FROM service_providers.services WHERE name = 'Exterior Wash'),
 'Exterior Wash', 'KSh 500 - 1,500', '15-30 mins', false, 
 '{"wash_types": ["Basic", "Premium", "Deluxe"]}');

-- Total Thika Road
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440500', 
 'Total Thika Road',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Fuel Station'),
 '24/7 fuel station with restaurant, ATM, and vehicle services. Located on major highway.',
 '{"phone": "+254 722 333 444", "email": "thikaroad@total.co.ke"}',
 '{"name": "Thika Road", "lat": -1.2000, "lng": 36.8500}',
 true, 4.1);

-- Attach services to Total Thika Road
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440500', 
 (SELECT id FROM service_providers.services WHERE name = 'Petrol Refuel'),
 'Petrol Refuel', 'KSh 175-195/liter', '5-10 mins', false, 
 '{"loyalty_program": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440500', 
 (SELECT id FROM service_providers.services WHERE name = 'Diesel Refuel'),
 'Diesel Refuel', 'KSh 155-175/liter', '5-10 mins', false, 
 '{"truck_friendly": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440500', 
 (SELECT id FROM service_providers.services WHERE name = 'LPG / CNG Refuel'),
 'LPG / CNG Refuel', 'KSh 120-140/liter', '10-15 mins', false, 
 '{"conversion_available": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440500', 
 (SELECT id FROM service_providers.services WHERE name = 'Emergency Fuel Delivery'),
 'Emergency Fuel Delivery', 'KSh 2,000 + fuel cost', '30-60 mins', true, 
 '{"mobile_service": true}');

-- Sparkle Auto Spa - Kilimani
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440600', 
 'Sparkle Auto Spa - Kilimani',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Car Wash & Detailing'),
 'Premium car wash and detailing services with eco-friendly products and professional equipment.',
 '{"phone": "+254 700 777 888", "email": "info@sparkleautospa.co.ke", "instagram": "@sparkleautospa"}',
 '{"name": "Kilimani", "lat": -1.3000, "lng": 36.7833}',
 true, 4.6);

-- Attach services to Sparkle Auto Spa
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440600', 
 (SELECT id FROM service_providers.services WHERE name = 'Exterior Wash'),
 'Exterior Wash', 'KSh 800 - 2,000', '30-45 mins', true, 
 '{"eco_friendly": true, "wax_included": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440600', 
 (SELECT id FROM service_providers.services WHERE name = 'Interior Deep Clean'),
 'Interior Deep Clean', 'KSh 2,500 - 5,000', '1-2 hours', true, 
 '{"leather_conditioning": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440600', 
 (SELECT id FROM service_providers.services WHERE name = 'Engine Bay Cleaning'),
 'Engine Bay Cleaning', 'KSh 1,500 - 3,000', '45 mins', true, 
 '{"degreasing": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440600', 
 (SELECT id FROM service_providers.services WHERE name = 'Ceramic Coating / Waxing'),
 'Ceramic Coating / Waxing', 'KSh 15,000 - 35,000', '4-6 hours', true, 
 '{"warranty": "1 year"}');

-- QuickWash Mobile - CBD
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440700', 
 'QuickWash Mobile - CBD',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Car Wash & Detailing'),
 'Mobile car wash service that comes to your location. Perfect for busy professionals.',
 '{"phone": "+254 722 111 222", "email": "mobile@quickwash.co.ke", "whatsapp": "+254 722 111 222"}',
 '{"name": "CBD", "lat": -1.2921, "lng": 36.8219}',
 true, 4.3);

-- Attach services to QuickWash Mobile
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440700', 
 (SELECT id FROM service_providers.services WHERE name = 'Exterior Wash'),
 'Exterior Wash', 'KSh 1,200 - 2,500', '45-60 mins', true, 
 '{"mobile_service": true, "water_efficient": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440700', 
 (SELECT id FROM service_providers.services WHERE name = 'Interior Deep Clean'),
 'Interior Deep Clean', 'KSh 3,000 - 6,000', '1.5-2 hours', true, 
 '{"mobile_service": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440700', 
 (SELECT id FROM service_providers.services WHERE name = 'Home Pickup for Service'),
 'Home Pickup for Service', 'KSh 500 - 1,000', '15 mins', true, 
 '{"pickup_radius": "20km"}');

-- TyreMax Kenya - Eastleigh
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440800', 
 'TyreMax Kenya - Eastleigh',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Tyre & Wheel Center'),
 'Leading tyre dealer with all major brands. Wheel alignment, balancing, and puncture repair services.',
 '{"phone": "+254 700 444 555", "email": "sales@tyremaxkenya.co.ke", "website": "www.tyremaxkenya.co.ke"}',
 '{"name": "Eastleigh", "lat": -1.2667, "lng": 36.8500}',
 true, 4.4);

-- Attach services to TyreMax Kenya
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440800', 
 (SELECT id FROM service_providers.services WHERE name = 'Tyre Replacement'),
 'Tyre Replacement', 'KSh 6,000 - 30,000', '30-45 mins', false, 
 '{"brands": ["Michelin", "Bridgestone", "Continental", "Goodyear", "Pirelli"]}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440800', 
 (SELECT id FROM service_providers.services WHERE name = 'Wheel Balancing'),
 'Wheel Balancing', 'KSh 1,500 - 3,000', '20-30 mins', false, 
 '{"computer_balancing": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440800', 
 (SELECT id FROM service_providers.services WHERE name = 'Wheel Alignment'),
 'Wheel Alignment', 'KSh 2,500 - 4,500', '30-45 mins', true, 
 '{"laser_alignment": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440800', 
 (SELECT id FROM service_providers.services WHERE name = 'Puncture Repair'),
 'Puncture Repair', 'KSh 500 - 1,500', '15-30 mins', false, 
 '{"patch_repair": true}');

-- PowerBatt Electrical - South B
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655440900', 
 'PowerBatt Electrical - South B',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Battery & Electrical Specialist'),
 'Specialized in automotive batteries, alternators, and electrical systems. Authorized dealer for major battery brands.',
 '{"phone": "+254 722 666 777", "email": "info@powerbatt.co.ke"}',
 '{"name": "South B", "lat": -1.3167, "lng": 36.8333}',
 true, 4.5);

-- Attach services to PowerBatt Electrical
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440900', 
 (SELECT id FROM service_providers.services WHERE name = 'Battery Testing & Replacement'),
 'Battery Testing & Replacement', 'KSh 12,000 - 40,000', '20-30 mins', false, 
 '{"brands": ["Exide", "Varta", "Delphi", "Bosch"], "warranty": "2-3 years"}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440900', 
 (SELECT id FROM service_providers.services WHERE name = 'Alternator / Starter Motor Service'),
 'Alternator / Starter Motor Service', 'KSh 8,000 - 25,000', '1-2 hours', true, 
 '{"rebuild_service": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440900', 
 (SELECT id FROM service_providers.services WHERE name = 'Wiring & Lighting Repairs'),
 'Wiring & Lighting Repairs', 'KSh 3,000 - 15,000', '1-3 hours', true, 
 '{"diagnostic_included": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440900', 
 (SELECT id FROM service_providers.services WHERE name = 'Jump Start'),
 'Jump Start', 'KSh 1,000', '10 mins', false, 
 '{"mobile_service": true}');

-- Kenya Insurance Brokers - CBD
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655441000', 
 'Kenya Insurance Brokers - CBD',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Insurance Agency'),
 'Comprehensive motor insurance services with competitive rates and fast claims processing.',
 '{"phone": "+254 20 123 4567", "email": "motor@kenyainsurance.co.ke", "website": "www.kenyainsurance.co.ke"}',
 '{"name": "CBD", "lat": -1.2921, "lng": 36.8219}',
 true, 4.2);

-- Attach services to Kenya Insurance Brokers
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441000', 
 (SELECT id FROM service_providers.services WHERE name = 'Insurance Renewal'),
 'Insurance Renewal', 'Varies by vehicle', '30-60 mins', true, 
 '{"online_quotes": true, "multiple_insurers": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441000', 
 (SELECT id FROM service_providers.services WHERE name = 'Accident Claim Assistance'),
 'Accident Claim Assistance', 'Free', '1-2 hours', true, 
 '{"24hr_claims": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441000', 
 (SELECT id FROM service_providers.services WHERE name = 'Vehicle Valuation'),
 'Vehicle Valuation', 'KSh 2,000 - 5,000', '1 hour', true, 
 '{"certified_valuers": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441000', 
 (SELECT id FROM service_providers.services WHERE name = 'Logbook Transfer'),
 'Logbook Transfer', 'KSh 3,000 - 8,000', '2-5 days', true, 
 '{"documentation_assistance": true}');

-- Rescue 24/7 - Nairobi
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655441100', 
 'Rescue 24/7 - Nairobi',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Roadside Assistance / Towing Service'),
 '24/7 roadside assistance and towing services across Nairobi and surrounding areas.',
 '{"phone": "+254 700 999 000", "email": "rescue@24seven.co.ke", "emergency": "+254 700 999 000"}',
 '{"name": "Nairobi", "lat": -1.2921, "lng": 36.8219}',
 true, 4.7);

-- Attach services to Rescue 24/7
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441100', 
 (SELECT id FROM service_providers.services WHERE name = 'Towing'),
 'Towing', 'KSh 3,000 - 8,000', '30-60 mins', true, 
 '{"24hr_service": true, "flatbed_available": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441100', 
 (SELECT id FROM service_providers.services WHERE name = 'Jump Start'),
 'Jump Start', 'KSh 2,000', '15-30 mins', true, 
 '{"mobile_service": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441100', 
 (SELECT id FROM service_providers.services WHERE name = 'Emergency Fuel Delivery'),
 'Emergency Fuel Delivery', 'KSh 2,500 + fuel cost', '30-45 mins', true, 
 '{"emergency_service": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441100', 
 (SELECT id FROM service_providers.services WHERE name = 'Flat Tyre Service'),
 'Flat Tyre Service', 'KSh 1,500 - 3,000', '20-40 mins', true, 
 '{"spare_tyre_available": true}');

-- NTSA Approved Inspection Center - Kasarani
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655441200', 
 'NTSA Approved Inspection Center - Kasarani',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Inspection & Emission Testing Center'),
 'NTSA approved vehicle inspection center with modern equipment for comprehensive vehicle testing.',
 '{"phone": "+254 700 888 999", "email": "inspection@ntsaapproved.co.ke"}',
 '{"name": "Kasarani", "lat": -1.2167, "lng": 36.9000}',
 true, 4.3);

-- Attach services to NTSA Approved Inspection Center
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441200', 
 (SELECT id FROM service_providers.services WHERE name = 'General Vehicle Inspection'),
 'General Vehicle Inspection', 'KSh 3,000 - 5,000', '1-2 hours', true, 
 '{"ntsa_approved": true, "certificate_included": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441200', 
 (SELECT id FROM service_providers.services WHERE name = 'Pre-Purchase Inspection'),
 'Pre-Purchase Inspection', 'KSh 4,000 - 7,000', '2-3 hours', true, 
 '{"detailed_report": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441200', 
 (SELECT id FROM service_providers.services WHERE name = 'Emissions Test'),
 'Emissions Test', 'KSh 2,000 - 3,500', '30-45 mins', true, 
 '{"environmental_compliance": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441200', 
 (SELECT id FROM service_providers.services WHERE name = 'OBD & ECU Diagnostics'),
 'OBD & ECU Diagnostics', 'KSh 2,500 - 4,500', '45-60 mins', true, 
 '{"modern_diagnostics": true}');

-- EV Solutions Kenya - Lavington
INSERT INTO service_providers.providers (id, name, category_id, description, contact_info, location, is_registered, rating) VALUES 
('550e8400-e29b-41d4-a716-446655441300', 
 'EV Solutions Kenya - Lavington',
 (SELECT id FROM service_providers.provider_categories WHERE name = 'Hybrid / EV Specialist'),
 'Specialized in hybrid and electric vehicle maintenance, charging solutions, and battery management.',
 '{"phone": "+254 700 111 333", "email": "info@evsolutionskenya.co.ke", "website": "www.evsolutionskenya.co.ke"}',
 '{"name": "Lavington", "lat": -1.2833, "lng": 36.7667}',
 true, 4.6);

-- Attach services to EV Solutions Kenya
INSERT INTO service_providers.provider_services (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data) VALUES 
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441300', 
 (SELECT id FROM service_providers.services WHERE name = 'Battery Health Check'),
 'Battery Health Check', 'KSh 5,000 - 10,000', '1-2 hours', true, 
 '{"specialized_equipment": true, "battery_report": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441300', 
 (SELECT id FROM service_providers.services WHERE name = 'EV Charger Installation'),
 'EV Charger Installation', 'KSh 80,000 - 200,000', '1-2 days', true, 
 '{"home_installation": true, "warranty": "2 years"}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441300', 
 (SELECT id FROM service_providers.services WHERE name = 'Hybrid System Service'),
 'Hybrid System Service', 'KSh 15,000 - 35,000', '2-4 hours', true, 
 '{"certified_technicians": true}'),

(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655441300', 
 (SELECT id FROM service_providers.services WHERE name = 'EV Charging'),
 'EV Charging', 'KSh 50-100/kWh', '30 mins - 2 hours', false, 
 '{"fast_charging": true, "multiple_connectors": true}');
