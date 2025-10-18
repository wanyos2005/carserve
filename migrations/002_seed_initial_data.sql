-- Migration: 002_seed_initial_data.sql
-- Description: Populate tables with initial data from seed_data_final.py
-- Created: 2025-10-18
-- Author: System

-- Insert Provider Categories
INSERT INTO service_providers.provider_categories (name) VALUES 
('Unregistered'),
('Garage / Mechanic'),
('Fuel Station'), 
('Car Wash & Detailing'),
('Tyre & Wheel Center'),
('Battery & Electrical Specialist'),
('Insurance Agency'),
('Spare Parts Dealer'),
('Roadside Assistance / Towing Service'),
('Inspection & Emission Testing Center'),
('Auto Body & Paint Shop'),
('Car Accessories / Customization Shop'),
('Vehicle Registration & Documentation Agency'),
('Car Rental / Leasing Company'),
('Diagnostics & ECU Specialist'),
('Hybrid / EV Specialist'),
('Vehicle Pickup & Delivery')
ON CONFLICT (name) DO NOTHING;

-- Insert Service Categories
INSERT INTO service_providers.service_categories (name) VALUES 
('Oil & Lubrication'),
('Filter Maintenance'), 
('Engine Care'),
('Transmission & Drivetrain'),
('Suspension & Steering'),
('Brakes & Safety Systems'),
('Cooling System'),
('Electrical & Battery'),
('Tyres & Wheels'),
('Fuel System'),
('Air Conditioning'),
('Body & Paint'),
('Car Wash & Detailing'),
('Refueling'),
('Inspection & Diagnostics'),
('Insurance & Documentation'),
('Spare Parts & Accessories'),
('Roadside Assistance'),
('Vehicle Pickup & Delivery'),
('Hybrid / EV Maintenance')
ON CONFLICT (name) DO NOTHING;

-- Insert Services with their categories and requirements
-- Oil & Lubrication Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Engine Oil Change
('550e8400-e29b-41d4-a716-446655440001', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'),
 'Engine Oil Change', 
 'Complete engine oil change service (e.g., QUARTZ 7000, QUARTZ 9000, etc.)',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "oil_type", "label": "Oil Type", "type": "select", "options": ["Conventional", "Synthetic", "Semi-Synthetic"], "required": true}, {"name": "oil_grade", "label": "Oil Grade", "type": "select", "options": ["5W-30", "10W-40", "15W-40", "5W-20"], "required": true}]}'),

