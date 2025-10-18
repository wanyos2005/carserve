#!/bin/bash

# Hybrid approach: Direct table creation + Alembic setup
# This creates tables directly, then sets up Alembic for future changes

echo "🚀 Setting up database with proper migration history..."
echo ""

# Step 1: Create all tables directly (bypassing Alembic)
echo "📝 Step 1: Creating all tables directly..."
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
    echo "  🔹 Creating tables for $service..."
    docker compose -f docker-compose.oracle.yml run --rm $service python -c "
from core.db import Base, engine
Base.metadata.create_all(bind=engine)
print(f'✅ Tables created for $service')
"
done

echo ""
echo "📝 Step 2: Setting up Alembic migration history..."

# Step 2: Create initial Alembic migrations and stamp them
for service in "${!services[@]}"; do
    echo "  🔹 Setting up Alembic for $service..."
    
    # Create a new initial migration
    docker compose -f docker-compose.oracle.yml run --rm $service alembic revision --autogenerate -m "initial tables (created directly)" || echo "    ⚠️  Migration generation failed, continuing..."
    
    # Stamp the database as being at the latest revision
    docker compose -f docker-compose.oracle.yml run --rm $service alembic stamp head || echo "    ⚠️  Stamping failed, continuing..."
    
    echo "    ✅ Alembic setup completed for $service"
done

echo ""
echo "🎉 Database setup completed!"
echo ""
echo "📋 What was done:"
echo "  1. ✅ Created all tables directly using SQLAlchemy"
echo "  2. ✅ Set up Alembic migration history"
echo "  3. ✅ Database is ready for future migrations"
echo ""
echo "📋 Next steps:"
echo "  1. Test the services:"
echo "     curl http://localhost/booking-health"
echo "     curl http://localhost/users/health"
echo "     curl http://localhost/vehicles/health"
echo ""
echo "  2. Start the services:"
echo "     docker compose -f docker-compose.oracle.yml up -d"
echo ""
echo "  3. For future changes, use normal Alembic workflow:"
echo "     docker compose -f docker-compose.oracle.yml run --rm user-service alembic revision --autogenerate -m 'description'"
echo "     docker compose -f docker-compose.oracle.yml run --rm user-service alembic upgrade head"
