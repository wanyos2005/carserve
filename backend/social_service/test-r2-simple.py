#!/usr/bin/env python3
"""
Simple test script to verify Cloudflare R2 configuration
"""

import boto3
from botocore.exceptions import ClientError
import os

def test_r2_simple():
    """Simple R2 test"""
    
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
        
        # Try to list buckets first
        print("📋 Listing all buckets...")
        try:
            response = client.list_buckets()
            print("✅ Successfully listed buckets:")
            for bucket in response.get('Buckets', []):
                print(f"   - {bucket['Name']} (created: {bucket['CreationDate']})")
        except ClientError as e:
            print(f"❌ Failed to list buckets: {e}")
            return False
        
        # Try to create bucket if it doesn't exist
        print(f"📦 Creating bucket '{bucket_name}' if it doesn't exist...")
        try:
            client.create_bucket(Bucket=bucket_name)
            print("✅ Bucket created successfully")
        except ClientError as e:
            if e.response['Error']['Code'] == 'BucketAlreadyOwnedByYou':
                print("✅ Bucket already exists and is owned by you")
            elif e.response['Error']['Code'] == 'BucketAlreadyExists':
                print("✅ Bucket already exists")
            else:
                print(f"❌ Failed to create bucket: {e}")
                return False
        
        # Test upload
        print("📤 Testing file upload...")
        test_content = b"Hello from DriveOn Social Service!"
        test_key = "test/connection-test.txt"
        
        try:
            client.put_object(
                Bucket=bucket_name,
                Key=test_key,
                Body=test_content,
                ContentType='text/plain'
            )
            print("✅ Test file uploaded successfully")
        except ClientError as e:
            print(f"❌ Failed to upload test file: {e}")
            return False
        
        # Test download
        print("📥 Testing file download...")
        try:
            response = client.get_object(Bucket=bucket_name, Key=test_key)
            downloaded_content = response['Body'].read()
            
            if downloaded_content == test_content:
                print("✅ Test file downloaded successfully")
            else:
                print("❌ Downloaded content doesn't match uploaded content")
                return False
        except ClientError as e:
            print(f"❌ Failed to download test file: {e}")
            return False
        
        # Clean up test file
        print("🧹 Cleaning up test file...")
        try:
            client.delete_object(Bucket=bucket_name, Key=test_key)
            print("✅ Test file deleted successfully")
        except ClientError as e:
            print(f"⚠️  Failed to delete test file: {e}")
        
        print()
        print("🎉 Cloudflare R2 configuration is working perfectly!")
        print("✅ Your social service can now upload and manage media files")
        
        return True
        
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_r2_simple()
    exit(0 if success else 1)
