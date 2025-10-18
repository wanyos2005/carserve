-- Migration: 002_seed_initial_data_fixed.sql
-- Description: Populate tables with initial data (without requirements column)
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

-- Insert Services (without requirements column)
INSERT INTO service_providers.services (category_id, name, description, base_price) VALUES 
-- Oil & Lubrication Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'), 'Engine Oil Change', 'Complete engine oil change service (e.g., QUARTZ 7000, QUARTZ 9000, etc.)', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'), 'Transmission Oil Change', 'Transmission fluid replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'), 'Differential / Axle Oil Change', 'Differential and axle oil replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'), 'Power Steering Fluid Change', 'Power steering fluid replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'), 'Greasing & Lubrication', 'General greasing and lubrication service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Oil & Lubrication'), 'Full Oil Service Package', 'Comprehensive oil service including all fluids', 0.00),

-- Filter Maintenance Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Filter Maintenance'), 'Oil Filter Replacement', 'Engine oil filter replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Filter Maintenance'), 'Air Filter Replacement', 'Engine air filter replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Filter Maintenance'), 'Fuel Filter Replacement', 'Fuel filter replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Filter Maintenance'), 'Cabin / AC Filter Replacement', 'Cabin air filter and AC filter replacement', 0.00),

-- Engine Care Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'), 'Engine Tune-Up', 'Complete engine tune-up service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'), 'Spark Plug Replacement', 'Spark plug replacement and gap adjustment', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'), 'Timing Belt / Chain Replacement', 'Timing belt or chain replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'), 'Engine Mount Replacement', 'Engine mount replacement and alignment', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Engine Care'), 'Engine Overhaul / Rebuild', 'Complete engine overhaul or rebuild service', 0.00),

-- Transmission & Drivetrain Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Transmission & Drivetrain'), 'Gearbox Service', 'Transmission gearbox service and maintenance', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Transmission & Drivetrain'), 'Clutch Replacement', 'Clutch assembly replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Transmission & Drivetrain'), 'Differential Service', 'Differential service and maintenance', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Transmission & Drivetrain'), 'Driveshaft / CV Joint Replacement', 'Driveshaft and CV joint replacement', 0.00),

-- Suspension & Steering Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Suspension & Steering'), 'Shock Absorber Replacement', 'Shock absorber replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Suspension & Steering'), 'Ball Joint & Bushing Service', 'Ball joint and bushing replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Suspension & Steering'), 'Steering Rack Repair', 'Steering rack repair and alignment', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Suspension & Steering'), 'Alignment & Balancing', 'Wheel alignment and balancing service', 0.00),

-- Brakes & Safety Systems Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Brakes & Safety Systems'), 'Brake Pad Replacement', 'Brake pad replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Brakes & Safety Systems'), 'Brake Disc / Drum Service', 'Brake disc or drum service and replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Brakes & Safety Systems'), 'Brake Fluid Change', 'Brake fluid replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Brakes & Safety Systems'), 'ABS System Diagnosis', 'ABS system diagnosis and repair', 0.00),

-- Cooling System Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Cooling System'), 'Radiator Flush & Refill', 'Radiator flush and coolant refill', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Cooling System'), 'Thermostat Replacement', 'Engine thermostat replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Cooling System'), 'Coolant Leak Inspection', 'Cooling system leak inspection and repair', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Cooling System'), 'Water Pump Replacement', 'Water pump replacement service', 0.00),

-- Electrical & Battery Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Electrical & Battery'), 'Battery Testing & Replacement', 'Battery testing and replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Electrical & Battery'), 'Alternator / Starter Motor Service', 'Alternator and starter motor service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Electrical & Battery'), 'Wiring & Lighting Repairs', 'Electrical wiring and lighting repairs', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Electrical & Battery'), 'ECU Diagnostics', 'Engine Control Unit diagnostics and repair', 0.00),

-- Tyres & Wheels Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Tyres & Wheels'), 'Tyre Replacement', 'Tyre replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Tyres & Wheels'), 'Wheel Balancing', 'Wheel balancing service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Tyres & Wheels'), 'Wheel Alignment', 'Wheel alignment service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Tyres & Wheels'), 'Puncture Repair', 'Tyre puncture repair service', 0.00),

-- Fuel System Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Fuel System'), 'Fuel Pump Replacement', 'Fuel pump replacement service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Fuel System'), 'Injector Cleaning', 'Fuel injector cleaning service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Fuel System'), 'Fuel Tank Service', 'Fuel tank service and repair', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Fuel System'), 'Refueling (Standard, Premium, Diesel)', 'Vehicle refueling service', 0.00),

