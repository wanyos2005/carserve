#!/usr/bin/env python3
"""
Test script to check database state and user data
"""
import sys
import os
import psycopg2
from datetime import datetime

def test_database_connection():
    """Test database connection and check user data"""
    
    print("🧪 Testing Database Connection and User Data...")
    
    # Database connection parameters
    DB_CONFIG = {
        'host': 'localhost',
        'port': 5432,
        'database': 'car_platform',
        'user': 'postgres',
        'password': 'password'
    }
    
    try:
        # Connect to database
        print(f"📊 Connecting to database: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        print("✅ Database connection successful!")
        
        # Test 1: Check if user exists
        print("\n1️⃣ Checking user data...")
        cursor.execute("SELECT id, email, phone, verified, is_guest, fcm_token FROM tbl_auth WHERE id = 1")
        user_data = cursor.fetchone()
        
        if user_data:
            print(f"✅ User 1 found:")
            print(f"  - ID: {user_data[0]}")
            print(f"  - Email: {user_data[1]}")
            print(f"  - Phone: {user_data[2]}")
            print(f"  - Verified: {user_data[3]}")
            print(f"  - Is Guest: {user_data[4]}")
            print(f"  - FCM Token: {user_data[5] if user_data[5] else 'None'}")
        else:
            print("❌ User 1 not found in database")
            return False
        
        # Test 2: Check service logs
        print("\n2️⃣ Checking service logs...")
        cursor.execute("""
            SELECT id, user_id, provider_name, service_name, performed_at 
            FROM service_logs 
            WHERE user_id = 1 
            ORDER BY performed_at DESC 
            LIMIT 5
        """)
        service_logs = cursor.fetchall()
        
        if service_logs:
            print(f"✅ Found {len(service_logs)} service logs for user 1:")
            for log in service_logs:
                print(f"  - Log ID: {log[0]}, Provider: {log[2]}, Service: {log[3]}, Date: {log[4]}")
        else:
            print("ℹ️ No service logs found for user 1")
        
        # Test 3: Check alerts
        print("\n3️⃣ Checking existing alerts...")
        cursor.execute("""
            SELECT id, user_id, type, title, status, created_at 
            FROM alerts 
            WHERE user_id = 1 
            ORDER BY created_at DESC 
            LIMIT 5
        """)
        alerts = cursor.fetchall()
        
        if alerts:
            print(f"✅ Found {len(alerts)} alerts for user 1:")
            for alert in alerts:
                print(f"  - Alert ID: {alert[0]}, Type: {alert[2]}, Title: {alert[3]}, Status: {alert[4]}")
        else:
            print("ℹ️ No alerts found for user 1")
        
        # Test 4: Check alert rules
        print("\n4️⃣ Checking alert rules...")
        cursor.execute("SELECT id, name, is_active FROM alert_rules WHERE is_active = true")
        alert_rules = cursor.fetchall()
        
        if alert_rules:
            print(f"✅ Found {len(alert_rules)} active alert rules:")
            for rule in alert_rules:
                print(f"  - Rule ID: {rule[0]}, Name: {rule[1]}, Active: {rule[2]}")
        else:
            print("ℹ️ No active alert rules found")
        
        # Test 5: Check recent app download prompts
        print("\n5️⃣ Checking recent app download prompts...")
        cursor.execute("""
            SELECT id, user_id, type, created_at 
            FROM alerts 
            WHERE user_id = 1 AND type = 'APP_DOWNLOAD_PROMPT'
            ORDER BY created_at DESC 
            LIMIT 3
        """)
        app_prompts = cursor.fetchall()
        
        if app_prompts:
            print(f"✅ Found {len(app_prompts)} recent app download prompts:")
            for prompt in app_prompts:
                print(f"  - Prompt ID: {prompt[0]}, User: {prompt[1]}, Date: {prompt[3]}")
        else:
            print("ℹ️ No recent app download prompts found")
        
        return True
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False
    finally:
        if 'conn' in locals():
            conn.close()

def test_user_scenarios():
    """Test different user scenarios"""
    print("\n🧪 Testing Different User Scenarios...")
    
    DB_CONFIG = {
        'host': 'localhost',
        'port': 5432,
        'database': 'car_platform',
        'user': 'postgres',
        'password': 'password'
    }
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Test different user types
        test_cases = [
            {"description": "Guest user (no FCM token)", "query": "SELECT id FROM tbl_auth WHERE is_guest = true AND fcm_token IS NULL LIMIT 1"},
            {"description": "Verified user with FCM token", "query": "SELECT id FROM tbl_auth WHERE verified = true AND fcm_token IS NOT NULL LIMIT 1"},
            {"description": "User with recent app prompt", "query": "SELECT DISTINCT user_id FROM alerts WHERE type = 'APP_DOWNLOAD_PROMPT' AND created_at > NOW() - INTERVAL '7 days' LIMIT 1"},
            {"description": "User without recent prompts", "query": "SELECT id FROM tbl_auth WHERE id NOT IN (SELECT DISTINCT user_id FROM alerts WHERE type = 'APP_DOWNLOAD_PROMPT' AND created_at > NOW() - INTERVAL '7 days') LIMIT 1"}
        ]
        
        for i, test_case in enumerate(test_cases, 1):
            print(f"\n{i}️⃣ {test_case['description']}...")
            cursor.execute(test_case['query'])
            result = cursor.fetchone()
            
            if result:
                user_id = result[0]
                print(f"  ✅ Found user ID: {user_id}")
                
                # Get user details
                cursor.execute("SELECT email, phone, verified, is_guest, fcm_token FROM tbl_auth WHERE id = %s", (user_id,))
                user_details = cursor.fetchone()
                if user_details:
                    print(f"  📊 Email: {user_details[0]}, Phone: {user_details[1]}")
                    print(f"  📊 Verified: {user_details[2]}, Guest: {user_details[3]}")
                    print(f"  📊 FCM Token: {'Yes' if user_details[4] else 'No'}")
            else:
                print(f"  ℹ️ No users found for this scenario")
        
        return True
        
    except Exception as e:
        print(f"❌ Error in user scenario test: {e}")
        return False
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    print("🚀 Starting Database and User Data Tests")
    print("=" * 50)
    
    # Test 1: Database connection and data
    print("\n🧪 Test 1: Database Connection and User Data")
    db_success = test_database_connection()
    
    # Test 2: User scenarios
    print("\n🧪 Test 2: Different User Scenarios")
    scenario_success = test_user_scenarios()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print(f"  - Database Connection: {'✅ PASS' if db_success else '❌ FAIL'}")
    print(f"  - User Scenarios: {'✅ PASS' if scenario_success else '❌ FAIL'}")
    
    if db_success and scenario_success:
        print("\n🎉 All database tests passed!")
        print("\n💡 Next steps:")
        print("  1. Start alert service: cd backend/alert_service && python -m uvicorn main:app --host 0.0.0.0 --port 8000")
        print("  2. Run API test: python test_app_download_prompt.py")
        print("  3. Run detection test: python test_app_detection_service.py")
    else:
        print("\n❌ Some database tests failed. Check the output above for details.")
        sys.exit(1)

