# Cloudflare R2 Setup Guide - No Credit Card Required!

## 🎉 **Why Cloudflare R2 is Perfect for Your Social Service**

### **✅ Advantages:**
- **No credit card required** for free tier
- **10 GB free storage** (vs 5 GB for AWS S3)
- **No egress fees** (unlike S3 which charges for downloads)
- **Easy verification** - just email confirmation
- **S3-compatible API** - easy to implement
- **Global CDN** - fast worldwide access

## 🚀 **Step-by-Step Setup**

### **Step 1: Create Cloudflare Account**
1. Go to [cloudflare.com](https://cloudflare.com)
2. Click "Sign Up"
3. Enter your email and password
4. **Verify your email** (no credit card needed!)
5. Complete basic account setup

### **Step 2: Enable R2 Object Storage**
1. Log into Cloudflare dashboard
2. Go to **R2 Object Storage** in the sidebar
3. Click **"Get Started"**
4. Accept terms and conditions
5. R2 is now enabled on your account!

### **Step 3: Create R2 Bucket**
1. In R2 dashboard, click **"Create bucket"**
2. Enter bucket name: `driveon-social-media`
3. Choose location: **Auto** (recommended)
4. Click **"Create bucket"**

### **Step 4: Generate API Credentials**
1. Go to **"My Profile"** (click your profile icon in top right)
2. Click **"API Tokens"** tab
3. Click **"Create Token"**
4. **Choose "Edit Cloudflare Workers" template** (this includes R2 access!)
5. Configure the template:
   - **Account**: Select your account
   - **Zone Resources**: `Include - All zones` (or leave as default)
6. Click **"Continue to summary"**
7. Click **"Create Token"**
8. **Copy the credentials** (you won't see them again!)

**Alternative Method (if you prefer custom token):**
1. Click **"Create Token"**
2. Choose **"Custom token"**
3. Configure permissions:
   - **Account**: Look for **"Workers R2 Storage"** (this is what you need!)
   - **Zone Resources**: `Include - All zones`
4. Click **"Continue to summary"**
5. Click **"Create Token"**

**Service Tokens Method (Alternative):**
1. Go to **"My Profile"** → **"API Tokens"**
2. Click **"Service Tokens"** tab
3. Click **"Create Service Token"**
4. This creates R2-specific credentials

### **Step 5: Configure Your Environment**

#### **Update your `.env` file:**
```bash
# Set Cloudflare as your media storage
MEDIA_STORAGE_TYPE=cloudflare

# Cloudflare R2 Configuration
CLOUDFLARE_ACCOUNT_ID=your-account-id-here
CLOUDFLARE_ACCESS_KEY_ID=your-access-key-here
CLOUDFLARE_SECRET_ACCESS_KEY=your-secret-key-here
CLOUDFLARE_BUCKET=driveon-social-media
CLOUDFLARE_PUBLIC_URL=https://pub-1234567890abcdef.r2.dev
```

#### **Get your Account ID:**
1. In Cloudflare dashboard, go to **"My Profile"**
2. Copy your **Account ID** from the right sidebar

#### **Get your Public URL:**
1. Go to your R2 bucket
2. Click **"Settings"** tab
3. Scroll to **"Public access"**
4. Click **"Allow Access"**
5. Copy the **R2.dev subdomain** URL

## 🔧 **Implementation in Your Social Service**

### **Add Cloudflare R2 Support to Your Code:**

Create a new file: `backend/social_service/services/media_storage.py`

```python
import boto3
from botocore.exceptions import ClientError
from core.config import (
    MEDIA_STORAGE_TYPE, CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_ACCESS_KEY_ID,
    CLOUDFLARE_SECRET_ACCESS_KEY, CLOUDFLARE_BUCKET, CLOUDFLARE_PUBLIC_URL
)

class MediaStorageService:
    def __init__(self):
        self.storage_type = MEDIA_STORAGE_TYPE
        self.setup_client()
    
    def setup_client(self):
        if self.storage_type == "cloudflare":
            # Cloudflare R2 uses S3-compatible API
            self.client = boto3.client(
                's3',
                endpoint_url=f'https://{CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com',
                aws_access_key_id=CLOUDFLARE_ACCESS_KEY_ID,
                aws_secret_access_key=CLOUDFLARE_SECRET_ACCESS_KEY,
                region_name='auto'
            )
            self.bucket = CLOUDFLARE_BUCKET
            self.public_url = CLOUDFLARE_PUBLIC_URL
    
    def upload_file(self, file, user_id, filename):
        """Upload file to Cloudflare R2"""
        try:
            key = f"users/{user_id}/{filename}"
            self.client.upload_fileobj(file, self.bucket, key)
            
            # Return public URL
            return f"{self.public_url}/{key}"
        except ClientError as e:
            raise Exception(f"Failed to upload file: {str(e)}")
    
    def delete_file(self, file_url):
        """Delete file from Cloudflare R2"""
        try:
            # Extract key from URL
            key = file_url.replace(f"{self.public_url}/", "")
            self.client.delete_object(Bucket=self.bucket, Key=key)
            return True
        except ClientError as e:
            raise Exception(f"Failed to delete file: {str(e)}")
```

### **Update your requirements.txt:**
```bash
# Add to backend/social_service/requirements.txt
boto3==1.34.0
botocore==1.34.0
```

## 📊 **Free Tier Limits & Pricing**

### **Cloudflare R2 Free Tier:**
- ✅ **10 GB storage** - Free forever
- ✅ **1 million requests/month** - Free forever
- ✅ **No egress fees** - Free forever
- ✅ **No time limit** - Free forever

### **After Free Tier:**
- **Storage**: $0.015/GB/month
- **Class A operations** (PUT, POST): $4.50/million
- **Class B operations** (GET, HEAD): $0.36/million
- **Egress**: $0 (unlike S3!)

## 🔄 **Migration from Local to Cloudflare**

### **Development Setup:**
```bash
# For development, use local storage
MEDIA_STORAGE_TYPE=local
MEDIA_UPLOAD_PATH=/app/uploads
```

### **Production Setup:**
```bash
# For production, use Cloudflare R2
MEDIA_STORAGE_TYPE=cloudflare
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_ACCESS_KEY_ID=your-access-key
CLOUDFLARE_SECRET_ACCESS_KEY=your-secret-key
CLOUDFLARE_BUCKET=driveon-social-media
CLOUDFLARE_PUBLIC_URL=https://pub-1234567890abcdef.r2.dev
```

## 🧪 **Testing Your Setup**

### **Test Upload:**
```bash
# Test via API
curl -X POST http://localhost:8008/social/posts/ \
  -H "Authorization: Bearer your-token" \
  -F "content=Test post with image" \
  -F "media=@test-image.jpg"
```

### **Expected Response:**
```json
{
  "id": "post_123",
  "content": "Test post with image",
  "media_urls": [
    "https://pub-1234567890abcdef.r2.dev/users/123/test-image.jpg"
  ],
  "user_id": 123,
  "created_at": "2024-01-15T10:30:00Z"
}
```

## 🆘 **Troubleshooting**

### **Common Issues:**

**1. "Access Denied" Error:**
```bash
# Check your API credentials
echo $CLOUDFLARE_ACCESS_KEY_ID
echo $CLOUDFLARE_SECRET_ACCESS_KEY
```

**2. "Bucket Not Found" Error:**
```bash
# Verify bucket name and account ID
echo $CLOUDFLARE_BUCKET
echo $CLOUDFLARE_ACCOUNT_ID
```

**3. "Invalid Endpoint" Error:**
```bash
# Check endpoint URL format
# Should be: https://{account-id}.r2.cloudflarestorage.com
```

### **Debug Commands:**
```bash
# Test connection
docker-compose exec social-service python -c "
from services.media_storage import MediaStorageService
storage = MediaStorageService()
print('Cloudflare R2 connection successful!')
"
```

## 🎯 **Why This is Better Than AWS S3**

| Feature | Cloudflare R2 | AWS S3 |
|---------|---------------|---------|
| **Free Storage** | 10 GB forever | 5 GB (12 months only) |
| **Credit Card** | Not required | Required |
| **Egress Fees** | $0 | $0.09/GB |
| **Verification** | Email only | Identity + Phone + Credit Card |
| **Setup Time** | 5 minutes | 30+ minutes |
| **Global CDN** | Included | Extra cost |

## 🚀 **Next Steps**

1. **Create Cloudflare account** (no credit card needed!)
2. **Set up R2 bucket** (5 minutes)
3. **Get API credentials** (2 minutes)
4. **Update your .env file** (1 minute)
5. **Test upload** (2 minutes)

**Total setup time: ~10 minutes vs 30+ minutes for AWS!**

---

**🎉 You now have a completely free, scalable media storage solution that's easier to set up than AWS and has better free tier limits!**
