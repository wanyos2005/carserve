#!/usr/bin/env python3
"""
Final seed script for populating provider_categories, service_categories, and services tables.
This script uses the exact connection string from the environment.

Usage:
    python seed_data_final.py
"""

import psycopg2
import os
import uuid
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_connection():
    """Get database connection using the exact DATABASE_URL"""
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        # Normalize SQLAlchemy-style URL to psycopg2-compatible
        if database_url.startswith("postgresql+psycopg2://"):
            database_url = database_url.replace("postgresql+psycopg2://", "postgresql://", 1)
        return psycopg2.connect(database_url)
    else:
        # Fallback to individual components
        return psycopg2.connect(
            host=os.getenv('DB_HOST', 'postgres'),
            port=os.getenv('DB_PORT', '5432'),
            database=os.getenv('DB_NAME', 'car_platform'),
            user=os.getenv('DB_USER', 'AdminDb'),
            password=os.getenv('DB_PASSWORD', 'Ngojakwanza')
        )

def create_provider_categories(conn):
    """Create all provider categories"""
    provider_categories = [
        "Unregistered",
        "Garage / Mechanic",
        "Fuel Station", 
        "Car Wash & Detailing",
        "Tyre & Wheel Center",
        "Battery & Electrical Specialist",
        "Insurance Agency",
        "Spare Parts Dealer",
        "Roadside Assistance / Towing Service",
        "Inspection & Emission Testing Center",
        "Auto Body & Paint Shop",
        "Car Accessories / Customization Shop",
        "Vehicle Registration & Documentation Agency",
        "Car Rental / Leasing Company",
        "Diagnostics & ECU Specialist",
        "Hybrid / EV Specialist",
        "Vehicle Pickup & Delivery"
    ]
    
    cursor = conn.cursor()
    created_count = 0
    
    for category_name in provider_categories:
        try:
            cursor.execute(
                "INSERT INTO service_providers.provider_categories (name) VALUES (%s) ON CONFLICT (name) DO NOTHING",
                (category_name,)
            )
            if cursor.rowcount > 0:
                created_count += 1
                print(f"✅ Created provider category: {category_name}")
            else:
                print(f"⚠️  Provider category already exists: {category_name}")
        except Exception as e:
            print(f"❌ Error creating provider category {category_name}: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_service_categories(conn):
    """Create all service categories"""
    service_categories = [
        "Oil & Lubrication",
        "Filter Maintenance", 
        "Engine Care",
        "Transmission & Drivetrain",
        "Suspension & Steering",
        "Brakes & Safety Systems",
        "Cooling System",
        "Electrical & Battery",
        "Tyres & Wheels",
        "Fuel System",
        "Air Conditioning",
        "Body & Paint",
        "Car Wash & Detailing",
        "Refueling",
        "Inspection & Diagnostics",
        "Insurance & Documentation",
        "Spare Parts & Accessories",
        "Roadside Assistance",
        "Vehicle Pickup & Delivery",
        "Hybrid / EV Maintenance"
    ]
    
    cursor = conn.cursor()
    created_count = 0
    
    for category_name in service_categories:
        try:
            cursor.execute(
                "INSERT INTO service_providers.service_categories (name) VALUES (%s) ON CONFLICT (name) DO NOTHING",
                (category_name,)
            )
            if cursor.rowcount > 0:
                created_count += 1
                print(f"✅ Created service category: {category_name}")
            else:
                print(f"⚠️  Service category already exists: {category_name}")
        except Exception as e:
            print(f"❌ Error creating service category {category_name}: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def create_services(conn):
    """Create all services with their categories"""
    
    # Get category IDs for easy lookup
    cursor = conn.cursor()
    cursor.execute("SELECT id, name FROM service_providers.service_categories")
    category_map = {name: id for id, name in cursor.fetchall()}
    
    services_data = [
        # Oil & Lubrication
        ("Engine Oil Change", "Complete engine oil change service (e.g., QUARTZ 7000, QUARTZ 9000, etc.)", "Oil & Lubrication"),
        ("Transmission Oil Change", "Transmission fluid replacement service", "Oil & Lubrication"),
        ("Differential / Axle Oil Change", "Differential and axle oil replacement", "Oil & Lubrication"),
        ("Power Steering Fluid Change", "Power steering fluid replacement", "Oil & Lubrication"),
        ("Greasing & Lubrication", "General greasing and lubrication service", "Oil & Lubrication"),
        ("Full Oil Service Package", "Comprehensive oil service including all fluids", "Oil & Lubrication"),
        
        # Filter Maintenance
        ("Oil Filter Replacement", "Engine oil filter replacement", "Filter Maintenance"),
        ("Air Filter Replacement", "Engine air filter replacement", "Filter Maintenance"),
        ("Fuel Filter Replacement", "Fuel filter replacement service", "Filter Maintenance"),
        ("Cabin / AC Filter Replacement", "Cabin air filter and AC filter replacement", "Filter Maintenance"),
        
        # Engine Care
        ("Engine Tune-Up", "Complete engine tune-up service", "Engine Care"),
        ("Spark Plug Replacement", "Spark plug replacement and gap adjustment", "Engine Care"),
        ("Timing Belt / Chain Replacement", "Timing belt or chain replacement service", "Engine Care"),
        ("Engine Mount Replacement", "Engine mount replacement and alignment", "Engine Care"),
        ("Engine Overhaul / Rebuild", "Complete engine overhaul or rebuild service", "Engine Care"),
        
        # Transmission & Drivetrain
        ("Gearbox Service", "Transmission gearbox service and maintenance", "Transmission & Drivetrain"),
        ("Clutch Replacement", "Clutch assembly replacement", "Transmission & Drivetrain"),
        ("Differential Service", "Differential service and maintenance", "Transmission & Drivetrain"),
        ("Driveshaft / CV Joint Replacement", "Driveshaft and CV joint replacement", "Transmission & Drivetrain"),
        
        # Suspension & Steering
        ("Shock Absorber Replacement", "Shock absorber replacement service", "Suspension & Steering"),
        ("Ball Joint & Bushing Service", "Ball joint and bushing replacement", "Suspension & Steering"),
        ("Steering Rack Repair", "Steering rack repair and alignment", "Suspension & Steering"),
        ("Alignment & Balancing", "Wheel alignment and balancing service", "Suspension & Steering"),
        
        # Brakes & Safety Systems
        ("Brake Pad Replacement", "Brake pad replacement service", "Brakes & Safety Systems"),
        ("Brake Disc / Drum Service", "Brake disc or drum service and replacement", "Brakes & Safety Systems"),
        ("Brake Fluid Change", "Brake fluid replacement service", "Brakes & Safety Systems"),
        ("ABS System Diagnosis", "ABS system diagnosis and repair", "Brakes & Safety Systems"),
        
        # Cooling System
        ("Radiator Flush & Refill", "Radiator flush and coolant refill", "Cooling System"),
        ("Thermostat Replacement", "Engine thermostat replacement", "Cooling System"),
        ("Coolant Leak Inspection", "Cooling system leak inspection and repair", "Cooling System"),
        ("Water Pump Replacement", "Water pump replacement service", "Cooling System"),
        
        # Electrical & Battery
        ("Battery Testing & Replacement", "Battery testing and replacement service", "Electrical & Battery"),
        ("Alternator / Starter Motor Service", "Alternator and starter motor service", "Electrical & Battery"),
        ("Wiring & Lighting Repairs", "Electrical wiring and lighting repairs", "Electrical & Battery"),
        ("ECU Diagnostics", "Engine Control Unit diagnostics and repair", "Electrical & Battery"),
        
        # Tyres & Wheels
        ("Tyre Replacement", "Tyre replacement service", "Tyres & Wheels"),
        ("Wheel Balancing", "Wheel balancing service", "Tyres & Wheels"),
        ("Wheel Alignment", "Wheel alignment service", "Tyres & Wheels"),
        ("Puncture Repair", "Tyre puncture repair service", "Tyres & Wheels"),
        
        # Fuel System
        ("Fuel Pump Replacement", "Fuel pump replacement service", "Fuel System"),
        ("Injector Cleaning", "Fuel injector cleaning service", "Fuel System"),
        ("Fuel Tank Service", "Fuel tank service and repair", "Fuel System"),
        ("Refueling (Standard, Premium, Diesel)", "Vehicle refueling service", "Fuel System"),
        
        # Air Conditioning
        ("AC Gas Refill", "Air conditioning gas refill service", "Air Conditioning"),
        ("Compressor Replacement", "AC compressor replacement", "Air Conditioning"),
        ("AC System Leak Test", "AC system leak testing and repair", "Air Conditioning"),
        ("Cabin Cooling Diagnosis", "Cabin cooling system diagnosis", "Air Conditioning"),
        
        # Body & Paint
        ("Scratch & Dent Repair", "Scratch and dent repair service", "Body & Paint"),
        ("Full Body Paint", "Complete vehicle body painting", "Body & Paint"),
        ("Bumper / Panel Replacement", "Bumper and panel replacement", "Body & Paint"),
        ("Polishing & Buffing", "Vehicle polishing and buffing service", "Body & Paint"),
        
        # Car Wash & Detailing
        
       
        ("Body Wash", "Standard exterior body wash", "Car Wash & Detailing"),
        ("Engine Wash", "General cleaning of engine surfaces", "Car Wash & Detailing"),
        ("Vacuum Cleaning", "Interior vacuuming of carpets and seats", "Car Wash & Detailing"),
        ("Under Wash", "Cleaning of the vehicle’s underside", "Car Wash & Detailing"),
        ("Interior Polish", "Dashboard and trims polishing for refreshed interior look", "Car Wash & Detailing"),
        ("Exterior Polish", "Polishing of exterior body to restore shine", "Car Wash & Detailing"),
        ("Leather Care", "Cleaning and conditioning of leather surfaces", "Car Wash & Detailing"),
        ("Water Mark Removal", "Removal of stubborn water spots on paint and windows", "Car Wash & Detailing"),
        ("Rim Cleaning", "Detailed rim and tire cleaning", "Car Wash & Detailing"),
        ("Light Restoration", "Restoring clarity of foggy or yellow headlights", "Car Wash & Detailing"),
        ("Air Freshener / Perfume", "Applying car air freshener or perfume", "Car Wash & Detailing"),
        ("Royal Wash", "Premium full-service wash package", "Car Wash & Detailing"),
        ("Executive Wash", "High-end wash and detailing package", "Car Wash & Detailing"),
        ("Detailing Package", "Combined detailing services at a bundled rate", "Car Wash & Detailing"),
        ("Shampoo Wash", "High-foam shampoo wash for body and mats", "Car Wash & Detailing"),
        ("Roof Cleaning", "Detailed cleaning of car roof exterior", "Car Wash & Detailing"),
        ("Floor Cleaning", "Deep cleaning of vehicle floor surfaces", "Car Wash & Detailing"),
        ("Premium Package", "Premium detailing package with multiple services", "Car Wash & Detailing"),
        ("Sanitization", "Interior disinfecting and sanitizing service", "Car Wash & Detailing"),
        ("Superior Package", "Top-tier, full detailing service", "Car Wash & Detailing"),
        ("Foam Wash", "Thick foam wash to loosen dirt safely", "Car Wash & Detailing"),
        ("Steam Engine Cleaning", "Steam-based engine cleaning", "Car Wash & Detailing"),
        ("Steam Interior Wash", "Deep interior steam cleaning for seats, mats, and AC vents", "Car Wash & Detailing"),
        
        # Carpet services grouped and renamed
        ("Carpet Cleaning – Small", "Cleaning of small car carpets or mats", "Car Wash & Detailing"),
        ("Carpet Cleaning – Medium", "Cleaning of medium-sized carpets", "Car Wash & Detailing"),
        ("Carpet Cleaning – Large", "Cleaning of large vehicle carpets", "Car Wash & Detailing"),
        ("Carpet Cleaning – XL", "Cleaning of extra-large vehicle carpets", "Car Wash & Detailing"),
        ("Carpet Cleaning – XXL", "Cleaning of oversized carpets", "Car Wash & Detailing"),
        ("Carpet Cleaning – Premium", "High-grade carpet wash service", "Car Wash & Detailing"),

        ("Waxing", "Waxing", "Car Wash & Detailing"),
        ("Machine polish", "Machine polish", "Car Wash & Detailing"),
        ("Detailing", "Detailing", "Car Wash & Detailing"),
        ("Buffing", "Buffing", "Car Wash & Detailing"),
        ("Leather restoration", "Leather restoration", "Car Wash & Detailing"),      

        ("Plastic restoration", "Plastic restoration", "Car Wash & Detailing"),

        # Refueling
        ("Petrol Refuel", "Petrol refueling service", "Refueling"),
        ("Diesel Refuel", "Diesel refueling service", "Refueling"),
        ("LPG / CNG Refuel", "LPG/CNG refueling service", "Refueling"),
        ("EV Charging", "Electric vehicle charging service", "Refueling"),
        
        # Inspection & Diagnostics
        ("General Vehicle Inspection", "Comprehensive vehicle inspection", "Inspection & Diagnostics"),
        ("Pre-Purchase Inspection", "Pre-purchase vehicle inspection", "Inspection & Diagnostics"),
        ("Emissions Test", "Vehicle emissions testing", "Inspection & Diagnostics"),
        ("OBD & ECU Diagnostics", "OBD and ECU diagnostic service", "Inspection & Diagnostics"),
        
        # Insurance & Documentation
        ("Insurance Renewal", "Vehicle insurance renewal assistance", "Insurance & Documentation"),
        ("Accident Claim Assistance", "Accident claim processing assistance", "Insurance & Documentation"),
        ("Logbook Transfer", "Vehicle logbook transfer service", "Insurance & Documentation"),
        ("Vehicle Valuation", "Professional vehicle valuation", "Insurance & Documentation"),
        
        # Spare Parts & Accessories
        ("Genuine Parts Replacement", "Genuine spare parts replacement", "Spare Parts & Accessories"),
        ("Car Audio & Infotainment Installation", "Car audio and infotainment system installation", "Spare Parts & Accessories"),
        ("Lighting Upgrade", "Vehicle lighting upgrade service", "Spare Parts & Accessories"),
        ("Accessories Fitting", "Car accessories fitting (Covers, Mats, Spoilers, etc.)", "Spare Parts & Accessories"),
        
        # Roadside Assistance
        ("Towing", "Vehicle towing service", "Roadside Assistance"),
        ("Jump Start", "Battery jump start service", "Roadside Assistance"),
        ("Emergency Fuel Delivery", "Emergency fuel delivery service", "Roadside Assistance"),
        ("Flat Tyre Service", "Flat tyre repair and replacement", "Roadside Assistance"),
        
        # Vehicle Pickup & Delivery
        ("Home Pickup for Service", "Home pickup service for vehicle maintenance", "Vehicle Pickup & Delivery"),
        ("Home Drop-Off", "Home drop-off service after maintenance", "Vehicle Pickup & Delivery"),
        ("Test Drive Pickup", "Test drive pickup service", "Vehicle Pickup & Delivery"),
        
        # Hybrid / EV Maintenance
        ("Battery Health Check", "Hybrid/EV battery health check", "Hybrid / EV Maintenance"),
        ("EV Charger Installation", "Electric vehicle charger installation", "Hybrid / EV Maintenance"),
        ("Hybrid System Service", "Hybrid system maintenance service", "Hybrid / EV Maintenance"),
        ("Inverter & Cooling System Maintenance", "EV inverter and cooling system maintenance", "Hybrid / EV Maintenance")
    ]
    
    created_count = 0
    for service_name, description, category_name in services_data:
        try:
            category_id = category_map.get(category_name)
            if not category_id:
                print(f"⚠️  Category not found: {category_name}")
                continue
                
            service_id = str(uuid.uuid4())
            # Default requirements with Price field
            requirements = {
                "fields": [
                    {
                        "name": "price",
                        "label": "Price",
                        "type": "string", #since it will be a range
                        "required": True
                    }
                ]
            }
            
            # Add category-specific requirements
            if category_name == "Oil & Lubrication" and "Oil Change" in service_name:
                requirements["fields"].extend([
                    {
                        "name": "oil_type",
                        "label": "Oil Type",
                        "type": "select",
                        "options": ["Conventional", "Synthetic", "Semi-Synthetic"],
                        "required": True
                    },
                    {
                        "name": "oil_grade",
                        "label": "Oil Grade",
                        "type": "select",
                        "options": ["5W-30", "10W-40", "15W-40", "5W-20"],
                        "required": True
                    }
                ])
            elif category_name == "Tyres & Wheels":
                requirements["fields"].extend([
                    {
                        "name": "tyre_size",
                        "label": "Tyre Size",
                        "type": "text",
                        "required": True
                    },
                    {
                        "name": "tyre_brand",
                        "label": "Tyre Brand",
                        "type": "select",
                        "options": ["Michelin", "Bridgestone", "Continental", "Goodyear", "Pirelli", "Other"],
                        "required": False
                    }
                ])
            elif category_name == "Refueling":
                requirements["fields"].extend([
                    {
                        "name": "fuel_type",
                        "label": "Fuel Type",
                        "type": "select",
                        "options": ["Petrol", "Diesel", "LPG", "CNG", "Electric"],
                        "required": True
                    },
                    {
                        "name": "quantity",
                        "label": "Quantity (Liters/kWh)",
                        "type": "number",
                        "required": True
                    }
                ])
            elif category_name == "Roadside Assistance":
                requirements["fields"].extend([
                    {
                        "name": "location",
                        "label": "Current Location",
                        "type": "text",
                        "required": True
                    },
                    {
                        "name": "vehicle_type",
                        "label": "Vehicle Type",
                        "type": "select",
                        "options": ["Car", "SUV", "Truck", "Motorcycle", "Other"],
                        "required": True
                    }
                ])
            elif category_name == "Vehicle Pickup & Delivery":
                requirements["fields"].extend([
                    {
                        "name": "pickup_address",
                        "label": "Pickup Address",
                        "type": "text",
                        "required": True
                    },
                    {
                        "name": "delivery_address",
                        "label": "Delivery Address",
                        "type": "text",
                        "required": True
                    }
                ])
            cursor.execute(
                "INSERT INTO service_providers.services (id, category_id, name, description, requirements) VALUES (%s, %s, %s, %s, %s) ON CONFLICT (id) DO NOTHING",
                (service_id, category_id, service_name, description, json.dumps(requirements))
            )
            if cursor.rowcount > 0:
                created_count += 1
                print(f"✅ Created service: {service_name}")
            else:
                print(f"⚠️  Service already exists: {service_name}")
        except Exception as e:
            print(f"❌ Error creating service {service_name}: {str(e)}")
    
    conn.commit()
    cursor.close()
    return created_count

def main():
    """Main function to run the seed script"""
    print("🌱 Starting database seeding...")
    print("=" * 50)
    
    try:
        # Get database connection
        conn = get_db_connection()
        
        # Create provider categories
        print("\n📋 Creating Provider Categories...")
        provider_count = create_provider_categories(conn)
        
        # Create service categories
        print("\n📋 Creating Service Categories...")
        service_category_count = create_service_categories(conn)
        
        # Create services
        print("\n🔧 Creating Services...")
        service_count = create_services(conn)
        
        print("\n" + "=" * 50)
        print("🎉 Database seeding completed successfully!")
        print(f"📊 Summary:")
        print(f"   - Provider Categories: {provider_count} created")
        print(f"   - Service Categories: {service_category_count} created")
        print(f"   - Services: {service_count} created")
        
    except Exception as e:
        print(f"❌ Error during seeding: {str(e)}")
        raise
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
