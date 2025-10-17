#!/bin/bash

# Script to bootstrap database migrations for all services
# This script will:
# 1. Stamp services (except alert-service) to base
# 2. Generate new initial migrations
# 3. Run migrations to create all tables

echo "🚀 Bootstrapping database migrations for all services..."

# List of services to bootstrap (excluding alert-service which already has tables)
services=(
    "user-service"
    "vehicle-service" 
    "booking-service"
    "insurance-service"
    "expenses-service"
    "service-provider"
)

for service in "${services[@]}"; do
    echo "📝 Processing $service..."
    
    # Step 1: Stamp to base (this tells Alembic the database is at the initial state)
    echo "  🔹 Stamping $service to base..."
    docker compose -f docker-compose.oracle.yml run --rm $service alembic stamp base
    
    # Step 2: Generate new initial migration
    echo "  🔹 Generating initial migration for $service..."
    docker compose -f docker-compose.oracle.yml run --rm $service alembic revision --autogenerate -m "initial $service tables"
    
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
