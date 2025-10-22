#!/usr/bin/env python3
"""
Test script for app download prompt functionality
"""
import requests
import json
import sys

def test_app_download_prompt():
    """Test the app download prompt endpoint"""
    
    # Test data
    test_data = {
        "user_id": 1,
        "vehicle_info": "Toyota Camry 2020",
        "service_provider_name": "Test Garage",
        "service_type": "Oil Change",
        "discount_code": "FIRST10"
    }
    
    # Alert service URL
    alert_service_url = "http://localhost:8000"
    
    print("🧪 Testing App Download Prompt...")
    print(f"📊 Test Data: {json.dumps(test_data, indent=2)}")
    
    try:
        # Test health endpoint first
        print("\n1️⃣ Checking alert service health...")
        health_response = requests.get(f"{alert_service_url}/health", timeout=5)
        if health_response.status_code == 200:
            print("✅ Alert service is running")
        else:
            print(f"❌ Alert service health check failed: {health_response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to alert service. Make sure it's running on port 8000")
        print("💡 Start it with: cd backend/alert_service && python -m uvicorn main:app --host 0.0.0.0 --port 8000")
        return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False
    
    try:
        # Test app download prompt endpoint
        print("\n2️⃣ Testing app download prompt trigger...")
        response = requests.post(
            f"{alert_service_url}/alerts/trigger/app-download-prompt",
            json=test_data,
            timeout=10
        )
        
        print(f"📊 Response Status: {response.status_code}")
        print(f"📊 Response Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ App download prompt triggered successfully!")
            print(f"📊 Response: {json.dumps(result, indent=2)}")
            
            # Check if alert was created
            if "alert_id" in result:
                print(f"🎯 Alert ID: {result['alert_id']}")
                print(f"👤 User ID: {result['user_id']}")
                print(f"🎫 Discount Code: {result['discount_code']}")
                
                # Test getting the alert
                print("\n3️⃣ Testing alert retrieval...")
                alert_response = requests.get(f"{alert_service_url}/alerts/{result['alert_id']}")
                if alert_response.status_code == 200:
                    alert_data = alert_response.json()
                    print("✅ Alert retrieved successfully!")
                    print(f"📊 Alert Details: {json.dumps(alert_data, indent=2)}")
                else:
                    print(f"⚠️ Could not retrieve alert: {alert_response.status_code}")
            
            return True
            
        else:
            print(f"❌ App download prompt failed: {response.status_code}")
            print(f"📊 Error Response: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out. Alert service might be slow to respond.")
        return False
    except Exception as e:
        print(f"❌ Request error: {e}")
        return False

def test_user_alerts():
    """Test getting alerts for user"""
    print("\n4️⃣ Testing user alerts...")
    
    try:
        response = requests.get("http://localhost:8000/alerts/user/1/unread-count")
        if response.status_code == 200:
            result = response.json()
            print(f"✅ User 1 has {result['unread_count']} unread alerts")
            return True
        else:
            print(f"❌ Failed to get user alerts: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error getting user alerts: {e}")
        return False

def test_all_alerts():
    """Test getting all alerts"""
    print("\n5️⃣ Testing all alerts...")
    
    try:
        response = requests.get("http://localhost:8000/alerts/")
        if response.status_code == 200:
            alerts = response.json()
            print(f"✅ Found {len(alerts)} total alerts")
            
            # Show recent alerts
            for alert in alerts[:3]:  # Show first 3
                print(f"📊 Alert: {alert.get('title', 'No title')} - Status: {alert.get('status', 'Unknown')}")
            
            return True
        else:
            print(f"❌ Failed to get alerts: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error getting alerts: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Starting App Download Prompt Tests")
    print("=" * 50)
    
    # Run tests
    success = test_app_download_prompt()
    
    if success:
        test_user_alerts()
        test_all_alerts()
        print("\n🎉 All tests completed!")
    else:
        print("\n❌ Tests failed. Check the output above for details.")
        sys.exit(1)

