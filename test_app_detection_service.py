#!/usr/bin/env python3
"""
Test script for AppDetectionService functionality
"""
import sys
import os
import asyncio
from datetime import datetime

# Add the alert service to Python path
sys.path.append('backend/alert_service')

def test_app_detection_service():
    """Test the AppDetectionService directly"""
    
    print("🧪 Testing AppDetectionService...")
    
    try:
        # Import required modules
        from sqlalchemy import create_engine
        from sqlalchemy.orm import sessionmaker
        from services.app_detection_service import AppDetectionService
        
        # Database connection (adjust as needed)
        DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5432/car_platform")
        
        print(f"📊 Connecting to database: {DATABASE_URL}")
        
        # Create database session
        engine = create_engine(DATABASE_URL)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        try:
            # Create AppDetectionService
            detection_service = AppDetectionService(db)
            
            # Test user ID 1
            user_id = 1
            print(f"\n1️⃣ Testing app detection for user {user_id}...")
            
            # Test comprehensive detection
            async def run_detection_tests():
                print("🔍 Running comprehensive app detection...")
                
                # Test 1: Check if user has app
                has_app = await detection_service.check_customer_has_app(user_id)
                print(f"📊 User {user_id} has app: {has_app}")
                
                # Test 2: Check if should send prompt
                should_send = await detection_service.should_send_app_prompt(user_id)
                print(f"📊 Should send prompt to user {user_id}: {should_send}")
                
                # Test 3: Get detailed detection results
                print("\n🔍 Getting detailed detection results...")
                detection_results = await detection_service._collect_all_detection_results(user_id)
                print(f"📊 Detection Results: {detection_results}")
                
                # Test 4: Evaluate app installation
                app_installed = detection_service._evaluate_app_installation(detection_results)
                print(f"📊 App installation evaluation: {app_installed}")
                
                return {
                    'has_app': has_app,
                    'should_send_prompt': should_send,
                    'detection_results': detection_results,
                    'app_installed': app_installed
                }
            
            # Run async tests
            results = asyncio.run(run_detection_tests())
            
            print("\n📊 Test Results Summary:")
            print(f"  - User has app: {results['has_app']}")
            print(f"  - Should send prompt: {results['should_send_prompt']}")
            print(f"  - App installed (evaluation): {results['app_installed']}")
            print(f"  - Detection results: {results['detection_results']}")
            
            # Test different user scenarios
            print("\n2️⃣ Testing different user scenarios...")
            
            # Test with a different user ID (if exists)
            test_user_ids = [1, 2, 3, 999]  # Test different user IDs
            
            for test_user_id in test_user_ids:
                try:
                    print(f"\n🔍 Testing user {test_user_id}...")
                    has_app = await detection_service.check_customer_has_app(test_user_id)
                    should_send = await detection_service.should_send_app_prompt(test_user_id)
                    print(f"  - Has app: {has_app}")
                    print(f"  - Should send prompt: {should_send}")
                except Exception as e:
                    print(f"  - Error testing user {test_user_id}: {e}")
            
            return True
            
        except Exception as e:
            print(f"❌ Error in detection service test: {e}")
            return False
        finally:
            db.close()
            
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Make sure you're running from the project root and alert service is properly set up")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def test_alert_service_integration():
    """Test AlertService integration"""
    print("\n🧪 Testing AlertService integration...")
    
    try:
        from sqlalchemy import create_engine
        from sqlalchemy.orm import sessionmaker
        from services.alert_service import AlertService
        from schemas.alert import AlertCreate
        from models.alert import AlertType
        
        # Database connection
        DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5432/car_platform")
        engine = create_engine(DATABASE_URL)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        try:
            alert_service = AlertService(db)
            
            # Test trigger app download prompt
            print("🔍 Testing trigger_app_download_prompt...")
            
            async def test_trigger():
                result = await alert_service.trigger_app_download_prompt(
                    user_id=1,
                    vehicle_info="Toyota Camry 2020",
                    service_provider_name="Test Garage",
                    service_type="Oil Change",
                    discount_code="FIRST10"
                )
                
                if result:
                    print(f"✅ Alert created successfully!")
                    print(f"📊 Alert ID: {result.id}")
                    print(f"📊 Alert Type: {result.type}")
                    print(f"📊 Alert Title: {result.title}")
                    print(f"📊 Alert Status: {result.status}")
                    return result
                else:
                    print("ℹ️ No alert created (user might already have app or prompt not needed)")
                    return None
            
            alert = asyncio.run(test_trigger())
            return alert is not None
            
        except Exception as e:
            print(f"❌ Error in alert service test: {e}")
            return False
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Error in alert service integration test: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Starting App Detection Service Tests")
    print("=" * 50)
    
    # Test 1: AppDetectionService
    print("\n🧪 Test 1: AppDetectionService")
    detection_success = test_app_detection_service()
    
    # Test 2: AlertService Integration
    print("\n🧪 Test 2: AlertService Integration")
    alert_success = test_alert_service_integration()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print(f"  - AppDetectionService: {'✅ PASS' if detection_success else '❌ FAIL'}")
    print(f"  - AlertService Integration: {'✅ PASS' if alert_success else '❌ FAIL'}")
    
    if detection_success and alert_success:
        print("\n🎉 All tests passed!")
    else:
        print("\n❌ Some tests failed. Check the output above for details.")
        sys.exit(1)

