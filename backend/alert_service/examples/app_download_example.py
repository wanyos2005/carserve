#!/usr/bin/env python3
"""
Example script demonstrating how to trigger app download prompts
when a service is logged for a customer without the app.
"""

import requests
import json
from datetime import datetime

# Configuration
ALERT_SERVICE_URL = "http://localhost:8000"  # Adjust based on your setup

def trigger_app_download_prompt(
    user_id: int,
    vehicle_info: str,
    service_provider_name: str,
    service_type: str,
    discount_code: str = "FIRST10"
):
    """Trigger app download prompt for a customer"""
    
    url = f"{ALERT_SERVICE_URL}/alerts/trigger/app-download-prompt"
    
    payload = {
        "user_id": user_id,
        "vehicle_info": vehicle_info,
        "service_provider_name": service_provider_name,
        "service_type": service_type,
        "discount_code": discount_code
    }
    
    try:
        response = requests.post(url, json=payload)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ App download prompt sent successfully!")
            print(f"   Alert ID: {result['alert_id']}")
            print(f"   User ID: {result['user_id']}")
            print(f"   Discount Code: {result['discount_code']}")
            return True
        else:
            print(f"❌ Failed to send app download prompt: {response.status_code}")
            print(f"   Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error sending app download prompt: {e}")
        return False

def simulate_service_logging_scenarios():
    """Simulate different service logging scenarios"""
    
    print("🚗 Simulating App Download Prompt Scenarios")
    print("=" * 50)
    
    # Scenario 1: Mechanic logs oil change
    print("\n1. Mechanic logs oil change for customer without app:")
    trigger_app_download_prompt(
        user_id=123,
        vehicle_info="Toyota Camry 2020",
        service_provider_name="AutoCare Garage",
        service_type="Oil Change",
        discount_code="MECH10"
    )
    
    # Scenario 2: Fuel station logs fuel service
    print("\n2. Fuel station logs fuel service for customer without app:")
    trigger_app_download_prompt(
        user_id=456,
        vehicle_info="Honda Civic 2019",
        service_provider_name="Shell Station",
        service_type="Fuel Service",
        discount_code="FUEL15"
    )
    
    # Scenario 3: Car wash logs service
    print("\n3. Car wash logs service for customer without app:")
    trigger_app_download_prompt(
        user_id=789,
        vehicle_info="BMW X5 2021",
        service_provider_name="Sparkle Car Wash",
        service_type="Full Car Wash",
        discount_code="WASH20"
    )
    
    # Scenario 4: Repair service
    print("\n4. Repair shop logs repair service for customer without app:")
    trigger_app_download_prompt(
        user_id=101,
        vehicle_info="Ford F-150 2018",
        service_provider_name="Fix-It Auto Repair",
        service_type="Brake Repair",
        discount_code="REPAIR10"
    )

def check_alert_service_health():
    """Check if alert service is running"""
    
    try:
        response = requests.get(f"{ALERT_SERVICE_URL}/health")
        if response.status_code == 200:
            health_data = response.json()
            print(f"✅ Alert service is healthy: {health_data['status']}")
            print(f"   Version: {health_data['version']}")
            print(f"   Features: {', '.join(health_data['features'])}")
            return True
        else:
            print(f"❌ Alert service health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to alert service: {e}")
        return False

def get_recent_alerts(user_id: int = None):
    """Get recent alerts (for testing)"""
    
    try:
        url = f"{ALERT_SERVICE_URL}/alerts"
        if user_id:
            url += f"?user_id={user_id}"
        
        response = requests.get(url)
        if response.status_code == 200:
            alerts = response.json()
            print(f"\n📋 Recent Alerts ({len(alerts)} found):")
            for alert in alerts[:5]:  # Show first 5
                print(f"   - {alert['type']}: {alert['title']}")
            return alerts
        else:
            print(f"❌ Failed to get alerts: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Error getting alerts: {e}")
        return []

if __name__ == "__main__":
    print("🚀 App Download Prompt Example")
    print("=" * 50)
    
    # Check service health first
    if not check_alert_service_health():
        print("❌ Alert service is not available. Please start the service first.")
        exit(1)
    
    # Run the simulation
    simulate_service_logging_scenarios()
    
    # Show recent alerts
    print("\n" + "=" * 50)
    get_recent_alerts()
    
    print("\n🎉 Example completed!")
    print("\nNext steps:")
    print("1. Check your alert service logs to see the alerts being processed")
    print("2. Verify that notifications are being sent via configured channels")
    print("3. Test the integration with your actual service provider service")
    print("4. Monitor app download rates and adjust messaging as needed")
