#!/usr/bin/env python3
"""
Comprehensive provider seeding script for Nairobi-based service providers.
This script creates realistic providers with their services and pricing.

Usage:
    python seed_providers_final.py
"""

import psycopg2
import os
import uuid
import json
import random
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
        return psycopg2.connect(
            host=os.getenv('DB_HOST', 'postgres'),
            port=os.getenv('DB_PORT', '5432'),
            database=os.getenv('DB_NAME', 'car_platform'),
            user=os.getenv('DB_USER', 'AdminDb'),
            password=os.getenv('DB_PASSWORD', 'Ngojakwanza')
        )

def get_category_mappings(conn):
    """Get category ID mappings for providers and services"""
    cursor = conn.cursor()
    
    # Get provider categories
    cursor.execute("SELECT id, name FROM service_providers.provider_categories")
    provider_categories = {name: id for id, name in cursor.fetchall()}
    
    # Get service categories
    cursor.execute("SELECT id, name FROM service_providers.service_categories")
    service_categories = {name: id for id, name in cursor.fetchall()}
    
    cursor.close()
    return provider_categories, service_categories

def get_services_by_category(conn):
    """Get all services grouped by category"""
    cursor = conn.cursor()
    cursor.execute("""
        SELECT s.id, s.name, s.description, s.requirements, sc.name as category_name
        FROM service_providers.services s
        JOIN service_providers.service_categories sc ON s.category_id = sc.id
        ORDER BY sc.name, s.name
    """)
    
    services_by_category = {}
    for row in cursor.fetchall():
        service_id, name, description, requirements, category_name = row
        if category_name not in services_by_category:
            services_by_category[category_name] = []
        services_by_category[category_name].append({
            'id': service_id,
            'name': name,
            'description': description,
            'requirements': requirements
        })
    
    cursor.close()
    return services_by_category

def create_provider(conn, provider_data, provider_categories):
    """Create a single provider"""
    cursor = conn.cursor()
    
    try:
        provider_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO service_providers.providers 
            (id, name, category_id, description, contact_info, location, is_registered, rating)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            provider_id,
            provider_data['name'],
            provider_categories[provider_data['category']],
            provider_data['description'],
            json.dumps(provider_data['contact_info']),
            json.dumps(provider_data['location']),
            provider_data['is_registered'],
            provider_data['rating']
        ))
        
        provider_id = cursor.fetchone()[0]
        conn.commit()
        print(f"Created provider: {provider_data['name']}")
        return provider_id
        
    except Exception as e:
        print(f"Error creating provider {provider_data['name']}: {str(e)}")
        conn.rollback()
        return None
    finally:
        cursor.close()

def attach_services_to_provider(conn, provider_id, services_data):
    """Attach services to a provider"""
    cursor = conn.cursor()
    attached_count = 0
    
    try:
        for service_data in services_data:
            provider_service_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO service_providers.provider_services 
                (id, provider_id, service_id, display_name, price, duration, booking_required, extra_data)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                provider_service_id,
                provider_id,
                service_data['service_id'],
                service_data.get('display_name'),
                service_data['price'],
                service_data.get('duration'),
                service_data.get('booking_required', False),
                json.dumps(service_data.get('extra_data', {}))
            ))
            attached_count += 1
            
        conn.commit()
        print(f"   Attached {attached_count} services")
        
    except Exception as e:
        print(f"Error attaching services: {str(e)}")
        conn.rollback()
    finally:
        cursor.close()

