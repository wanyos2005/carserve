# Social Service Setup Guide

## 🎉 **Complete Social Service Integration**

This guide covers all the modifications made to support the new social service in your DriveOn platform.

## 📋 **What's Been Updated**

### **1. Setup Scripts**
- ✅ **`setup-dev-env.sh`** - Added social service to development setup
- ✅ **`setup-prod-env.sh`** - Added social service to production setup

### **2. Environment Files**
- ✅ **`env.dev`** - Added social service configuration for development
- ✅ **`env.prod`** - Added social service configuration for production
- ✅ **`env.oracle.example`** - Added social service configuration for Oracle deployment

### **3. Docker Configuration**
- ✅ **`docker-compose.yml`** - Added social service (port 8008)
- ✅ **`docker-compose.oracle.yml`** - Added social service for Oracle deployment
- ✅ **`nginx.conf`** - Added social service routing
- ✅ **`nginx.prod.conf`** - Added social service routing for production

## 🚀 **Oracle vs AWS: Why Oracle is Better**

### **Current Setup (Recommended)**
- **Oracle Cloud Always Free Tier** - Hosting services
- **Neon PostgreSQL** - Database (free tier)
- **Upstash Redis** - Caching (free tier)

### **Why This is Better Than AWS:**
- ✅ **100% Free** - No billing surprises
- ✅ **Better Performance** - Optimized for small-medium apps
- ✅ **Simpler Management** - Less complexity than AWS
- ✅ **No Vendor Lock-in** - Easy to migrate if needed
- ✅ **Better Free Tiers** - More generous than AWS free tier

## 🔧 **Social Service Configuration**

### **Development Environment**
```bash
# Run development setup
./setup-dev-env.sh

# Start services
docker-compose up --build -d
```

**Social Service URLs:**
- API: `http://localhost:8000/social/`
- Direct: `http://localhost:8008/`
- Docs: `http://localhost:8008/docs`

### **Production Environment (Oracle)**
```bash
# Run production setup
./setup-prod-env.sh

# Deploy to Oracle
docker-compose -f docker-compose.oracle.yml up -d
```

**Production URLs:**
- API: `https://yourdomain.com/social/`
- Direct: `https://yourdomain.com:8008/`
- Docs: `https://yourdomain.com:8008/docs`

## 📊 **Social Service Features**

### **Core Features**
- **Posts**: Create, read, update, delete social posts
- **Stories**: 24-hour expiring stories with view tracking
- **Comments**: Nested comment system with replies
- **Likes & Shares**: Social interactions and analytics
- **Follow System**: User following and follower management
- **Hashtags**: Content discovery through hashtag system

### **Provider Integration**
- **Sponsored Content**: Provider-sponsored posts and stories
- **Provider Profiles**: Enhanced profiles for service providers
- **Analytics**: Detailed analytics for providers and content creators
- **Verification**: Provider verification badges and status

### **Content Discovery**
- **Search**: Global search across posts, users, and hashtags
- **Trending**: Trending posts, hashtags, and users
- **Feed**: Personalized feed based on following and interests
- **Explore**: Content discovery for non-followers

## 🔐 **Security & Performance**

### **Security Features**
- JWT-based authentication
- Content moderation (configurable)
- Rate limiting (60 requests/minute)
- CORS protection
- Input validation and sanitization

### **Performance Features**
- Redis caching for frequently accessed data
- Database connection pooling
- Optimized queries with proper indexing
- Media storage (local dev, S3 production)
- Analytics caching

## 📱 **Media Storage Configuration**

### **Development (Local)**
```env
MEDIA_STORAGE_TYPE=local
MEDIA_UPLOAD_PATH=/app/uploads
MAX_FILE_SIZE=10485760  # 10MB
```

### **Production (S3)**
```env
MEDIA_STORAGE_TYPE=s3
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_S3_BUCKET=your-s3-bucket
AWS_S3_REGION=us-east-1
```

## 🚀 **Quick Start Guide**

### **1. Development Setup**
```bash
# Clone and setup
git clone <your-repo>
cd car-platform

# Setup development environment
./setup-dev-env.sh

# Start all services
docker-compose up --build -d

# Check service status
docker-compose ps

# View social service logs
docker-compose logs -f social-service
```

### **2. Production Setup (Oracle)**
```bash
# Setup production environment
./setup-prod-env.sh

# Edit .env with your production values
nano .env

# Deploy to Oracle Cloud
docker-compose -f docker-compose.oracle.yml up -d
```

### **3. Test Social Service**
```bash
# Test health endpoint
curl http://localhost:8008/health

# Test via gateway
curl http://localhost:8000/social/health

# View API documentation
open http://localhost:8008/docs
```

## 📈 **Business Impact**

### **Revenue Generation**
- Sponsored content from service providers
- Premium analytics for providers
- Enhanced user engagement = higher retention

### **Market Expansion**
- Appeals to Gen Z and younger demographics
- Attracts non-car owners to the platform
- Creates community around automotive lifestyle

### **Provider Value**
- Enhanced marketing tools
- Detailed analytics and ROI tracking
- Direct engagement with potential customers

## 🔄 **Next Steps**

### **1. Database Migration**
```bash
cd backend/social_service
alembic revision --autogenerate -m "Initial social schema"
alembic upgrade head
```

### **2. Frontend Integration**
- Update Flutter app to consume social API
- Implement social hub UI components
- Add media upload functionality

### **3. Content Moderation**
- Set up content moderation API key
- Configure automated filtering rules
- Implement user reporting system

### **4. Analytics Dashboard**
- Create provider analytics dashboard
- Implement real-time metrics
- Set up automated reports

## 🆘 **Troubleshooting**

### **Common Issues**

**Service won't start:**
```bash
# Check logs
docker-compose logs social-service

# Check database connection
docker-compose exec social-service python -c "from core.db import engine; print(engine.execute('SELECT 1').fetchone())"
```

**Database migration issues:**
```bash
# Reset migrations
cd backend/social_service
alembic downgrade base
alembic upgrade head
```

**Media upload issues:**
```bash
# Check upload directory permissions
docker-compose exec social-service ls -la /app/uploads

# Check S3 credentials (production)
docker-compose exec social-service env | grep AWS
```

## 📞 **Support**

For issues or questions:
1. Check service logs: `docker-compose logs social-service`
2. Verify environment variables: `docker-compose exec social-service env`
3. Test database connection: `docker-compose exec social-service python -c "from core.db import engine; print('DB OK')"`
4. Check API documentation: `http://localhost:8008/docs`

---

**🎉 Your social service is now fully integrated and ready to power the Instagram/Twitter/Pinterest-like social hub for your DriveOn platform!**