-- Air Conditioning Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Air Conditioning'), 'AC Gas Refill', 'Air conditioning gas refill service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Air Conditioning'), 'Compressor Replacement', 'AC compressor replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Air Conditioning'), 'AC System Leak Test', 'AC system leak testing and repair', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Air Conditioning'), 'Cabin Cooling Diagnosis', 'Cabin cooling system diagnosis', 0.00),

-- Body & Paint Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Body & Paint'), 'Scratch & Dent Repair', 'Scratch and dent repair service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Body & Paint'), 'Full Body Paint', 'Complete vehicle body painting', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Body & Paint'), 'Bumper / Panel Replacement', 'Bumper and panel replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Body & Paint'), 'Polishing & Buffing', 'Vehicle polishing and buffing service', 0.00),

-- Car Wash & Detailing Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Car Wash & Detailing'), 'Exterior Wash', 'Complete exterior car wash', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Car Wash & Detailing'), 'Interior Deep Clean', 'Interior deep cleaning service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Car Wash & Detailing'), 'Engine Bay Cleaning', 'Engine bay cleaning service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Car Wash & Detailing'), 'Ceramic Coating / Waxing', 'Ceramic coating and waxing service', 0.00),

-- Refueling Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Refueling'), 'Petrol Refuel', 'Petrol refueling service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Refueling'), 'Diesel Refuel', 'Diesel refueling service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Refueling'), 'LPG / CNG Refuel', 'LPG/CNG refueling service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Refueling'), 'EV Charging', 'Electric vehicle charging service', 0.00),

-- Inspection & Diagnostics Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Inspection & Diagnostics'), 'General Vehicle Inspection', 'Comprehensive vehicle inspection', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Inspection & Diagnostics'), 'Pre-Purchase Inspection', 'Pre-purchase vehicle inspection', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Inspection & Diagnostics'), 'Emissions Test', 'Vehicle emissions testing', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Inspection & Diagnostics'), 'OBD & ECU Diagnostics', 'OBD and ECU diagnostic service', 0.00),

-- Insurance & Documentation Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Insurance & Documentation'), 'Insurance Renewal', 'Vehicle insurance renewal assistance', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Insurance & Documentation'), 'Accident Claim Assistance', 'Accident claim processing assistance', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Insurance & Documentation'), 'Logbook Transfer', 'Vehicle logbook transfer service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Insurance & Documentation'), 'Vehicle Valuation', 'Professional vehicle valuation', 0.00),

-- Spare Parts & Accessories Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Spare Parts & Accessories'), 'Genuine Parts Replacement', 'Genuine spare parts replacement', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Spare Parts & Accessories'), 'Car Audio & Infotainment Installation', 'Car audio and infotainment system installation', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Spare Parts & Accessories'), 'Lighting Upgrade', 'Vehicle lighting upgrade service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Spare Parts & Accessories'), 'Accessories Fitting', 'Car accessories fitting (Covers, Mats, Spoilers, etc.)', 0.00),

-- Roadside Assistance Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Roadside Assistance'), 'Towing', 'Vehicle towing service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Roadside Assistance'), 'Jump Start', 'Battery jump start service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Roadside Assistance'), 'Emergency Fuel Delivery', 'Emergency fuel delivery service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Roadside Assistance'), 'Flat Tyre Service', 'Flat tyre repair and replacement', 0.00),

-- Vehicle Pickup & Delivery Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Vehicle Pickup & Delivery'), 'Home Pickup for Service', 'Home pickup service for vehicle maintenance', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Vehicle Pickup & Delivery'), 'Home Drop-Off', 'Home drop-off service after maintenance', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Vehicle Pickup & Delivery'), 'Test Drive Pickup', 'Test drive pickup service', 0.00),

-- Hybrid / EV Maintenance Services
((SELECT id FROM service_providers.service_categories WHERE name = 'Hybrid / EV Maintenance'), 'Battery Health Check', 'Hybrid/EV battery health check', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Hybrid / EV Maintenance'), 'EV Charger Installation', 'Electric vehicle charger installation', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Hybrid / EV Maintenance'), 'Hybrid System Service', 'Hybrid system maintenance service', 0.00),
((SELECT id FROM service_providers.service_categories WHERE name = 'Hybrid / EV Maintenance'), 'Inverter & Cooling System Maintenance', 'EV inverter and cooling system maintenance', 0.00)

ON CONFLICT (name) DO NOTHING;
