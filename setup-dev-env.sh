#!/bin/bash

# Development Environment Setup Script
# This script sets up the development environment with proper configuration

echo "🔧 Setting up Car Platform Development Environment..."

# Copy env.dev to .env for development (always replace for clean dev setup)
if [ -f env.dev ]; then
    echo "📝 Copying env.dev to .env for development..."
    cp env.dev .env
    echo "✅ .env file created from env.dev"
else
    echo "❌ env.dev file not found. Please ensure env.dev exists in the root directory."
    exit 1
fi

# Create individual .env files for each service if they don't exist
services=("user_service" "vehicle_service" "service_provider_service" "booking_service" "insurance_service" "alert_service" "expenses_service" "social_service")

for service in "${services[@]}"; do
    service_path="backend/${service}"
    env_file="${service_path}/.env"
    
    if [ ! -f "$env_file" ]; then
        echo "📝 Creating .env file for $service..."
        # Special configuration for social service
        if [ "$service" = "social_service" ]; then
            cat > "$env_file" << EOF
# Development Environment for $service
DATABASE_URL=postgresql+psycopg2://AdminDb:Ngojakwanza@postgres:5432/car_platform
DB_HOST=postgres
DB_NAME=car_platform
DB_USER=AdminDb
DB_PASSWORD=Ngojakwanza
REDIS_HOST=redis
REDIS_URL=redis://redis:6379
SECRET_KEY=dev-super-secret-jwt-key-here
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081,http://localhost:8000
ENVIRONMENT=development
LOG_LEVEL=DEBUG

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

# Celery Configuration for Social Service
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/1

# Cloudflare R2 Configuration
CLOUDFLARE_ACCOUNT_ID=4739f91ba1dc08d51ef1d0e905c95da7
CLOUDFLARE_ACCESS_KEY_ID=1c2c27b577ed7c83ab8c17baf76fc50c
CLOUDFLARE_SECRET_ACCESS_KEY=4351417510a2f068ffa87ea703e5afb68f05ae10efdd8155d1071097143363b1
CLOUDFLARE_BUCKET=driveon-social-media
CLOUDFLARE_PUBLIC_URL=https://pub-4739f91ba1dc08d51ef1d0e905c95da7.r2.dev
EOF
        else
            cat > "$env_file" << EOF
# Development Environment for $service
DATABASE_URL=postgresql+psycopg2://AdminDb:Ngojakwanza@postgres:5432/car_platform
DB_HOST=postgres
DB_NAME=car_platform
DB_USER=AdminDb
DB_PASSWORD=Ngojakwanza
REDIS_HOST=redis
REDIS_URL=redis://redis:6379
SECRET_KEY=dev-super-secret-jwt-key-here
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081,http://localhost:8000
ENVIRONMENT=development
LOG_LEVEL=DEBUG
EOF
        fi
        echo "✅ Created .env for $service"
    else
        echo "ℹ️  .env file already exists for $service"
    fi
done

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Run: docker-compose up --build -d"
echo "2. Wait for services to start (about 2-3 minutes)"
echo "3. Check service status: docker-compose ps"
echo "4. View logs: docker-compose logs -f [service-name]"
echo ""
echo "🌐 Service URLs:"
echo "   Gateway: http://localhost:8000"
echo "   User Service: http://localhost:8001"
echo "   Vehicle Service: http://localhost:8002"
echo "   Service Provider: http://localhost:8003"
echo "   Booking Service: http://localhost:8004"
echo "   Insurance Service: http://localhost:8005"
echo "   Alert Service: http://localhost:8006"
echo "   Expenses Service: http://localhost:8007"
echo "   Social Service: http://localhost:8008"
echo "   PostgreSQL: localhost:5432"
echo "   Redis: localhost:6379"
echo ""
echo "📱 Social Hub Features:"
echo "   Posts & Stories: http://localhost:8000/social/"
echo "   API Documentation: http://localhost:8008/docs"
