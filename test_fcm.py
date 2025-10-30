#!/usr/bin/env python3
"""
FCM Test Script for DriveOn Platform
This script tests FCM functionality for both alert and social services
"""

import requests
import json
import sys
from typing import Dict, Any

# Configuration
BASE_URL = "http://localhost"  # Change to your server URL
ALERT_SERVICE_PORT = 8006
SOCIAL_SERVICE_PORT = 8008

def test_fcm_status(service: str, port: int) -> Dict[str, Any]:
    """Test FCM status for a service"""
    url = f"{BASE_URL}:{port}/alerts/test/fcm/status" if service == "alert" else f"{BASE_URL}:{port}/social/notifications/test/fcm/status"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e), "service": service}

def test_fcm_send(service: str, port: int, token: str, title: str = None, body: str = None) -> Dict[str, Any]:
    """Test FCM send for a service"""
    url = f"{BASE_URL}:{port}/alerts/test/fcm/send" if service == "alert" else f"{BASE_URL}:{port}/social/notifications/test/fcm/send"
    
    params = {"token": token}
    if title:
        params["title"] = title
    if body:
        params["body"] = body
    
    try:
        response = requests.post(url, params=params, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e), "service": service}

def test_fcm_multicast(service: str, port: int, tokens: list, title: str = None, body: str = None) -> Dict[str, Any]:
    """Test FCM multicast for a service"""
    url = f"{BASE_URL}:{port}/alerts/test/fcm/multicast" if service == "alert" else f"{BASE_URL}:{port}/social/notifications/test/fcm/multicast"
    
    data = {"tokens": tokens}
    if title:
        data["title"] = title
    if body:
        data["body"] = body
    
    try:
        response = requests.post(url, json=data, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e), "service": service}

def test_fcm_topic(service: str, port: int, topic: str, title: str = None, body: str = None) -> Dict[str, Any]:
    """Test FCM topic for a service"""
    url = f"{BASE_URL}:{port}/alerts/test/fcm/topic" if service == "alert" else f"{BASE_URL}:{port}/social/notifications/test/fcm/topic"
    
    params = {"topic": topic}
    if title:
        params["title"] = title
    if body:
        params["body"] = body
    
    try:
        response = requests.post(url, params=params, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e), "service": service}

def print_result(service: str, test_name: str, result: Dict[str, Any]):
    """Print test result in a formatted way"""
    print(f"\n{'='*60}")
    print(f"🔔 {service.upper()} SERVICE - {test_name.upper()}")
    print(f"{'='*60}")
    
    if "error" in result:
        print(f"❌ Error: {result['error']}")
    else:
        print(f"✅ Success!")
        for key, value in result.items():
            if key != "result":
                print(f"   {key}: {value}")
        
        if "result" in result and isinstance(result["result"], dict):
            print(f"   Detailed result:")
            for key, value in result["result"].items():
                print(f"     {key}: {value}")

def main():
    """Main test function"""
    print("🚀 DriveOn FCM Test Script")
    print("=" * 60)
    
    # Get FCM token from user
    print("\n📱 Please provide your FCM token for testing:")
    print("   (You can get this from your Flutter app's FCM service)")
    fcm_token = input("FCM Token: ").strip()
    
    if not fcm_token:
        print("❌ No FCM token provided. Exiting.")
        sys.exit(1)
    
    # Test Alert Service
    print("\n🔔 Testing Alert Service...")
    
    # Check FCM status
    result = test_fcm_status("alert", ALERT_SERVICE_PORT)
    print_result("alert", "FCM Status Check", result)
    
    if result.get("fcm_initialized"):
        # Test single notification
        result = test_fcm_send(
            "alert", 
            ALERT_SERVICE_PORT, 
            fcm_token,
            "Test Alert Notification",
            "This is a test alert from DriveOn Alert Service"
        )
        print_result("alert", "Single Notification", result)
        
        # Test multicast notification
        result = test_fcm_multicast(
            "alert",
            ALERT_SERVICE_PORT,
            [fcm_token],
            "Test Alert Multicast",
            "This is a test multicast alert from DriveOn"
        )
        print_result("alert", "Multicast Notification", result)
        
        # Test topic notification
        result = test_fcm_topic(
            "alert",
            ALERT_SERVICE_PORT,
            "test-topic",
            "Test Alert Topic",
            "This is a test topic alert from DriveOn"
        )
        print_result("alert", "Topic Notification", result)
    
    # Test Social Service
    print("\n📱 Testing Social Service...")
    
    # Check FCM status
    result = test_fcm_status("social", SOCIAL_SERVICE_PORT)
    print_result("social", "FCM Status Check", result)
    
    if result.get("fcm_initialized"):
        # Test single social notification
        result = test_fcm_send(
            "social",
            SOCIAL_SERVICE_PORT,
            fcm_token,
            "Test Social Notification",
            "This is a test social notification from DriveOn Social Service"
        )
        print_result("social", "Single Social Notification", result)
        
        # Test multicast social notification
        result = test_fcm_multicast(
            "social",
            SOCIAL_SERVICE_PORT,
            [fcm_token],
            "Test Social Multicast",
            "This is a test social multicast from DriveOn"
        )
        print_result("social", "Multicast Social Notification", result)
        
        # Test topic social notification
        result = test_fcm_topic(
            "social",
            SOCIAL_SERVICE_PORT,
            "social-updates",
            "Test Social Topic",
            "This is a test social topic notification from DriveOn"
        )
        print_result("social", "Topic Social Notification", result)
    
    print("\n🎉 FCM Testing Complete!")
    print("=" * 60)
    print("📝 Next Steps:")
    print("   1. Check your device for notifications")
    print("   2. Verify notification data and actions work")
    print("   3. Test with real app scenarios")

if __name__ == "__main__":
    main()
