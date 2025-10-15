#!/usr/bin/env python3
"""
Test Alert Creation for MVP
This script tests creating alerts using the API endpoints
"""

import requests
import json
from datetime import datetime, timedelta

# Alert service base URL
BASE_URL = "http://localhost:8006"

def test_alert_creation():
    """Test creating different types of alerts"""
    
    print("🧪 Testing Alert Creation for MVP...")
    print("=" * 50)
    
    # Test data for different alert types
    test_alerts = [
        {
            "name": "Insurance Expiry Alert",
            "type": "insurance_expiry", #will help the alert service to determine the rule to use
            "data": {
                "user_id": 1,
                "type": "insurance_expiry",
                "title": "Insurance Expires in 7 days",
                "message": "Your insurance policy expires in 7 day(s). Renew now to avoid penalties and stay protected.",
                "priority": 3,#this is the priority of the alert, the numbers are defined
                "vehicle_id": "vehicle_123",
                "policy_id": "policy_456",
                "channels": ["email", "in_app"],
                "scheduled_at": (datetime.now() + timedelta(minutes=1)).isoformat(),
                "alert_metadata": {
                    "days_until_expiry": 7,
                    "policy_number": "INS-2024-001",
                    "provider": "Jubilee Insurance"
                }
            }
        },
        {
            "name": "Service Due Alert", 
            "type": "service_due",
            "data": {
                "user_id": 1,
                "type": "service_due",
                "title": "Service Due - 5000 km",
                "message": "Your vehicle service is due. You've driven 5000 km since last service. Book your appointment now.",
                "priority": 2,
                "vehicle_id": "vehicle_123",
                "channels": ["email", "in_app"],
                "scheduled_at": (datetime.now() + timedelta(minutes=2)).isoformat(),
                "alert_metadata": {
                    "mileage_since_service": 5000,
                    "last_service_date": "2024-01-15",
                    "recommended_service_type": "oil_change"
                }
            }
        },
        {
            "name": "Promotional Alert",
            "type": "promotional", 
            "data": {
                "user_id": 1,
                "type": "promotional",
                "title": "🎉 Special Offer: AutoCare Garage",
                "message": "Special offer: 20% off oil change service. Valid until 2024-12-31.",
                "priority": 1, #1 as compared to 2 and 3, is the highest priority and means it will be sent first
                "provider_id": "provider_789",
                "channels": ["email", "in_app"],
                "scheduled_at": (datetime.now() + timedelta(minutes=3)).isoformat(),
                "alert_metadata": {
                    "offer_description": "20% off oil change service",
                    "expiry_date": "2024-12-31",
                    "provider_name": "AutoCare Garage",
                    "discount_code": "OIL20"
                }
            }
        }
    ]
    
    created_alerts = []
    
    for test_alert in test_alerts:
        print(f"\n📝 Creating {test_alert['name']}...")
        
        try:
            response = requests.post(
                f"{BASE_URL}/alerts/",
                json=test_alert['data'],
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                alert_data = response.json()
                created_alerts.append(alert_data)
                print(f"✅ Created alert: {alert_data['id']}")
                print(f"   Title: {alert_data['title']}")
                print(f"   Status: {alert_data['status']}")
                print(f"   Scheduled: {alert_data['scheduled_at']}")
            else:
                print(f"❌ Failed to create alert: {response.status_code}")
                print(f"   Error: {response.text}")
                
        except Exception as e:
            print(f"❌ Error creating alert: {e}")
    
    return created_alerts

def test_alert_retrieval():
    """Test retrieving alerts"""
    
    print(f"\n📋 Testing Alert Retrieval...")
    print("=" * 30)
    
    try:
        # Get all alerts
        response = requests.get(f"{BASE_URL}/alerts/")
        
        if response.status_code == 200:
            alerts = response.json()
            print(f"✅ Retrieved {len(alerts)} alerts")
            
            for alert in alerts:
                print(f"   - {alert['title']} (Status: {alert['status']})")
        else:
            print(f"❌ Failed to retrieve alerts: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error retrieving alerts: {e}")

def test_alert_rules():
    """Test retrieving alert rules"""
    
    print(f"\n📋 Testing Alert Rules...")
    print("=" * 30)
    
    try:
        # Get all alert rules
        response = requests.get(f"{BASE_URL}/rules/")
        
        if response.status_code == 200:
            rules = response.json()
            print(f"✅ Retrieved {len(rules)} alert rules")
            
            for rule in rules:
                print(f"   - {rule['name']} ({rule['alert_type']})")
        else:
            print(f"❌ Failed to retrieve rules: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error retrieving rules: {e}")

def test_health_endpoint():
    """Test the health endpoint"""
    
    print(f"\n🏥 Testing Health Endpoint...")
    print("=" * 30)
    
    try:
        response = requests.get(f"{BASE_URL}/health")
        
        if response.status_code == 200:
            health_data = response.json()
            print(f"✅ Service Status: {health_data['status']}")
            print(f"   Version: {health_data['version']}")
            print(f"   Features: {len(health_data['features'])} available")
        else:
            print(f"❌ Health check failed: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error checking health: {e}")

if __name__ == "__main__":
    print("🚀 Alert Service MVP Testing")
    print("=" * 50)
    
    # Test health first
    test_health_endpoint()
    
    # Test alert rules
    test_alert_rules()
    
    # Test alert creation
    created_alerts = test_alert_creation()
    
    # Test alert retrieval
    test_alert_retrieval()
    
    print(f"\n🎉 MVP Testing Complete!")
    print(f"✅ Created {len(created_alerts)} test alerts")
    print(f"📧 Check your email for alert notifications!")
    print(f"🌐 API Documentation: {BASE_URL}/docs")
