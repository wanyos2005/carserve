#!/usr/bin/env python3
"""
Upload local seedAssets to Cloudflare R2 and update database URLs
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
    """Upload a file to Cloudflare R2 with progress tracking"""
    try:
        bucket_name = os.getenv('CLOUDFLARE_BUCKET', 'driveon-social-media')
        
        # Get file size for progress tracking
        file_size = os.path.getsize(local_path)
        file_size_mb = file_size / (1024 * 1024)
        
        print(f"   📊 File size: {file_size_mb:.1f}MB")
        
        # Determine content type based on file extension
        content_type = 'application/octet-stream'
        if local_path.endswith('.mp4'):
            content_type = 'video/mp4'
        elif local_path.endswith(('.jpg', '.jpeg')):
            content_type = 'image/jpeg'
        elif local_path.endswith('.png'):
            content_type = 'image/png'
        elif local_path.endswith('.gif'):
            content_type = 'image/gif'
        elif local_path.endswith('.webp'):
            content_type = 'image/webp'
        
        # Use multipart upload for large files
        if file_size > 50 * 1024 * 1024:  # 50MB threshold
            print(f"   🔄 Using multipart upload for large file...")
            s3_client.upload_file(
                local_path,
                bucket_name,
                r2_key,
                ExtraArgs={
                    'ContentType': content_type,
                    'ServerSideEncryption': 'AES256'
                },
                Config=boto3.s3.transfer.TransferConfig(
                    multipart_threshold=50 * 1024 * 1024,  # 50MB
                    max_concurrency=4,
                    multipart_chunksize=10 * 1024 * 1024,  # 10MB chunks
                    use_threads=True
                )
            )
        else:
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
    """Main function to upload assets to R2"""
    print("🚀 Starting Asset Upload to Cloudflare R2...")
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
        
        asset_files = list(assets_dir.glob("*"))
        print(f"📁 Found {len(asset_files)} assets to upload")
        
        uploaded_count = 0
        
        for asset_file in asset_files:
            if asset_file.is_file():
                print(f"\n📤 Uploading: {asset_file.name}")
                
                # Create R2 key (path in bucket)
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
        print(f"🎉 Upload Complete!")
        print(f"📊 Summary:")
        print(f"   - Assets uploaded: {uploaded_count}")
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
