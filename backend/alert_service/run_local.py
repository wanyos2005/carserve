#!/usr/bin/env python3
"""
Local Development Runner for Alert Service
This script helps you run the alert service locally for testing
"""

import os
import sys
import subprocess
from pathlib import Path

def check_dependencies():
    """Check if required dependencies are installed"""
    required_packages = [
        'fastapi',
        'uvicorn', 
        'sqlalchemy',
        'psycopg2',
        'fastapi-mail',
        'pydantic',
        'requests'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print(f"❌ Missing packages: {', '.join(missing_packages)}")
        print("📦 Installing missing packages...")
        try:
            subprocess.run([sys.executable, "-m", "pip", "install"] + missing_packages, check=True)
            print("✅ Dependencies installed successfully")
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to install dependencies: {e}")
            return False
    else:
        print("✅ All dependencies are available")
    
    return True

def setup_environment():
    """Setup environment variables"""
    env_vars = {
        'DATABASE_URL': 'postgresql://AdminDb:Ngojakwanza@localhost:5432/car_platform',
        'REDIS_URL': 'redis://localhost:6379',
        'USER_SERVICE_URL': 'http://localhost:8001',
        'BOOKING_SERVICE_URL': 'http://localhost:8004',
        'INSURANCE_SERVICE_URL': 'http://localhost:8005',
        'SMTP_HOST': 'smtp.gmail.com',
        'SMTP_PORT': '587',
        'SMTP_USERNAME': 'tastytasty101@gmail.com',
        'SMTP_PASSWORD': 'degp zfga fqfp sifz',
        'SMTP_FROM_EMAIL': 'tastytasty101@gmail.com',
        'SMTP_FROM_NAME': 'DriveOn',
        'SMTP_TLS': 'True',
        'SMTP_SSL': 'False',
        'ALLOWED_ORIGINS': 'http://localhost:3000,http://192.168.0.107:8081,http://192.168.2.116:8000*'
    }
    
    for key, value in env_vars.items():
        os.environ[key] = value
    
    print("✅ Environment variables set")

def run_service():
    """Run the alert service locally"""
    print("🚀 Starting Alert Service locally...")
    print("📍 Service will be available at: http://localhost:8004")
    print("📚 API Documentation: http://localhost:8004/docs")
    print("🛑 Press Ctrl+C to stop")
    print("=" * 50)
    
    try:
        subprocess.run([
            sys.executable, "-m", "uvicorn", 
            "main:app", 
            "--host", "0.0.0.0", 
            "--port", "8004",
            "--reload"
        ], check=True)
    except KeyboardInterrupt:
        print("\n🛑 Alert Service stopped")
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to start service: {e}")

def main():
    """Main function"""
    print("🚀 Alert Service Local Development Setup")
    print("=" * 50)
    
    # Change to alert service directory
    os.chdir(Path(__file__).parent)
    
    # Setup steps
    if not check_dependencies():
        return False
    
    setup_environment()
    
    print("\n🎯 Prerequisites:")
    print("1. Make sure PostgreSQL is running on localhost:5432")
    print("2. Make sure Redis is running on localhost:6379 (optional)")
    print("3. Make sure other services are running (user, booking, insurance)")
    print("\n💡 If services aren't running, you can still test the alert service")
    print("   but some features (like checking insurance expiry) won't work.")
    
    input("\nPress Enter to start the service...")
    
    run_service()
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
