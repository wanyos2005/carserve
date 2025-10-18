#!/bin/bash

# Script to fix DATABASE_URL configuration in all services
# This makes services use DATABASE_URL environment variable directly

echo "🔧 Fixing DATABASE_URL configuration in all services..."

# List of services
services=(
    "user-service"
    "vehicle-service"
    "booking-service"
    "insurance-service"
    "expenses-service"
    "service-provider"
    "alert-service"
)

for service in "${services[@]}"; do
    echo "📝 Fixing $service..."
    
    # Get the correct service path
    if [ "$service" == "service-provider" ]; then
        service_path="backend/service_provider_service"
    else
        service_path="backend/${service//-/_}"
    fi
    
    config_file="$service_path/core/config.py"
    
    if [ -f "$config_file" ]; then
        echo "  🔹 Updating $config_file..."
        
        # Create backup
        cp "$config_file" "$config_file.backup"
        
        # Replace the DATABASE_URL section
        sed -i '/^DB_USER = os.getenv/d' "$config_file"
        sed -i '/^DB_PASSWORD = os.getenv/d' "$config_file"
        sed -i '/^DB_NAME = os.getenv/d' "$config_file"
        sed -i '/^DB_HOST = os.getenv/d' "$config_file"
        sed -i '/^DB_PORT = os.getenv/d' "$config_file"
        sed -i '/^DATABASE_URL = f"postgresql/d' "$config_file"
        
        # Add new DATABASE_URL configuration
        sed -i '/^load_dotenv()/a\
\
# Use DATABASE_URL directly from environment (for Neon/external DB)\
# Fallback to individual components for local development\
DATABASE_URL = os.getenv("DATABASE_URL")\
if not DATABASE_URL:\
    # Fallback for local development\
    DB_USER = os.getenv("DB_USER", "AdminDb")\
    DB_PASSWORD = os.getenv("DB_PASSWORD", "Ngojakwanza")\
    DB_NAME = os.getenv("DB_NAME", "car_platform")\
    DB_HOST = os.getenv("DB_HOST", "postgres")\
    DB_PORT = os.getenv("DB_PORT", "5432")\
    DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"\
' "$config_file"
        
        echo "    ✅ Updated $config_file"
    else
        echo "    ⚠️  Config file not found: $config_file"
    fi
done

echo ""
echo "🎉 All services updated!"
echo ""
echo "📋 What was changed:"
echo "  1. ✅ Services now use DATABASE_URL environment variable directly"
echo "  2. ✅ Fallback to individual components for local development"
echo "  3. ✅ Works with both internal postgres and external Neon"
echo ""
echo "📋 Next steps:"
echo "  1. Commit and push changes:"
echo "     git add backend/*/core/config.py"
echo "     git commit -m 'Fix DATABASE_URL configuration for Neon compatibility'"
echo "     git push origin main"
echo ""
echo "  2. Wait for CI/CD to complete"
echo ""
echo "  3. Run the database setup script on VM:"
echo "     ./setup_database_properly.sh"