-- Transmission Oil Change
('550e8400-e29b-41d4-a716-446655440002', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'),
 'Transmission Oil Change', 
 'Transmission fluid replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Differential / Axle Oil Change
('550e8400-e29b-41d4-a716-446655440003', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'),
 'Differential / Axle Oil Change', 
 'Differential and axle oil replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Power Steering Fluid Change
('550e8400-e29b-41d4-a716-446655440004', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'),
 'Power Steering Fluid Change', 
 'Power steering fluid replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Greasing & Lubrication
('550e8400-e29b-41d4-a716-446655440005', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'),
 'Greasing & Lubrication', 
 'General greasing and lubrication service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Full Oil Service Package
('550e8400-e29b-41d4-a716-446655440006', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'),
 'Full Oil Service Package', 
 'Comprehensive oil service including all fluids',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Filter Maintenance Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Oil Filter Replacement
('550e8400-e29b-41d4-a716-446655440007', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Filter Maintenance'),
 'Oil Filter Replacement', 
 'Engine oil filter replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Air Filter Replacement
('550e8400-e29b-41d4-a716-446655440008', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Filter Maintenance'),
 'Air Filter Replacement', 
 'Engine air filter replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Fuel Filter Replacement
('550e8400-e29b-41d4-a716-446655440009', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Filter Maintenance'),
 'Fuel Filter Replacement', 
 'Fuel filter replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Cabin / AC Filter Replacement
('550e8400-e29b-41d4-a716-446655440010', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Filter Maintenance'),
 'Cabin / AC Filter Replacement', 
 'Cabin air filter and AC filter replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Engine Care Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Engine Tune-Up
('550e8400-e29b-41d4-a716-446655440011', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'),
 'Engine Tune-Up', 
 'Complete engine tune-up service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Spark Plug Replacement
('550e8400-e29b-41d4-a716-446655440012', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'),
 'Spark Plug Replacement', 
 'Spark plug replacement and gap adjustment',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Timing Belt / Chain Replacement
('550e8400-e29b-41d4-a716-446655440013', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'),
 'Timing Belt / Chain Replacement', 
 'Timing belt or chain replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Engine Mount Replacement
('550e8400-e29b-41d4-a716-446655440014', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'),
 'Engine Mount Replacement', 
 'Engine mount replacement and alignment',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Engine Overhaul / Rebuild
('550e8400-e29b-41d4-a716-446655440015', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'),
 'Engine Overhaul / Rebuild', 
 'Complete engine overhaul or rebuild service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Transmission & Drivetrain Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Gearbox Service
('550e8400-e29b-41d4-a716-446655440016', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Transmission & Drivetrain'),
 'Gearbox Service', 
 'Transmission gearbox service and maintenance',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Clutch Replacement
('550e8400-e29b-41d4-a716-446655440017', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Transmission & Drivetrain'),
 'Clutch Replacement', 
 'Clutch assembly replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Differential Service
('550e8400-e29b-41d4-a716-446655440018', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Transmission & Drivetrain'),
 'Differential Service', 
 'Differential service and maintenance',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Driveshaft / CV Joint Replacement
('550e8400-e29b-41d4-a716-446655440019', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Transmission & Drivetrain'),
 'Driveshaft / CV Joint Replacement', 
 'Driveshaft and CV joint replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Suspension & Steering Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Shock Absorber Replacement
('550e8400-e29b-41d4-a716-446655440020', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Suspension & Steering'),
 'Shock Absorber Replacement', 
 'Shock absorber replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Ball Joint & Bushing Service
('550e8400-e29b-41d4-a716-446655440021', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Suspension & Steering'),
 'Ball Joint & Bushing Service', 
 'Ball joint and bushing replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Steering Rack Repair
('550e8400-e29b-41d4-a716-446655440022', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Suspension & Steering'),
 'Steering Rack Repair', 
 'Steering rack repair and alignment',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Alignment & Balancing
('550e8400-e29b-41d4-a716-446655440023', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Suspension & Steering'),
 'Alignment & Balancing', 
 'Wheel alignment and balancing service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Brakes & Safety Systems Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Brake Pad Replacement
('550e8400-e29b-41d4-a716-446655440024', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Brakes & Safety Systems'),
 'Brake Pad Replacement', 
 'Brake pad replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Brake Disc / Drum Service
('550e8400-e29b-41d4-a716-446655440025', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Brakes & Safety Systems'),
 'Brake Disc / Drum Service', 
 'Brake disc or drum service and replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Brake Fluid Change
('550e8400-e29b-41d4-a716-446655440026', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Brakes & Safety Systems'),
 'Brake Fluid Change', 
 'Brake fluid replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- ABS System Diagnosis
('550e8400-e29b-41d4-a716-446655440027', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Brakes & Safety Systems'),
 'ABS System Diagnosis', 
 'ABS system diagnosis and repair',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Cooling System Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Radiator Flush & Refill
('550e8400-e29b-41d4-a716-446655440028', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Cooling System'),
 'Radiator Flush & Refill', 
 'Radiator flush and coolant refill',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Thermostat Replacement
('550e8400-e29b-41d4-a716-446655440029', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Cooling System'),
 'Thermostat Replacement', 
 'Engine thermostat replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Coolant Leak Inspection
('550e8400-e29b-41d4-a716-446655440030', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Cooling System'),
 'Coolant Leak Inspection', 
 'Cooling system leak inspection and repair',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Water Pump Replacement
('550e8400-e29b-41d4-a716-446655440031', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Cooling System'),
 'Water Pump Replacement', 
 'Water pump replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Electrical & Battery Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Battery Testing & Replacement
('550e8400-e29b-41d4-a716-446655440032', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Electrical & Battery'),
 'Battery Testing & Replacement', 
 'Battery testing and replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Alternator / Starter Motor Service
('550e8400-e29b-41d4-a716-446655440033', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Electrical & Battery'),
 'Alternator / Starter Motor Service', 
 'Alternator and starter motor service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Wiring & Lighting Repairs
('550e8400-e29b-41d4-a716-446655440034', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Electrical & Battery'),
 'Wiring & Lighting Repairs', 
 'Electrical wiring and lighting repairs',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- ECU Diagnostics
('550e8400-e29b-41d4-a716-446655440035', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Electrical & Battery'),
 'ECU Diagnostics', 
 'Engine Control Unit diagnostics and repair',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Tyres & Wheels Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Tyre Replacement
('550e8400-e29b-41d4-a716-446655440036', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Tyres & Wheels'),
 'Tyre Replacement', 
 'Tyre replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "tyre_size", "label": "Tyre Size", "type": "text", "required": true}, {"name": "tyre_brand", "label": "Tyre Brand", "type": "select", "options": ["Michelin", "Bridgestone", "Continental", "Goodyear", "Pirelli", "Other"], "required": false}]}'),

-- Wheel Balancing
('550e8400-e29b-41d4-a716-446655440037', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Tyres & Wheels'),
 'Wheel Balancing', 
 'Wheel balancing service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Wheel Alignment
('550e8400-e29b-41d4-a716-446655440038', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Tyres & Wheels'),
 'Wheel Alignment', 
 'Wheel alignment service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Puncture Repair
('550e8400-e29b-41d4-a716-446655440039', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Tyres & Wheels'),
 'Puncture Repair', 
 'Tyre puncture repair service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Fuel System Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Fuel Pump Replacement
('550e8400-e29b-41d4-a716-446655440040', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Fuel System'),
 'Fuel Pump Replacement', 
 'Fuel pump replacement service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Injector Cleaning
('550e8400-e29b-41d4-a716-446655440041', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Fuel System'),
 'Injector Cleaning', 
 'Fuel injector cleaning service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Fuel Tank Service
('550e8400-e29b-41d4-a716-446655440042', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Fuel System'),
 'Fuel Tank Service', 
 'Fuel tank service and repair',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Refueling (Standard, Premium, Diesel)
('550e8400-e29b-41d4-a716-446655440043', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Fuel System'),
 'Refueling (Standard, Premium, Diesel)', 
 'Vehicle refueling service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Air Conditioning Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- AC Gas Refill
('550e8400-e29b-41d4-a716-446655440044', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Air Conditioning'),
 'AC Gas Refill', 
 'Air conditioning gas refill service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Compressor Replacement
('550e8400-e29b-41d4-a716-446655440045', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Air Conditioning'),
 'Compressor Replacement', 
 'AC compressor replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- AC System Leak Test
('550e8400-e29b-41d4-a716-446655440046', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Air Conditioning'),
 'AC System Leak Test', 
 'AC system leak testing and repair',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Cabin Cooling Diagnosis
('550e8400-e29b-41d4-a716-446655440047', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Air Conditioning'),
 'Cabin Cooling Diagnosis', 
 'Cabin cooling system diagnosis',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Body & Paint Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Scratch & Dent Repair
('550e8400-e29b-41d4-a716-446655440048', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Body & Paint'),
 'Scratch & Dent Repair', 
 'Scratch and dent repair service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Full Body Paint
('550e8400-e29b-41d4-a716-446655440049', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Body & Paint'),
 'Full Body Paint', 
 'Complete vehicle body painting',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Bumper / Panel Replacement
('550e8400-e29b-41d4-a716-446655440050', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Body & Paint'),
 'Bumper / Panel Replacement', 
 'Bumper and panel replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Polishing & Buffing
('550e8400-e29b-41d4-a716-446655440051', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Body & Paint'),
 'Polishing & Buffing', 
 'Vehicle polishing and buffing service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Car Wash & Detailing Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Exterior Wash
('550e8400-e29b-41d4-a716-446655440052', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Car Wash & Detailing'),
 'Exterior Wash', 
 'Complete exterior car wash',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Interior Deep Clean
('550e8400-e29b-41d4-a716-446655440053', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Car Wash & Detailing'),
 'Interior Deep Clean', 
 'Interior deep cleaning service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Engine Bay Cleaning
('550e8400-e29b-41d4-a716-446655440054', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Car Wash & Detailing'),
 'Engine Bay Cleaning', 
 'Engine bay cleaning service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Ceramic Coating / Waxing
('550e8400-e29b-41d4-a716-446655440055', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Car Wash & Detailing'),
 'Ceramic Coating / Waxing', 
 'Ceramic coating and waxing service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Refueling Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Petrol Refuel
('550e8400-e29b-41d4-a716-446655440056', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Refueling'),
 'Petrol Refuel', 
 'Petrol refueling service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "fuel_type", "label": "Fuel Type", "type": "select", "options": ["Petrol", "Diesel", "LPG", "CNG", "Electric"], "required": true}, {"name": "quantity", "label": "Quantity (Liters/kWh)", "type": "number", "required": true}]}'),

-- Diesel Refuel
('550e8400-e29b-41d4-a716-446655440057', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Refueling'),
 'Diesel Refuel', 
 'Diesel refueling service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "fuel_type", "label": "Fuel Type", "type": "select", "options": ["Petrol", "Diesel", "LPG", "CNG", "Electric"], "required": true}, {"name": "quantity", "label": "Quantity (Liters/kWh)", "type": "number", "required": true}]}'),

-- LPG / CNG Refuel
('550e8400-e29b-41d4-a716-446655440058', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Refueling'),
 'LPG / CNG Refuel', 
 'LPG/CNG refueling service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "fuel_type", "label": "Fuel Type", "type": "select", "options": ["Petrol", "Diesel", "LPG", "CNG", "Electric"], "required": true}, {"name": "quantity", "label": "Quantity (Liters/kWh)", "type": "number", "required": true}]}'),

-- EV Charging
('550e8400-e29b-41d4-a716-446655440059', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Refueling'),
 'EV Charging', 
 'Electric vehicle charging service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "fuel_type", "label": "Fuel Type", "type": "select", "options": ["Petrol", "Diesel", "LPG", "CNG", "Electric"], "required": true}, {"name": "quantity", "label": "Quantity (Liters/kWh)", "type": "number", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Inspection & Diagnostics Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- General Vehicle Inspection
('550e8400-e29b-41d4-a716-446655440060', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Inspection & Diagnostics'),
 'General Vehicle Inspection', 
 'Comprehensive vehicle inspection',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Pre-Purchase Inspection
('550e8400-e29b-41d4-a716-446655440061', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Inspection & Diagnostics'),
 'Pre-Purchase Inspection', 
 'Pre-purchase vehicle inspection',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Emissions Test
('550e8400-e29b-41d4-a716-446655440062', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Inspection & Diagnostics'),
 'Emissions Test', 
 'Vehicle emissions testing',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- OBD & ECU Diagnostics
('550e8400-e29b-41d4-a716-446655440063', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Inspection & Diagnostics'),
 'OBD & ECU Diagnostics', 
 'OBD and ECU diagnostic service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Insurance & Documentation Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Insurance Renewal
('550e8400-e29b-41d4-a716-446655440064', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Insurance & Documentation'),
 'Insurance Renewal', 
 'Vehicle insurance renewal assistance',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Accident Claim Assistance
('550e8400-e29b-41d4-a716-446655440065', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Insurance & Documentation'),
 'Accident Claim Assistance', 
 'Accident claim processing assistance',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Logbook Transfer
('550e8400-e29b-41d4-a716-446655440066', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Insurance & Documentation'),
 'Logbook Transfer', 
 'Vehicle logbook transfer service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Vehicle Valuation
('550e8400-e29b-41d4-a716-446655440067', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Insurance & Documentation'),
 'Vehicle Valuation', 
 'Professional vehicle valuation',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Spare Parts & Accessories Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Genuine Parts Replacement
('550e8400-e29b-41d4-a716-446655440068', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Spare Parts & Accessories'),
 'Genuine Parts Replacement', 
 'Genuine spare parts replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Car Audio & Infotainment Installation
('550e8400-e29b-41d4-a716-446655440069', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Spare Parts & Accessories'),
 'Car Audio & Infotainment Installation', 
 'Car audio and infotainment system installation',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Lighting Upgrade
('550e8400-e29b-41d4-a716-446655440070', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Spare Parts & Accessories'),
 'Lighting Upgrade', 
 'Vehicle lighting upgrade service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Accessories Fitting
('550e8400-e29b-41d4-a716-446655440071', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Spare Parts & Accessories'),
 'Accessories Fitting', 
 'Car accessories fitting (Covers, Mats, Spoilers, etc.)',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Roadside Assistance Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Towing
('550e8400-e29b-41d4-a716-446655440072', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Roadside Assistance'),
 'Towing', 
 'Vehicle towing service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "location", "label": "Current Location", "type": "text", "required": true}, {"name": "vehicle_type", "label": "Vehicle Type", "type": "select", "options": ["Car", "SUV", "Truck", "Motorcycle", "Other"], "required": true}]}'),

-- Jump Start
('550e8400-e29b-41d4-a716-446655440073', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Roadside Assistance'),
 'Jump Start', 
 'Battery jump start service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "location", "label": "Current Location", "type": "text", "required": true}, {"name": "vehicle_type", "label": "Vehicle Type", "type": "select", "options": ["Car", "SUV", "Truck", "Motorcycle", "Other"], "required": true}]}'),

-- Emergency Fuel Delivery
('550e8400-e29b-41d4-a716-446655440074', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Roadside Assistance'),
 'Emergency Fuel Delivery', 
 'Emergency fuel delivery service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "location", "label": "Current Location", "type": "text", "required": true}, {"name": "vehicle_type", "label": "Vehicle Type", "type": "select", "options": ["Car", "SUV", "Truck", "Motorcycle", "Other"], "required": true}]}'),

-- Flat Tyre Service
('550e8400-e29b-41d4-a716-446655440075', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Roadside Assistance'),
 'Flat Tyre Service', 
 'Flat tyre repair and replacement',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "location", "label": "Current Location", "type": "text", "required": true}, {"name": "vehicle_type", "label": "Vehicle Type", "type": "select", "options": ["Car", "SUV", "Truck", "Motorcycle", "Other"], "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Vehicle Pickup & Delivery Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Home Pickup for Service
('550e8400-e29b-41d4-a716-446655440076', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Vehicle Pickup & Delivery'),
 'Home Pickup for Service', 
 'Home pickup service for vehicle maintenance',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "pickup_address", "label": "Pickup Address", "type": "text", "required": true}, {"name": "delivery_address", "label": "Delivery Address", "type": "text", "required": true}]}'),

-- Home Drop-Off
('550e8400-e29b-41d4-a716-446655440077', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Vehicle Pickup & Delivery'),
 'Home Drop-Off', 
 'Home drop-off service after maintenance',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "pickup_address", "label": "Pickup Address", "type": "text", "required": true}, {"name": "delivery_address", "label": "Delivery Address", "type": "text", "required": true}]}'),

-- Test Drive Pickup
('550e8400-e29b-41d4-a716-446655440078', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Vehicle Pickup & Delivery'),
 'Test Drive Pickup', 
 'Test drive pickup service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}, {"name": "pickup_address", "label": "Pickup Address", "type": "text", "required": true}, {"name": "delivery_address", "label": "Delivery Address", "type": "text", "required": true}]}')

ON CONFLICT (id) DO NOTHING;

-- Hybrid / EV Maintenance Services
INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES 
-- Battery Health Check
('550e8400-e29b-41d4-a716-446655440079', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Hybrid / EV Maintenance'),
 'Battery Health Check', 
 'Hybrid/EV battery health check',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- EV Charger Installation
('550e8400-e29b-41d4-a716-446655440080', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Hybrid / EV Maintenance'),
 'EV Charger Installation', 
 'Electric vehicle charger installation',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Hybrid System Service
('550e8400-e29b-41d4-a716-446655440081', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Hybrid / EV Maintenance'),
 'Hybrid System Service', 
 'Hybrid system maintenance service',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}'),

-- Inverter & Cooling System Maintenance
('550e8400-e29b-41d4-a716-446655440082', 
 (SELECT id FROM service_providers.service_categories WHERE name = 'Hybrid / EV Maintenance'),
 'Inverter & Cooling System Maintenance', 
 'EV inverter and cooling system maintenance',
 '{"fields": [{"name": "price", "label": "Price", "type": "string", "required": true}]}')

ON CONFLICT (id) DO NOTHING;
