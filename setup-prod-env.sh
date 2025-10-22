#!/bin/bash

# Production Environment Setup Script
# This script sets up the production environment with external databases

echo "🚀 Setting up Car Platform Production Environment..."

# Copy env.prod to .env for production (always replace for clean prod setup)
if [ -f env.prod ]; then
    echo "📝 Copying env.prod to .env for production..."
    cp env.prod .env
    echo "✅ .env file created from env.prod"
    echo "⚠️  IMPORTANT: Please edit .env file with your actual production values before deploying!"
else
    echo "❌ env.prod file not found. Please ensure env.prod exists in the root directory."
    exit 1
fi

# Create individual .env files for each service with production settings
services=("user_service" "vehicle_service" "service_provider_service" "booking_service" "insurance_service" "alert_service" "expenses_service" "social_service")

for service in "${services[@]}"; do
    service_path="backend/${service}"
    env_file="${service_path}/.env"
    
    echo "📝 Creating production .env file for $service..."
    
    # Special configuration for social service
    if [ "$service" = "social_service" ]; then
        cat > "$env_file" << EOF
# Production Environment for $service
# Use external database URLs from main .env file
DATABASE_URL=\${NEON_DATABASE_URL}
REDIS_URL=\${UPSTASH_REDIS_URL}
SECRET_KEY=\${JWT_SECRET_KEY}
ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
ENVIRONMENT=production
LOG_LEVEL=INFO

# Social Service Specific Configuration
SOCIAL_SERVICE_PORT=8008
ENABLE_CONTENT_MODERATION=true
ENABLE_ANALYTICS=true
ENABLE_NOTIFICATIONS=true
RATE_LIMIT_ENABLED=true
MEDIA_STORAGE_TYPE=cloudflare
MEDIA_UPLOAD_PATH=/app/uploads
MAX_FILE_SIZE=10485760
ALLOWED_IMAGE_TYPES=image/jpeg,image/png,image/gif,image/webp
ALLOWED_VIDEO_TYPES=video/mp4,video/webm,video/quicktime
ANALYTICS_RETENTION_DAYS=90
RATE_LIMIT_REQUESTS_PER_MINUTE=60
PUSH_NOTIFICATION_ENABLED=true

# Cloudflare R2 Configuration (for media storage)
CLOUDFLARE_ACCOUNT_ID=4739f91ba1dc08d51ef1d0e905c95da7
CLOUDFLARE_ACCESS_KEY_ID=1c2c27b577ed7c83ab8c17baf76fc50c
CLOUDFLARE_SECRET_ACCESS_KEY=4351417510a2f068ffa87ea703e5afb68f05ae10efdd8155d1071097143363b1
CLOUDFLARE_BUCKET=driveon-social-media
CLOUDFLARE_PUBLIC_URL=https://pub-4739f91ba1dc08d51ef1d0e905c95da7.r2.dev

# Content Moderation
MODERATION_API_KEY=\${MODERATION_API_KEY}

# Email settings
SMTP_HOST=\${SMTP_HOST}
SMTP_PORT=\${SMTP_PORT}
SMTP_USERNAME=\${SMTP_USERNAME}
SMTP_PASSWORD=\${SMTP_PASSWORD}
SMTP_FROM_EMAIL=\${SMTP_FROM_EMAIL}
SMTP_FROM_NAME=\${SMTP_FROM_NAME}
SMTP_TLS=\${SMTP_TLS}
SMTP_SSL=\${SMTP_SSL}

# SMS Configuration
SMS_PROVIDER=\${SMS_PROVIDER}
AT_USERNAME=\${AT_USERNAME}
AT_API_KEY=\${AT_API_KEY}
AT_SENDER_ID=\${AT_SENDER_ID}

# Push Notifications
FCM_SERVER_KEY=\${FCM_SERVER_KEY}

# Celery Configuration for Social Service
CELERY_BROKER_URL=\${UPSTASH_REDIS_URL}/0
CELERY_RESULT_BACKEND=\${UPSTASH_REDIS_URL}/1

EOF
    else
        cat > "$env_file" << EOF
# Production Environment for $service
# Use external database URLs from main .env file
DATABASE_URL=\${NEON_DATABASE_URL}
REDIS_URL=\${UPSTASH_REDIS_URL}
SECRET_KEY=\${JWT_SECRET_KEY}
ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
ENVIRONMENT=production
LOG_LEVEL=INFO

# Email settings
SMTP_HOST=\${SMTP_HOST}
SMTP_PORT=\${SMTP_PORT}
SMTP_USERNAME=\${SMTP_USERNAME}
SMTP_PASSWORD=\${SMTP_PASSWORD}
SMTP_FROM_EMAIL=\${SMTP_FROM_EMAIL}
SMTP_FROM_NAME=\${SMTP_FROM_NAME}
SMTP_TLS=\${SMTP_TLS}
SMTP_SSL=\${SMTP_SSL}

# SMS Configuration
SMS_PROVIDER=\${SMS_PROVIDER}
AT_USERNAME=\${AT_USERNAME}
AT_API_KEY=\${AT_API_KEY}
AT_SENDER_ID=\${AT_SENDER_ID}

# Push Notifications
FCM_SERVER_KEY=\${FCM_SERVER_KEY}

EOF
    fi
    echo "✅ Created production .env for $service"
done

echo ""
echo "🎉 Production environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Ensure your .env file has all required production values"
echo "2. Run: docker-compose -f docker-compose.oracle.yml up -d"
echo "3. Or use your CI/CD pipeline to deploy"
echo ""
echo "⚠️  Important Notes:"
echo "   - Production uses external databases (Neon PostgreSQL + Upstash Redis)"
echo "   - Make sure your external database credentials are correct"
echo "   - Update ALLOWED_ORIGINS with your production domain"
echo "   - Use strong JWT_SECRET_KEY for production"
echo "   - Social service uses Cloudflare R2 for media storage (configured)"
echo "   - Set up content moderation API key for social content filtering"
echo ""
echo "🌐 Social Hub Production URLs:"
echo "   Social API: https://yourdomain.com/social/"
echo "   Social Docs: https://yourdomain.com:8008/docs"
