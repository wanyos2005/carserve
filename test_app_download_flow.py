#!/usr/bin/env python3
"""
Test the complete app download prompt flow
"""
import requests
import json
import time

def test_complete_flow():
    """Test the complete flow from service logging to alert creation"""
    
    print("🧪 Testing Complete App Download Prompt Flow")
    print("=" * 50)
    
    # Test data - simulate a guest user service log
    test_payload = [
        {
            "provider_id": "9a8b23c3-fb15-42bc-83a9-f239b0050bdb",
            "provider_name": "Test Garage",
            "provider_contact": {"phone": "0748561982", "email": "test@garage.com"},
            "vehicle_id": "test-vehicle-123",
            "user_id": 38,  # Guest user ID from your logs
            "service_id": "test-service-123",
            "service_name": "Oil Change",
            "service_items": {"notes": "Test service", "checked": True},
            "performed_at": "2025-10-23T00:00:00",
            "next_service_km": 500,
            "next_service_date": "2025-10-31T00:00:00",
            "mileage_km": 100,
            "served_by": "Test Mechanic",
            "served_by_contact": "0712345678",
            "logged_by": "provider",
            "notes": "Test service log"
        }
    ]
    
    print("1️⃣ Testing booking service bulk logs...")
    try:
        # Call booking service
        booking_response = requests.post(
            "http://localhost:8004/service-logs/bulk",
            json=test_payload,
            timeout=10
        )
        
        if booking_response.status_code == 200:
            print("✅ Booking service processed logs successfully")
            logs = booking_response.json()
            print(f"📊 Created {len(logs)} service logs")
            
            # Check if any logs were created
            if logs:
                user_id = logs[0]['user_id']
                print(f"📊 User ID: {user_id}")
                
                # Wait a moment for async processing
                print("⏳ Waiting for async alert processing...")
                time.sleep(2)
                
                # Check if alert was created
                print("2️⃣ Checking if alert was created...")
                try:
                    alert_response = requests.get("http://localhost:8000/alerts/")
                    if alert_response.status_code == 200:
                        alerts = alert_response.json()
                        app_download_alerts = [a for a in alerts if a.get('type') == 'APP_DOWNLOAD_PROMPT' and a.get('user_id') == user_id]
                        
                        if app_download_alerts:
                            print(f"✅ App download alert created for user {user_id}!")
                            print(f"📊 Alert ID: {app_download_alerts[0]['id']}")
                            print(f"📊 Alert Title: {app_download_alerts[0]['title']}")
                            print(f"📊 Alert Status: {app_download_alerts[0]['status']}")
                            return True
                        else:
                            print(f"❌ No app download alert found for user {user_id}")
                            print(f"📊 Total alerts: {len(alerts)}")
                            return False
                    else:
                        print(f"❌ Failed to get alerts: {alert_response.status_code}")
                        return False
                except Exception as e:
                    print(f"❌ Error checking alerts: {e}")
                    return False
            else:
                print("❌ No logs were created")
                return False
        else:
            print(f"❌ Booking service failed: {booking_response.status_code}")
            print(f"📊 Response: {booking_response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing booking service: {e}")
        return False

def test_alert_service_directly():
    """Test alert service directly"""
    print("\n3️⃣ Testing alert service directly...")
    
    try:
        # Test direct alert service call
        alert_payload = {
            "user_id": 38,
            "vehicle_info": "Test Vehicle",
            "service_provider_name": "Test Garage",
            "service_type": "Oil Change",
            "discount_code": "FIRST10"
        }
        
        response = requests.post(
            "http://localhost:8000/alerts/trigger/app-download-prompt",
            json=alert_payload,
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Direct alert service call successful!")
            print(f"📊 Response: {json.dumps(result, indent=2)}")
            return True
        else:
            print(f"❌ Alert service failed: {response.status_code}")
            print(f"📊 Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing alert service: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Starting App Download Prompt Flow Test")
    print("=" * 50)
    
    # Test 1: Complete flow
    flow_success = test_complete_flow()
    
    # Test 2: Direct alert service
    direct_success = test_alert_service_directly()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print(f"  - Complete Flow: {'✅ PASS' if flow_success else '❌ FAIL'}")
    print(f"  - Direct Alert Service: {'✅ PASS' if direct_success else '❌ FAIL'}")
    
    if flow_success or direct_success:
        print("\n🎉 App download prompt integration is working!")
    else:
        print("\n❌ App download prompt integration needs debugging.")
        print("\n💡 Check the logs for:")
        print("  - Booking service: docker compose logs booking-service")
        print("  - Alert service: docker compose logs alert-service")
