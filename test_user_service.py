#!/usr/bin/env python3
"""
Test script to verify user-service endpoints with the new public URL
Tests all endpoints to ensure they return proper status codes
"""

import requests
import json
import sys
from datetime import datetime

# Configuration
BASE_URL = "http://152.70.28.112"
USER_SERVICE_BASE = f"{BASE_URL}/user-service"

# Test results storage
test_results = []

def log_test(endpoint, method, status_code, response_time, success, error_msg=None):
    """Log test results"""
    result = {
        "endpoint": endpoint,
        "method": method,
        "status_code": status_code,
        "response_time_ms": response_time,
        "success": success,
        "error": error_msg,
        "timestamp": datetime.now().isoformat()
    }
    test_results.append(result)
    
    status_icon = "✅" if success else "❌"
    print(f"{status_icon} {method} {endpoint} - Status: {status_code} - Time: {response_time}ms")
    if error_msg:
        print(f"   Error: {error_msg}")

def test_endpoint(endpoint, method="GET", data=None, headers=None, expected_status=200):
    """Test a single endpoint"""
    url = f"{USER_SERVICE_BASE}{endpoint}"
    
    try:
        start_time = datetime.now()
        
        if method == "GET":
            response = requests.get(url, headers=headers, timeout=10)
        elif method == "POST":
            response = requests.post(url, json=data, headers=headers, timeout=10)
        elif method == "PUT":
            response = requests.put(url, json=data, headers=headers, timeout=10)
        elif method == "DELETE":
            response = requests.delete(url, headers=headers, timeout=10)
        else:
            raise ValueError(f"Unsupported method: {method}")
        
        end_time = datetime.now()
        response_time = int((end_time - start_time).total_seconds() * 1000)
        
        success = response.status_code == expected_status
        error_msg = None if success else f"Expected {expected_status}, got {response.status_code}"
        
        log_test(endpoint, method, response.status_code, response_time, success, error_msg)
        
        return response
        
    except requests.exceptions.RequestException as e:
        end_time = datetime.now()
        response_time = int((end_time - start_time).total_seconds() * 1000)
        log_test(endpoint, method, 0, response_time, False, str(e))
        return None

def main():
    """Run all user-service endpoint tests"""
    print("🚀 Testing User Service Endpoints")
    print("=" * 50)
    print(f"Base URL: {USER_SERVICE_BASE}")
    print(f"Test started at: {datetime.now().isoformat()}")
    print()
    
    # Test basic endpoints (should work without authentication)
    print("📋 Testing Basic Endpoints...")
    test_endpoint("/", "GET")  # Root endpoint
    test_endpoint("/health", "GET")  # Health check
    test_endpoint("/metrics", "GET")  # Metrics endpoint
    
    print()
    
    # Test authentication endpoints
    print("🔐 Testing Authentication Endpoints...")
    
    # Test send-code endpoint
    send_code_data = {
        "email": "test@example.com"
    }
    test_endpoint("/send-code", "POST", send_code_data, expected_status=200)
    
    # Test verify-code endpoint (should fail with invalid code)
    verify_code_data = {
        "email": "test@example.com",
        "code": "0000"
    }
    test_endpoint("/verify-code", "POST", verify_code_data, expected_status=401)
    
    print()
    
    # Test protected endpoints (should fail without authentication)
    print("🔒 Testing Protected Endpoints (should fail without auth)...")
    
    protected_endpoints = [
        ("/me", "GET"),
        ("/all", "GET"),
        ("/search?q=test", "GET"),
        ("/admin/list", "GET"),
    ]
    
    for endpoint, method in protected_endpoints:
        test_endpoint(endpoint, method, expected_status=401)
    
    print()
    
    # Test user lookup endpoints (should work without auth for service-to-service)
    print("👤 Testing User Lookup Endpoints...")
    test_endpoint("/users/1", "GET", expected_status=404)  # Non-existent user
    test_endpoint("/users/1/fcm-token", "GET", expected_status=404)  # Non-existent user
    
    print()
    
    # Test guest user creation
    print("👥 Testing Guest User Creation...")
    guest_data = {
        "email": "guest@example.com",
        "name": "Guest User",
        "provider_id": 1
    }
    test_endpoint("/guest", "POST", guest_data, expected_status=200)
    
    print()
    
    # Test admin endpoints (should fail without admin auth)
    print("👑 Testing Admin Endpoints (should fail without admin auth)...")
    
    admin_data = {
        "email": "newadmin@example.com",
        "name": "New Admin"
    }
    test_endpoint("/admin/create", "POST", admin_data, expected_status=403)
    
    remove_admin_data = {
        "email": "admin@example.com"
    }
    test_endpoint("/admin/remove", "DELETE", remove_admin_data, expected_status=403)
    
    print()
    
    # Test link user to provider endpoint
    print("🔗 Testing Provider Linking...")
    link_data = {
        "user_id": 1,
        "provider_id": 1
    }
    test_endpoint("/link-user-provider", "POST", link_data, expected_status=200)
    
    print()
    
    # Summary
    print("📊 Test Summary")
    print("=" * 50)
    
    total_tests = len(test_results)
    successful_tests = sum(1 for result in test_results if result["success"])
    failed_tests = total_tests - successful_tests
    
    print(f"Total Tests: {total_tests}")
    print(f"Successful: {successful_tests} ✅")
    print(f"Failed: {failed_tests} ❌")
    print(f"Success Rate: {(successful_tests/total_tests)*100:.1f}%")
    
    if failed_tests > 0:
        print("\n❌ Failed Tests:")
        for result in test_results:
            if not result["success"]:
                print(f"  - {result['method']} {result['endpoint']}: {result['error']}")
    
    print(f"\nTest completed at: {datetime.now().isoformat()}")
    
    # Save detailed results to file
    with open("user_service_test_results.json", "w") as f:
        json.dump(test_results, f, indent=2)
    
    print(f"\nDetailed results saved to: user_service_test_results.json")
    
    # Return appropriate exit code
    return 0 if failed_tests == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
