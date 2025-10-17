#!/bin/bash

# Script to bootstrap database migrations for all services
# This script will:
# 1. Delete and recreate empty alembic/versions folders
# 2. Generate new initial migrations for Neon database
# 3. Run migrations to create all tables
# NOTE: Assumes schemas are created manually in Neon

echo "🚀 Bootstrapping database migrations for all services..."
echo "⚠️  WARNING: This will delete existing migration files and create new ones!"
echo ""

# List of services to bootstrap
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
    echo "📝 Processing $service..."
    
    # Get the correct service path
    if [ "$service" == "service-provider" ]; then
        service_path="backend/service_provider_service"
    else
        service_path="backend/${service//-/_}"
    fi
    
    # Step 1: Delete and recreate empty alembic/versions folder
    echo "  🔹 Cleaning migration files for $service..."
    if [ -d "$service_path/alembic/versions" ]; then
        rm -rf "$service_path/alembic/versions"
        echo "    ✅ Deleted existing versions folder"
    fi
    mkdir -p "$service_path/alembic/versions"
    echo "    ✅ Created empty versions folder"
    
    # Step 2: Generate new initial migration
    echo "  🔹 Generating initial migration for $service..."
    docker compose -f docker-compose.oracle.yml run --rm $service alembic revision --autogenerate -m "initial $service tables for Neon"
    
    # Step 3: Run the migration to create tables
    echo "  🔹 Running migration for $service..."
    docker compose -f docker-compose.oracle.yml run --rm $service alembic upgrade head
    
    echo "  ✅ $service migration completed"
    echo ""
done

echo "🎉 All migrations completed successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Test the services:"
echo "     curl http://localhost/booking-health"
echo "     curl http://localhost/users/health"
echo "     curl http://localhost/vehicles/health"
echo ""
echo "  2. Check database schemas in Neon dashboard"
echo ""
echo "  3. Commit the new migration files:"
echo "     git add backend/*/alembic/versions/"
echo "     git commit -m 'Add initial migration files for all services'"
echo "     git push origin main"
