#!/bin/bash

# Database Reset and Migration Script
# This script will drop all schemas, recreate them, generate migrations, and apply them

echo "🗑️  Resetting database schemas and running migrations..."

# Function to run command in container
run_in_container() {
    local service=$1
    shift
    local command="$@"
    echo "📦 Running in $service: $command"
    docker compose exec $service sh -c "$command"
}

# Function to check if container is running
check_container() {
    local service=$1
    if ! docker compose ps $service | grep -q "Up"; then
        echo "❌ Container $service is not running. Starting it..."
        docker compose up -d $service
        sleep 5
    fi
}

echo "🔧 Step 1: Dropping and recreating schemas in PostgreSQL..."

# Create SQL script for schema reset
cat > /tmp/reset_schemas.sql << 'EOF'
-- Drop all schemas except public
DROP SCHEMA IF EXISTS alerts CASCADE;
DROP SCHEMA IF EXISTS bookings CASCADE;
DROP SCHEMA IF EXISTS expenses CASCADE;
DROP SCHEMA IF EXISTS insurance CASCADE;
DROP SCHEMA IF EXISTS service_providers CASCADE;
DROP SCHEMA IF EXISTS users CASCADE;
DROP SCHEMA IF EXISTS vehicles CASCADE;
DROP SCHEMA IF EXISTS social CASCADE;


-- Recreate all schemas
CREATE SCHEMA alerts;
CREATE SCHEMA bookings;
CREATE SCHEMA expenses;
CREATE SCHEMA insurance;
CREATE SCHEMA service_providers;
CREATE SCHEMA users;
CREATE SCHEMA vehicles;
CREATE SCHEMA social;

-- Grant permissions to AdminDb
GRANT ALL ON SCHEMA alerts TO "AdminDb";
GRANT ALL ON SCHEMA bookings TO "AdminDb";
GRANT ALL ON SCHEMA expenses TO "AdminDb";
GRANT ALL ON SCHEMA insurance TO "AdminDb";
GRANT ALL ON SCHEMA service_providers TO "AdminDb";
GRANT ALL ON SCHEMA users TO "AdminDb";
GRANT ALL ON SCHEMA vehicles TO "AdminDb";
GRANT ALL ON SCHEMA social TO "AdminDb";
EOF

# Execute the SQL script
docker compose exec -T postgres psql -U AdminDb -d car_platform < /tmp/reset_schemas.sql

# Clean up
rm /tmp/reset_schemas.sql

echo "✅ Schemas recreated successfully!"

echo "🔧 Step 2: Clearing existing alembic versions..."

# List of services
services=(
    "user-service"
    "vehicle-service"
    "service-provider"
    "booking-service"
    "insurance-service"
    "alert-service"
    "expenses-service"
    "social-service"
)

# Clear existing alembic versions for each service
for service in "${services[@]}"; do
    echo "🗑️  Clearing alembic versions for $service..."
    check_container $service
    
    # Remove all files from alembic/versions folder
    run_in_container $service "rm -rf /app/alembic/versions/*"
    if [ $? -eq 0 ]; then
        echo "✅ Cleared versions for $service"
    else
        echo "⚠️  No versions to clear for $service (folder might be empty)"
    fi
done

echo "🔧 Step 3: Generating fresh migrations for each service..."

# Generate migrations for each service
for service in "${services[@]}"; do
    echo "📝 Generating migration for $service..."
    check_container $service
    run_in_container $service "alembic revision --autogenerate -m 'tables initialization'"
    if [ $? -eq 0 ]; then
        echo "✅ Migration generated for $service"
    else
        echo "❌ Failed to generate migration for $service"
    fi
done

echo "🔧 Step 4: Applying migrations..."

# Apply migrations for each service
for service in "${services[@]}"; do
    echo "🚀 Applying migration for $service..."
    run_in_container $service "alembic upgrade head"
    if [ $? -eq 0 ]; then
        echo "✅ Migration applied for $service"
    else
        echo "❌ Failed to apply migration for $service"
    fi
done

echo "🎉 Database reset and migrations completed!"
echo ""
echo "📋 Summary:"
echo "   - All schemas dropped and recreated"
echo "   - Existing alembic versions cleared from all services"
echo "   - Fresh migrations generated for all services"
echo "   - Migrations applied to database"
echo ""
echo "🌐 Your services should now be ready at:"
echo "   Gateway: http://localhost:8000"
echo "   User Service: http://localhost:8001"
echo "   Vehicle Service: http://localhost:8002"
echo "   Service Provider: http://localhost:8003"
echo "   Booking Service: http://localhost:8004"
echo "   Insurance Service: http://localhost:8005"
echo "   Alert Service: http://localhost:8006"
echo "   Expenses Service: http://localhost:8007"
echo "   Social Service: http://localhost:8008"
