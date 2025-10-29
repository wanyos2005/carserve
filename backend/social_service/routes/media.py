"""
Media upload routes for social service
Handles file uploads to Cloudflare R2
"""

import os
import uuid
import mimetypes
import boto3
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from fastapi.responses import JSONResponse
from typing import List
from core.config import (
    CLOUDFLARE_ACCESS_KEY_ID, 
    CLOUDFLARE_SECRET_ACCESS_KEY, 
    CLOUDFLARE_BUCKET,
    CLOUDFLARE_PUBLIC_URL
)

router = APIRouter(prefix="/media", tags=["media"])

def get_r2_client():
    """Initialize Cloudflare R2 client"""
    return boto3.client(
        's3',
        endpoint_url='https://4739f91ba1dc08d51ef1d0e905c95da7.r2.cloudflarestorage.com',
        aws_access_key_id=CLOUDFLARE_ACCESS_KEY_ID,
        aws_secret_access_key=CLOUDFLARE_SECRET_ACCESS_KEY,
        region_name='auto'
    )

@router.post("/upload")
async def upload_media(
    file: UploadFile = File(...),
    folder: str = "posts"
):
    """
    Upload a single media file to Cloudflare R2
    """
    try:
        # Validate file type with safe fallbacks for missing/unknown content-type
        allowed_types = [
            'image/jpeg', 'image/png', 'image/gif', 'image/webp',
            'video/mp4', 'video/webm', 'video/quicktime'
        ]

        effective_content_type = file.content_type or ''
        if (not effective_content_type) or (effective_content_type == 'application/octet-stream'):
            guessed_type, _ = mimetypes.guess_type(file.filename or '')
            if guessed_type:
                effective_content_type = guessed_type

        if effective_content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Unsupported file type '{file.content_type}'. "
                    f"Guessed '{effective_content_type}' from filename '{file.filename}'. "
                    f"Allowed types: {allowed_types}"
                )
            )
        
        # Check file size using env override; default 10MB images / 100MB videos
        is_video = effective_content_type.startswith('video/')
        default_video = 100 * 1024 * 1024  # 100MB
        default_image = 10 * 1024 * 1024   # 10MB
        env_max = os.getenv('MAX_FILE_SIZE')
        if env_max and env_max.isdigit():
            max_size = int(env_max)
        else:
            max_size = default_video if is_video else default_image
        content = await file.read()
        if len(content) > max_size:
            raise HTTPException(
                status_code=400,
                detail=f"File too large. Maximum size is {max_size / (1024 * 1024):.1f}MB"
            )
        
        # Generate unique filename
        file_extension = os.path.splitext(file.filename)[1] if file.filename else '.bin'
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        r2_key = f"{folder}/{unique_filename}"
        
        # Upload to R2
        s3_client = get_r2_client()
        bucket_name = CLOUDFLARE_BUCKET
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=r2_key,
            Body=content,
            ContentType=effective_content_type or 'application/octet-stream'
        )
        
        # Return public URL (configurable)
        base_public = (CLOUDFLARE_PUBLIC_URL or '').rstrip('/')
        if base_public:
            public_url = f"{base_public}/{r2_key}"
        else:
            # Fallback to known demo domain; recommend setting CLOUDFLARE_PUBLIC_URL
            public_url = f"https://pub-4739f91ba1dc08d51ef1d0e905c95da7.r2.dev/{r2_key}"
        
        return JSONResponse(content={
            "success": True,
            "url": public_url,
            "filename": unique_filename,
            "content_type": file.content_type,
            "size": len(content)
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.post("/upload-multiple")
async def upload_multiple_media(
    files: List[UploadFile] = File(...),
    folder: str = "posts"
):
    """
    Upload multiple media files to Cloudflare R2
    """
    try:
        if len(files) > 10:  # Limit to 10 files
            raise HTTPException(
                status_code=400,
                detail="Maximum 10 files allowed per request"
            )
        
        uploaded_files = []
        errors = []
        
        for file in files:
            try:
                # Validate file type with safe fallbacks
                allowed_types = [
                    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
                    'video/mp4', 'video/webm', 'video/quicktime'
                ]

                effective_content_type = file.content_type or ''
                if (not effective_content_type) or (effective_content_type == 'application/octet-stream'):
                    guessed_type, _ = mimetypes.guess_type(file.filename or '')
                    if guessed_type:
                        effective_content_type = guessed_type

                if effective_content_type not in allowed_types:
                    errors.append(
                        f"{file.filename}: Unsupported type '{file.content_type}' (guessed '{effective_content_type}')"
                    )
                    continue
                
                # Check file size using env override; default 10MB images / 100MB videos
                content = await file.read()
                is_video = effective_content_type.startswith('video/')
                default_video = 100 * 1024 * 1024  # 100MB
                default_image = 10 * 1024 * 1024   # 10MB
                env_max = os.getenv('MAX_FILE_SIZE')
                if env_max and env_max.isdigit():
                    max_size = int(env_max)
                else:
                    max_size = default_video if is_video else default_image
                if len(content) > max_size:
                    errors.append(f"{file.filename}: File too large")
                    continue
                
                # Generate unique filename
                file_extension = os.path.splitext(file.filename)[1] if file.filename else '.bin'
                unique_filename = f"{uuid.uuid4()}{file_extension}"
                r2_key = f"{folder}/{unique_filename}"
                
                # Upload to R2
                s3_client = get_r2_client()
                bucket_name = CLOUDFLARE_BUCKET
                
                s3_client.put_object(
                    Bucket=bucket_name,
                    Key=r2_key,
                    Body=content,
                    ContentType=effective_content_type or 'application/octet-stream'
                )
                
                # Add to successful uploads (configurable)
                base_public = (CLOUDFLARE_PUBLIC_URL or '').rstrip('/')
                if base_public:
                    public_url = f"{base_public}/{r2_key}"
                else:
                    public_url = f"https://pub-4739f91ba1dc08d51ef1d0e905c95da7.r2.dev/{r2_key}"
                uploaded_files.append({
                    "url": public_url,
                    "filename": unique_filename,
                    "content_type": file.content_type,
                    "size": len(content)
                })
                
            except Exception as e:
                errors.append(f"{file.filename}: {str(e)}")
        
        return JSONResponse(content={
            "success": len(uploaded_files) > 0,
            "uploaded_files": uploaded_files,
            "errors": errors,
            "total_uploaded": len(uploaded_files)
        })
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.delete("/delete/{file_path:path}")
async def delete_media(file_path: str):
    """
    Delete a media file from Cloudflare R2
    """
    try:
        s3_client = get_r2_client()
        bucket_name = CLOUDFLARE_BUCKET
        
        s3_client.delete_object(Bucket=bucket_name, Key=file_path)
        
        return JSONResponse(content={
            "success": True,
            "message": f"File {file_path} deleted successfully"
        })
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Delete failed: {str(e)}")

@router.get("/list")
async def list_media(folder: str = "posts", limit: int = 50):
    """
    List media files in a folder
    """
    try:
        s3_client = get_r2_client()
        bucket_name = CLOUDFLARE_BUCKET
        
        response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Prefix=f"{folder}/",
            MaxKeys=limit
        )
        
        files = []
        if 'Contents' in response:
            for obj in response['Contents']:
                files.append({
                    "key": obj['Key'],
                    "url": f"https://pub-4739f91ba1dc08d51ef1d0e905c95da7.r2.dev/{obj['Key']}",
                    "size": obj['Size'],
                    "last_modified": obj['LastModified'].isoformat()
                })
        
        return JSONResponse(content={
            "success": True,
            "files": files,
            "count": len(files)
        })
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"List failed: {str(e)}")
