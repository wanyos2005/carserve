#!/bin/bash

# Script to create all tables directly using SQL
# This bypasses Alembic completely and creates tables directly

echo "🚀 Creating all tables directly in Neon database..."
echo "⚠️  WARNING: This will create tables directly without Alembic migrations!"
echo ""

# List of services and their schemas
declare -A services=(
    ["user-service"]="users"
    ["vehicle-service"]="vehicles"
    ["booking-service"]="bookings"
    ["insurance-service"]="insurance"
    ["expenses-service"]="expenses"
    ["service-provider"]="service_providers"
    ["alert-service"]="alerts"
)

for service in "${!services[@]}"; do
    schema="${services[$service]}"
    echo "📝 Creating tables for $service in schema: $schema..."
    
    # Create tables directly using the service's SQLAlchemy models
    docker compose -f docker-compose.oracle.yml run --rm $service python -c "
import os
from sqlalchemy import create_engine, text
from core.db import Base, engine

# Create all tables for this service
print(f'Creating tables in schema: $schema')
Base.metadata.create_all(bind=engine)
print(f'✅ Tables created successfully for $service')
"
    
    echo "  ✅ $service tables created"
    echo ""
done

echo "🎉 All tables created successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Test the services:"
echo "     curl http://localhost/booking-health"
echo "     curl http://localhost/users/health"
echo "     curl http://localhost/vehicles/health"
echo ""
echo "  2. Check database schemas in Neon dashboard"
echo ""
echo "  3. Start the services:"
echo "     docker compose -f docker-compose.oracle.yml up -d"