def get_nairobi_providers_data():
    """Define comprehensive Nairobi-based providers with their services"""
    
    # Nairobi areas and coordinates
    nairobi_areas = [
        {"name": "Westlands", "lat": -1.2657, "lng": 36.8065},
        {"name": "Karen", "lat": -1.3197, "lng": 36.6788},
        {"name": "Runda", "lat": -1.2000, "lng": 36.8000},
        {"name": "Kilimani", "lat": -1.3000, "lng": 36.7833},
        {"name": "Lavington", "lat": -1.2833, "lng": 36.7667},
        {"name": "Eastleigh", "lat": -1.2667, "lng": 36.8500},
        {"name": "South B", "lat": -1.3167, "lng": 36.8333},
        {"name": "Industrial Area", "lat": -1.3000, "lng": 36.8167},
        {"name": "CBD", "lat": -1.2921, "lng": 36.8219},
        {"name": "Kasarani", "lat": -1.2167, "lng": 36.9000},
        {"name": "Thika Road", "lat": -1.2000, "lng": 36.8500},
        {"name": "Mombasa Road", "lat": -1.3167, "lng": 36.8833}
    ]
    
    providers_data = [
        # Garage/Mechanic Providers
        {
            "name": "AutoCare Kenya - Westlands",
            "category": "Garage / Mechanic",
            "description": "Full-service automotive repair center specializing in European and Japanese vehicles. 15+ years experience with certified technicians.",
            "contact_info": {
                "phone": "+254 700 123 456",
                "email": "info@autocarekenya.co.ke",
                "website": "www.autocarekenya.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.5,
            "services": [
                {"service_name": "Engine Oil Change", "price": "KSh 3,500 - 8,000", "duration": "30-45 mins", "booking_required": True, "extra_data": {"oil_types": ["Synthetic", "Semi-Synthetic"], "warranty": "3 months"}},
                {"service_name": "Brake Pad Replacement", "price": "KSh 8,000 - 15,000", "duration": "1-2 hours", "booking_required": True, "extra_data": {"parts_warranty": "6 months"}},
                {"service_name": "Engine Tune-Up", "price": "KSh 12,000 - 25,000", "duration": "2-3 hours", "booking_required": True, "extra_data": {"includes_diagnostics": True}},
                {"service_name": "AC Gas Refill", "price": "KSh 4,500 - 7,000", "duration": "45 mins", "booking_required": False, "extra_data": {"gas_type": "R134a"}},
                {"service_name": "General Vehicle Inspection", "price": "KSh 2,500 - 4,000", "duration": "1 hour", "booking_required": True, "extra_data": {"report_included": True}}
            ]
        },
        {
            "name": "QuickFix Motors - Industrial Area",
            "category": "Garage / Mechanic", 
            "description": "Fast and reliable car repair services. Open 7 days a week with emergency services available.",
            "contact_info": {
                "phone": "+254 722 987 654",
                "email": "quickfix@motors.co.ke",
                "whatsapp": "+254 722 987 654"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.2,
            "services": [
                {"service_name": "Engine Oil Change", "price": "KSh 2,800 - 6,500", "duration": "25 mins", "booking_required": False, "extra_data": {"express_service": True}},
                {"service_name": "Tyre Replacement", "price": "KSh 8,000 - 25,000", "duration": "30 mins", "booking_required": False, "extra_data": {"brands": ["Michelin", "Bridgestone", "Goodyear"]}},
                {"service_name": "Battery Testing & Replacement", "price": "KSh 15,000 - 35,000", "duration": "20 mins", "booking_required": False, "extra_data": {"battery_warranty": "2 years"}},
                {"service_name": "Jump Start", "price": "KSh 1,500", "duration": "10 mins", "booking_required": False, "extra_data": {"mobile_service": True}}
            ]
        },
        {
            "name": "Premium Auto Services - Karen",
            "category": "Garage / Mechanic",
            "description": "Luxury car specialists with state-of-the-art equipment. Authorized service center for premium brands.",
            "contact_info": {
                "phone": "+254 20 123 4567",
                "email": "premium@autoservices.co.ke",
                "website": "www.premiumautoservices.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.8,
            "services": [
                {"service_name": "Engine Oil Change", "price": "KSh 8,000 - 18,000", "duration": "45 mins", "booking_required": True, "extra_data": {"premium_oils_only": True, "complementary_wash": True}},
                {"service_name": "Full Body Paint", "price": "KSh 80,000 - 200,000", "duration": "5-7 days", "booking_required": True, "extra_data": {"color_matching": True, "warranty": "2 years"}},
                {"service_name": "Engine Overhaul / Rebuild", "price": "KSh 150,000 - 500,000", "duration": "1-2 weeks", "booking_required": True, "extra_data": {"genuine_parts_only": True}},
                {"service_name": "Ceramic Coating / Waxing", "price": "KSh 25,000 - 50,000", "duration": "1 day", "booking_required": True, "extra_data": {"premium_coating": True}}
            ]
        },
        
        # Fuel Station Providers
        {
            "name": "Shell Westlands",
            "category": "Fuel Station",
            "description": "Full-service fuel station with convenience store, car wash, and basic maintenance services.",
            "contact_info": {
                "phone": "+254 700 555 123",
                "email": "westlands@shell.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.0,
            "services": [
                {"service_name": "Petrol Refuel", "price": "KSh 180-200/liter", "duration": "5-10 mins", "booking_required": False, "extra_data": {"fuel_types": ["Regular", "Premium", "Super"]}},
                {"service_name": "Diesel Refuel", "price": "KSh 160-180/liter", "duration": "5-10 mins", "booking_required": False, "extra_data": {"bulk_discounts": True}},
                {"service_name": "Exterior Wash", "price": "KSh 500 - 1,500", "duration": "15-30 mins", "booking_required": False, "extra_data": {"wash_types": ["Basic", "Premium", "Deluxe"]}},
                {"service_name": "Tyre Pressure Check", "price": "Free", "duration": "5 mins", "booking_required": False, "extra_data": {"free_service": True}}
            ]
        },
        {
            "name": "Total Thika Road",
            "category": "Fuel Station",
            "description": "24/7 fuel station with restaurant, ATM, and vehicle services. Located on major highway.",
            "contact_info": {
                "phone": "+254 722 333 444",
                "email": "thikaroad@total.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.1,
            "services": [
                {"service_name": "Petrol Refuel", "price": "KSh 175-195/liter", "duration": "5-10 mins", "booking_required": False, "extra_data": {"loyalty_program": True}},
                {"service_name": "Diesel Refuel", "price": "KSh 155-175/liter", "duration": "5-10 mins", "booking_required": False, "extra_data": {"truck_friendly": True}},
                {"service_name": "LPG / CNG Refuel", "price": "KSh 120-140/liter", "duration": "10-15 mins", "booking_required": False, "extra_data": {"conversion_available": True}},
                {"service_name": "Emergency Fuel Delivery", "price": "KSh 2,000 + fuel cost", "duration": "30-60 mins", "booking_required": True, "extra_data": {"mobile_service": True}}
            ]
        },
        
        # Car Wash & Detailing
        {
            "name": "Sparkle Auto Spa - Kilimani",
            "category": "Car Wash & Detailing",
            "description": "Premium car wash and detailing services with eco-friendly products and professional equipment.",
            "contact_info": {
                "phone": "+254 700 777 888",
                "email": "info@sparkleautospa.co.ke",
                "instagram": "@sparkleautospa"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.6,
            "services": [
                {"service_name": "Exterior Wash", "price": "KSh 800 - 2,000", "duration": "30-45 mins", "booking_required": True, "extra_data": {"eco_friendly": True, "wax_included": True}},
                {"service_name": "Interior Deep Clean", "price": "KSh 2,500 - 5,000", "duration": "1-2 hours", "booking_required": True, "extra_data": {"leather_conditioning": True}},
                {"service_name": "Engine Bay Cleaning", "price": "KSh 1,500 - 3,000", "duration": "45 mins", "booking_required": True, "extra_data": {"degreasing": True}},
                {"service_name": "Ceramic Coating / Waxing", "price": "KSh 15,000 - 35,000", "duration": "4-6 hours", "booking_required": True, "extra_data": {"warranty": "1 year"}}
            ]
        },
        {
            "name": "QuickWash Mobile - CBD",
            "category": "Car Wash & Detailing",
            "description": "Mobile car wash service that comes to your location. Perfect for busy professionals.",
            "contact_info": {
                "phone": "+254 722 111 222",
                "email": "mobile@quickwash.co.ke",
                "whatsapp": "+254 722 111 222"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.3,
            "services": [
                {"service_name": "Exterior Wash", "price": "KSh 1,200 - 2,500", "duration": "45-60 mins", "booking_required": True, "extra_data": {"mobile_service": True, "water_efficient": True}},
                {"service_name": "Interior Deep Clean", "price": "KSh 3,000 - 6,000", "duration": "1.5-2 hours", "booking_required": True, "extra_data": {"mobile_service": True}},
                {"service_name": "Home Pickup for Service", "price": "KSh 500 - 1,000", "duration": "15 mins", "booking_required": True, "extra_data": {"pickup_radius": "20km"}}
            ]
        },
        
        # Tyre & Wheel Center
        {
            "name": "TyreMax Kenya - Eastleigh",
            "category": "Tyre & Wheel Center",
            "description": "Leading tyre dealer with all major brands. Wheel alignment, balancing, and puncture repair services.",
            "contact_info": {
                "phone": "+254 700 444 555",
                "email": "sales@tyremaxkenya.co.ke",
                "website": "www.tyremaxkenya.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.4,
            "services": [
                {"service_name": "Tyre Replacement", "price": "KSh 6,000 - 30,000", "duration": "30-45 mins", "booking_required": False, "extra_data": {"brands": ["Michelin", "Bridgestone", "Continental", "Goodyear", "Pirelli"]}},
                {"service_name": "Wheel Balancing", "price": "KSh 1,500 - 3,000", "duration": "20-30 mins", "booking_required": False, "extra_data": {"computer_balancing": True}},
                {"service_name": "Wheel Alignment", "price": "KSh 2,500 - 4,500", "duration": "30-45 mins", "booking_required": True, "extra_data": {"laser_alignment": True}},
                {"service_name": "Puncture Repair", "price": "KSh 500 - 1,500", "duration": "15-30 mins", "booking_required": False, "extra_data": {"patch_repair": True}}
            ]
        },
        
        # Battery & Electrical Specialist
        {
            "name": "PowerBatt Electrical - South B",
            "category": "Battery & Electrical Specialist",
            "description": "Specialized in automotive batteries, alternators, and electrical systems. Authorized dealer for major battery brands.",
            "contact_info": {
                "phone": "+254 722 666 777",
                "email": "info@powerbatt.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.5,
            "services": [
                {"service_name": "Battery Testing & Replacement", "price": "KSh 12,000 - 40,000", "duration": "20-30 mins", "booking_required": False, "extra_data": {"brands": ["Exide", "Varta", "Delphi", "Bosch"], "warranty": "2-3 years"}},
                {"service_name": "Alternator / Starter Motor Service", "price": "KSh 8,000 - 25,000", "duration": "1-2 hours", "booking_required": True, "extra_data": {"rebuild_service": True}},
                {"service_name": "Wiring & Lighting Repairs", "price": "KSh 3,000 - 15,000", "duration": "1-3 hours", "booking_required": True, "extra_data": {"diagnostic_included": True}},
                {"service_name": "Jump Start", "price": "KSh 1,000", "duration": "10 mins", "booking_required": False, "extra_data": {"mobile_service": True}}
            ]
        },
        
        # Insurance Agency
        {
            "name": "Kenya Insurance Brokers - CBD",
            "category": "Insurance Agency",
            "description": "Comprehensive motor insurance services with competitive rates and fast claims processing.",
            "contact_info": {
                "phone": "+254 20 123 4567",
                "email": "motor@kenyainsurance.co.ke",
                "website": "www.kenyainsurance.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.2,
            "services": [
                {"service_name": "Insurance Renewal", "price": "Varies by vehicle", "duration": "30-60 mins", "booking_required": True, "extra_data": {"online_quotes": True, "multiple_insurers": True}},
                {"service_name": "Accident Claim Assistance", "price": "Free", "duration": "1-2 hours", "booking_required": True, "extra_data": {"24hr_claims": True}},
                {"service_name": "Vehicle Valuation", "price": "KSh 2,000 - 5,000", "duration": "1 hour", "booking_required": True, "extra_data": {"certified_valuers": True}},
                {"service_name": "Logbook Transfer", "price": "KSh 3,000 - 8,000", "duration": "2-5 days", "booking_required": True, "extra_data": {"documentation_assistance": True}}
            ]
        },
        
        
        # Roadside Assistance
        {
            "name": "Rescue 24/7 - Nairobi",
            "category": "Roadside Assistance / Towing Service",
            "description": "24/7 roadside assistance and towing services across Nairobi and surrounding areas.",
            "contact_info": {
                "phone": "+254 700 999 000",
                "email": "rescue@24seven.co.ke",
                "emergency": "+254 700 999 000"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.7,
            "services": [
                {"service_name": "Towing", "price": "KSh 3,000 - 8,000", "duration": "30-60 mins", "booking_required": True, "extra_data": {"24hr_service": True, "flatbed_available": True}},
                {"service_name": "Jump Start", "price": "KSh 2,000", "duration": "15-30 mins", "booking_required": True, "extra_data": {"mobile_service": True}},
                {"service_name": "Emergency Fuel Delivery", "price": "KSh 2,500 + fuel cost", "duration": "30-45 mins", "booking_required": True, "extra_data": {"emergency_service": True}},
                {"service_name": "Flat Tyre Service", "price": "KSh 1,500 - 3,000", "duration": "20-40 mins", "booking_required": True, "extra_data": {"spare_tyre_available": True}}
            ]
        },
        
        # Inspection & Emission Testing
        {
            "name": "NTSA Approved Inspection Center - Kasarani",
            "category": "Inspection & Emission Testing Center",
            "description": "NTSA approved vehicle inspection center with modern equipment for comprehensive vehicle testing.",
            "contact_info": {
                "phone": "+254 700 888 999",
                "email": "inspection@ntsaapproved.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.3,
            "services": [
                {"service_name": "General Vehicle Inspection", "price": "KSh 3,000 - 5,000", "duration": "1-2 hours", "booking_required": True, "extra_data": {"ntsa_approved": True, "certificate_included": True}},
                {"service_name": "Pre-Purchase Inspection", "price": "KSh 4,000 - 7,000", "duration": "2-3 hours", "booking_required": True, "extra_data": {"detailed_report": True}},
                {"service_name": "Emissions Test", "price": "KSh 2,000 - 3,500", "duration": "30-45 mins", "booking_required": True, "extra_data": {"environmental_compliance": True}},
                {"service_name": "OBD & ECU Diagnostics", "price": "KSh 2,500 - 4,500", "duration": "45-60 mins", "booking_required": True, "extra_data": {"modern_diagnostics": True}}
            ]
        },
        
        # Hybrid / EV Specialist
        {
            "name": "EV Solutions Kenya - Lavington",
            "category": "Hybrid / EV Specialist",
            "description": "Specialized in hybrid and electric vehicle maintenance, charging solutions, and battery management.",
            "contact_info": {
                "phone": "+254 700 111 333",
                "email": "info@evsolutionskenya.co.ke",
                "website": "www.evsolutionskenya.co.ke"
            },
            "location": random.choice(nairobi_areas),
            "is_registered": True,
            "rating": 4.6,
            "services": [
                {"service_name": "Battery Health Check", "price": "KSh 5,000 - 10,000", "duration": "1-2 hours", "booking_required": True, "extra_data": {"specialized_equipment": True, "battery_report": True}},
                {"service_name": "EV Charger Installation", "price": "KSh 80,000 - 200,000", "duration": "1-2 days", "booking_required": True, "extra_data": {"home_installation": True, "warranty": "2 years"}},
                {"service_name": "Hybrid System Service", "price": "KSh 15,000 - 35,000", "duration": "2-4 hours", "booking_required": True, "extra_data": {"certified_technicians": True}},
                {"service_name": "EV Charging", "price": "KSh 50-100/kWh", "duration": "30 mins - 2 hours", "booking_required": False, "extra_data": {"fast_charging": True, "multiple_connectors": True}}
            ]
        }
    ]
    
    return providers_data

def main():
    """Main function to run the provider seeding script"""
    print("Starting provider seeding...")
    print("=" * 60)
    
    try:
        # Get database connection
        conn = get_db_connection()
        
        # Get category mappings
        print("\nGetting category mappings...")
        provider_categories, service_categories = get_category_mappings(conn)
        print(f"   Found {len(provider_categories)} provider categories")
        print(f"   Found {len(service_categories)} service categories")
        
        # Get services by category
        print("\nGetting services by category...")
        services_by_category = get_services_by_category(conn)
        print(f"   Found services in {len(services_by_category)} categories")
        
        # Get provider data
        providers_data = get_nairobi_providers_data()
        
        # Create providers and attach services
        print(f"\nCreating {len(providers_data)} providers...")
        created_providers = 0
        total_services_attached = 0
        
        for provider_data in providers_data:
            print(f"\n--- Creating: {provider_data['name']} ---")
            
            # Create provider
            provider_id = create_provider(conn, provider_data, provider_categories)
            if not provider_id:
                continue
                
            created_providers += 1
            
            # Prepare services for attachment
            services_to_attach = []
            for service_info in provider_data['services']:
                # Find matching service by name
                service_found = None
                for category_name, services in services_by_category.items():
                    for service in services:
                        if service['name'] == service_info['service_name']:
                            service_found = service
                            break
                    if service_found:
                        break
                
                if service_found:
                    service_data = {
                        'service_id': service_found['id'],
                        'display_name': service_info.get('display_name'),
                        'price': service_info['price'],
                        'duration': service_info.get('duration'),
                        'booking_required': service_info.get('booking_required', False),
                        'extra_data': service_info.get('extra_data', {})
                    }
                    services_to_attach.append(service_data)
                else:
                    print(f"   Service not found: {service_info['service_name']}")
            
            # Attach services to provider
            if services_to_attach:
                attach_services_to_provider(conn, provider_id, services_to_attach)
                total_services_attached += len(services_to_attach)
        
        print("\n" + "=" * 60)
        print("Provider seeding completed successfully!")
        print(f"Summary:")
        print(f"   - Providers Created: {created_providers}")
        print(f"   - Services Attached: {total_services_attached}")
        print(f"   - Average Services per Provider: {total_services_attached/created_providers:.1f}")
        
    except Exception as e:
        print(f"Error during seeding: {str(e)}")
        raise
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
