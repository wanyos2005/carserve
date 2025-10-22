#!/usr/bin/env python3
"""
Test script to verify Cloudflare R2 configuration
Run this to test your R2 setup before deploying
"""

import boto3
from botocore.exceptions import ClientError
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_cloudflare_r2():
    """Test Cloudflare R2 connection and permissions"""
    
    # Get configuration from environment
    account_id = os.getenv("CLOUDFLARE_ACCOUNT_ID")
    access_key = os.getenv("CLOUDFLARE_ACCESS_KEY_ID")
    secret_key = os.getenv("CLOUDFLARE_SECRET_ACCESS_KEY")
    bucket_name = os.getenv("CLOUDFLARE_BUCKET")
    
    print("🔧 Testing Cloudflare R2 Configuration...")
    print(f"Account ID: {account_id}")
    print(f"Access Key: {access_key[:10]}..." if access_key else "Not set")
    print(f"Bucket: {bucket_name}")
    print()
    
    if not all([account_id, access_key, secret_key, bucket_name]):
        print("❌ Missing required environment variables!")
        print("Please check your .env file has all Cloudflare R2 credentials")
        return False
    
    try:
        # Create S3 client for Cloudflare R2
        client = boto3.client(
            's3',
            endpoint_url=f'https://{account_id}.r2.cloudflarestorage.com',
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name='auto'
        )
        
        print("✅ S3 client created successfully")
        
        # Test bucket access or create if it doesn't exist
        print("🔍 Testing bucket access...")
        try:
            response = client.head_bucket(Bucket=bucket_name)
            print("✅ Bucket access successful")
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                print("📦 Bucket doesn't exist, creating it...")
                try:
                    client.create_bucket(Bucket=bucket_name)
                    print("✅ Bucket created successfully")
                except ClientError as create_error:
                    print(f"❌ Failed to create bucket: {create_error}")
                    return False
            else:
                print(f"❌ Bucket access error: {e}")
                return False
        
        # List objects in bucket
        print("📋 Listing bucket contents...")
        response = client.list_objects_v2(Bucket=bucket_name, MaxKeys=5)
        
        if 'Contents' in response:
            print(f"📁 Found {len(response['Contents'])} objects in bucket:")
            for obj in response['Contents']:
                print(f"   - {obj['Key']} ({obj['Size']} bytes)")
        else:
            print("📁 Bucket is empty (this is normal for new buckets)")
        
        # Test upload (small test file)
        print("📤 Testing file upload...")
        test_content = b"Hello from DriveOn Social Service!"
        test_key = "test/connection-test.txt"
        
        client.put_object(
            Bucket=bucket_name,
            Key=test_key,
            Body=test_content,
            ContentType='text/plain'
        )
        print("✅ Test file uploaded successfully")
        
        # Test download
        print("📥 Testing file download...")
        response = client.get_object(Bucket=bucket_name, Key=test_key)
        downloaded_content = response['Body'].read()
        
        if downloaded_content == test_content:
            print("✅ Test file downloaded successfully")
        else:
            print("❌ Downloaded content doesn't match uploaded content")
            return False
        
        # Clean up test file
        print("🧹 Cleaning up test file...")
        client.delete_object(Bucket=bucket_name, Key=test_key)
        print("✅ Test file deleted successfully")
        
        print()
        print("🎉 Cloudflare R2 configuration is working perfectly!")
        print("✅ Your social service can now upload and manage media files")
        
        return True
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        
        print(f"❌ AWS/Cloudflare Error: {error_code}")
        print(f"   Message: {error_message}")
        
        if error_code == 'NoSuchBucket':
            print("💡 Solution: Create the bucket 'driveon-social-media' in your Cloudflare R2 dashboard")
        elif error_code == 'AccessDenied':
            print("💡 Solution: Check your API token has R2:Edit permissions")
        elif error_code == 'InvalidAccessKeyId':
            print("💡 Solution: Check your CLOUDFLARE_ACCESS_KEY_ID is correct")
        elif error_code == 'SignatureDoesNotMatch':
            print("💡 Solution: Check your CLOUDFLARE_SECRET_ACCESS_KEY is correct")
        
        return False
        
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_cloudflare_r2()
    exit(0 if success else 1)