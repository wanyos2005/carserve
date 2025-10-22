#!/usr/bin/env python3
"""
Test Cloudflare R2 connection and upload a small test file
"""

import os
import boto3
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_r2_connection():
    """Test basic R2 connection"""
    print("🔍 Testing Cloudflare R2 Connection...")
    print("=" * 50)
    
    try:
        # Initialize R2 client
        s3_client = boto3.client(
            's3',
            endpoint_url='https://4739f91ba1dc08d51ef1d0e905c95da7.r2.cloudflarestorage.com',
            aws_access_key_id=os.getenv('CLOUDFLARE_ACCESS_KEY_ID'),
            aws_secret_access_key=os.getenv('CLOUDFLARE_SECRET_ACCESS_KEY'),
            region_name='auto'
        )
        
        bucket_name = os.getenv('CLOUDFLARE_BUCKET', 'driveon-social-media')
        
        print(f"📦 Bucket: {bucket_name}")
        print(f"🔑 Access Key: {os.getenv('CLOUDFLARE_ACCESS_KEY_ID')[:10]}...")
        print(f"🌐 Endpoint: https://4739f91ba1dc08d51ef1d0e905c95da7.r2.cloudflarestorage.com")
        
        # Test 1: List buckets
        print("\n📋 Test 1: Listing buckets...")
        try:
            response = s3_client.list_buckets()
            print(f"✅ Successfully connected! Found {len(response['Buckets'])} buckets")
            for bucket in response['Buckets']:
                print(f"   - {bucket['Name']} (created: {bucket['CreationDate']})")
        except Exception as e:
            print(f"❌ Failed to list buckets: {str(e)}")
            return False
        
        # Test 2: Check if our bucket exists
        print(f"\n📋 Test 2: Checking bucket '{bucket_name}'...")
        try:
            s3_client.head_bucket(Bucket=bucket_name)
            print(f"✅ Bucket '{bucket_name}' exists and is accessible")
        except Exception as e:
            print(f"❌ Bucket '{bucket_name}' not accessible: {str(e)}")
            return False
        
        # Test 3: Upload a small test file
        print(f"\n📋 Test 3: Uploading test file...")
        try:
            test_content = "Hello from DriveOn Social Hub! 🚗✨"
            test_key = "test/connection-test.txt"
            
            s3_client.put_object(
                Bucket=bucket_name,
                Key=test_key,
                Body=test_content.encode('utf-8'),
                ContentType='text/plain'
            )
            print(f"✅ Successfully uploaded test file: {test_key}")
            
            # Get the public URL
            public_url = f"https://pub-4739f91ba1dc08d51ef1d0e905c95da7.r2.dev/{test_key}"
            print(f"🌐 Public URL: {public_url}")
            
        except Exception as e:
            print(f"❌ Failed to upload test file: {str(e)}")
            return False
        
        # Test 4: Download the test file
        print(f"\n📋 Test 4: Downloading test file...")
        try:
            response = s3_client.get_object(Bucket=bucket_name, Key=test_key)
            content = response['Body'].read().decode('utf-8')
            print(f"✅ Successfully downloaded: {content}")
        except Exception as e:
            print(f"❌ Failed to download test file: {str(e)}")
            return False
        
        # Test 5: Delete the test file
        print(f"\n📋 Test 5: Cleaning up test file...")
        try:
            s3_client.delete_object(Bucket=bucket_name, Key=test_key)
            print(f"✅ Successfully deleted test file")
        except Exception as e:
            print(f"⚠️  Failed to delete test file: {str(e)}")
        
        print(f"\n🎉 All R2 tests passed! Cloudflare R2 is ready for production! 🚀")
        return True
        
    except Exception as e:
        print(f"❌ R2 connection failed: {str(e)}")
        return False

if __name__ == "__main__":
    test_r2_connection()
