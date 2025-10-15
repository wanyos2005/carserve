#!/usr/bin/env python3
"""
Update script to add requirements to existing services.
This script updates all existing services with default Price requirement and category-specific requirements.

Usage:
    python update_service_requirements.py
"""

import psycopg2
import os
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_connection():
    """Get database connection using the exact DATABASE_URL"""
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        # Use the exact DATABASE_URL from environment
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

def get_service_requirements(service_name, category_name):
    """Get requirements for a specific service based on its name and category"""
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
    elif category_name == "Inspection & Diagnostics":
        requirements["fields"].extend([
            {
                "name": "vehicle_year",
                "label": "Vehicle Year",
                "type": "number",
                "required": True
            },
            {
                "name": "vehicle_make",
                "label": "Vehicle Make",
                "type": "text",
                "required": True
            }
        ])
    elif category_name == "Insurance & Documentation":
        requirements["fields"].extend([
            {
                "name": "document_type",
                "label": "Document Type",
                "type": "select",
                "options": ["Insurance", "Registration", "Logbook", "Valuation"],
                "required": True
            },
            {
                "name": "vehicle_details",
                "label": "Vehicle Details",
                "type": "text",
                "required": True
            }
        ])
    
    return requirements

def update_service_requirements(conn):
    """Update all services with requirements"""
    cursor = conn.cursor()
    
    # Get all services with their categories
    cursor.execute("""
        SELECT s.id, s.name, sc.name as category_name, s.requirements
        FROM service_providers.services s
        JOIN service_providers.service_categories sc ON s.category_id = sc.id
        ORDER BY s.name
    """)
    
    services = cursor.fetchall()
    updated_count = 0
    
    for service_id, service_name, category_name, current_requirements in services:
        try:
            # Get new requirements for this service
            new_requirements = get_service_requirements(service_name, category_name)
            
            # Update the service with new requirements
            cursor.execute(
                "UPDATE service_providers.services SET requirements = %s WHERE id = %s",
                (json.dumps(new_requirements), service_id)
            )
            
            updated_count += 1
            print(f"✅ Updated service: {service_name} (Category: {category_name})")
            print(f"   Requirements: {len(new_requirements['fields'])} fields")
            
        except Exception as e:
            print(f"❌ Error updating service {service_name}: {str(e)}")
    
    conn.commit()
    cursor.close()
    return updated_count

def main():
    """Main function to run the update script"""
    print("🔄 Updating service requirements...")
    print("=" * 50)
    
    try:
        # Get database connection
        conn = get_db_connection()
        
        # Update service requirements
        print("\n🔧 Updating Services with Requirements...")
        updated_count = update_service_requirements(conn)
        
        print("\n" + "=" * 50)
        print("🎉 Service requirements update completed successfully!")
        print(f"📊 Summary:")
        print(f"   - Services Updated: {updated_count}")
        print(f"   - All services now have Price requirement")
        print(f"   - Category-specific requirements added where applicable")
        
    except Exception as e:
        print(f"❌ Error during update: {str(e)}")
        raise
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
