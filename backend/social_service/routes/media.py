"""
Media upload routes for social service
Handles file uploads to Cloudflare R2
"""

import os
import uuid
import boto3
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from fastapi.responses import JSONResponse
from typing import List
from core.config import (
    CLOUDFLARE_ACCESS_KEY_ID, 
    CLOUDFLARE_SECRET_ACCESS_KEY, 
    CLOUDFLARE_BUCKET
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
        # Validate file type
        allowed_types = [
            'image/jpeg', 'image/png', 'image/gif', 'image/webp',
            'video/mp4', 'video/webm', 'video/quicktime'
        ]
        
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400, 
                detail=f"File type {file.content_type} not allowed. Allowed types: {allowed_types}"
            )
        
        # Check file size (10MB limit)
        max_size = 10 * 1024 * 1024  # 10MB
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
            ContentType=file.content_type
        )
        
        # Return public URL
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
                # Validate file type
                allowed_types = [
                    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
                    'video/mp4', 'video/webm', 'video/quicktime'
                ]
                
                if file.content_type not in allowed_types:
                    errors.append(f"{file.filename}: Invalid file type")
                    continue
                
                # Check file size
                content = await file.read()
                max_size = 10 * 1024 * 1024  # 10MB
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
                    ContentType=file.content_type
                )
                
                # Add to successful uploads
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
