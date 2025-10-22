#!/usr/bin/env python3
"""
Upload only smaller assets to Cloudflare R2 (faster approach)
"""

import os
import boto3
import psycopg2
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
load_dotenv()

def get_r2_client():
    """Initialize Cloudflare R2 client"""
    return boto3.client(
        's3',
        endpoint_url='https://4739f91ba1dc08d51ef1d0e905c95da7.r2.cloudflarestorage.com',
        aws_access_key_id=os.getenv('CLOUDFLARE_ACCESS_KEY_ID'),
        aws_secret_access_key=os.getenv('CLOUDFLARE_SECRET_ACCESS_KEY'),
        region_name='auto'
    )

def get_db_connection():
    """Get database connection"""
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        if database_url.startswith("postgresql+psycopg2://"):
            database_url = database_url.replace("postgresql+psycopg2://", "postgresql://", 1)
        return psycopg2.connect(database_url)
    else:
        return psycopg2.connect(
            host=os.getenv('DB_HOST', 'postgres'),
            port=os.getenv('DB_PORT', '5432'),
            database=os.getenv('DB_NAME', 'car_platform'),
            user=os.getenv('DB_USER', 'AdminDb'),
            password=os.getenv('DB_PASSWORD', 'Ngojakwanza')
        )

def upload_file_to_r2(s3_client, local_path, r2_key):
    """Upload a file to Cloudflare R2"""
    try:
        bucket_name = os.getenv('CLOUDFLARE_BUCKET', 'driveon-social-media')
        
        # Get file size
        file_size = os.path.getsize(local_path)
        file_size_mb = file_size / (1024 * 1024)
        
        print(f"   📊 Size: {file_size_mb:.1f}MB")
        
        # Determine content type
        content_type = 'video/mp4' if local_path.endswith('.mp4') else 'application/octet-stream'
        
        s3_client.upload_file(
            local_path,
            bucket_name,
            r2_key,
            ExtraArgs={'ContentType': content_type}
        )
        
        # Return the public URL
        public_url = f"https://pub-4739f91ba1dc08d51ef1d0e905c95da7.r2.dev/{r2_key}"
        return public_url
        
    except Exception as e:
        print(f"❌ Error uploading {local_path}: {str(e)}")
        return None

def update_database_urls(conn, old_url, new_url):
    """Update database records with new R2 URLs"""
    cursor = conn.cursor()
    
    try:
        # Update posts table
        cursor.execute("""
            UPDATE social.posts 
            SET media_urls = jsonb_set(
                media_urls, 
                '{0}', 
                to_jsonb(%s)
            )
            WHERE media_urls::text LIKE %s
        """, (new_url, f'%{old_url}%'))
        
        # Update stories table
        cursor.execute("""
            UPDATE social.stories 
            SET media_url = %s
            WHERE media_url = %s
        """, (new_url, old_url))
        
        conn.commit()
        print(f"✅ Updated database: {old_url} → {new_url}")
        
    except Exception as e:
        print(f"❌ Error updating database: {str(e)}")
        conn.rollback()
    finally:
        cursor.close()

def main():
    """Main function to upload only smaller assets"""
    print("🚀 Starting FAST Asset Upload to Cloudflare R2...")
    print("=" * 60)
    print("📋 Strategy: Upload only smaller files (< 50MB) for speed")
    print("=" * 60)
    
    try:
        # Initialize clients
        s3_client = get_r2_client()
        conn = get_db_connection()
        
        # Get all local asset files
        assets_dir = Path("/app/seedAssets")
        if not assets_dir.exists():
            print("❌ seedAssets directory not found!")
            return
        
        # Filter for smaller files only (< 50MB)
        asset_files = []
        for asset_file in assets_dir.glob("*"):
            if asset_file.is_file():
                file_size_mb = asset_file.stat().st_size / (1024 * 1024)
                if file_size_mb < 50:  # Only files smaller than 50MB
                    asset_files.append((asset_file, file_size_mb))
        
        # Sort by size (smallest first)
        asset_files.sort(key=lambda x: x[1])
        
        print(f"📁 Found {len(asset_files)} small assets to upload (< 50MB)")
        
        uploaded_count = 0
        
        for asset_file, file_size_mb in asset_files:
            print(f"\n📤 Uploading: {asset_file.name} ({file_size_mb:.1f}MB)")
            
            # Create R2 key
            r2_key = f"seed-assets/{asset_file.name}"
            
            # Upload to R2
            public_url = upload_file_to_r2(s3_client, str(asset_file), r2_key)
            
            if public_url:
                # Update database with new URL
                old_url = f"/app/seedAssets/{asset_file.name}"
                update_database_urls(conn, old_url, public_url)
                uploaded_count += 1
                print(f"✅ Uploaded: {asset_file.name}")
            else:
                print(f"❌ Failed to upload: {asset_file.name}")
        
        print(f"\n" + "=" * 60)
        print(f"🎉 Fast Upload Complete!")
        print(f"📊 Summary:")
        print(f"   - Small assets uploaded: {uploaded_count}")
        print(f"   - Large files skipped for speed")
        print(f"   - Database updated with R2 URLs")
        print(f"   - Your social hub now uses Cloudflare R2! 🚀")
        
    except Exception as e:
        print(f"❌ Error during upload: {str(e)}")
        raise
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    main()
