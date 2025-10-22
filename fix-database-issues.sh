#!/bin/bash

# Fix Database Issues Script
# This script will:
# 1. Create the proper provider_service_view as a database view
# 2. Fix the alert-service enum issue
# 3. Apply the alert-service migration

echo "🔧 Fixing database issues..."

# Function to run command in container
run_in_container() {
    local service=$1
    shift
    local command="$@"
    echo "📦 Running in $service: $command"
    docker compose exec $service sh -c "$command"
}

echo "🔧 Step 1: Creating proper provider_service_view as a database view..."

# Create the view using the SQL file
docker compose exec -T postgres psql -U AdminDb -d car_platform < backend/service_provider_service/create_provider_view.sql

if [ $? -eq 0 ]; then
    echo "✅ Provider service view created successfully"
else
    echo "❌ Failed to create provider service view"
    exit 1
fi

echo "🔧 Step 2: Creating missing database schemas..."

# Create the missing schemas
docker compose exec postgres psql -U AdminDb -d car_platform -c "
CREATE SCHEMA IF NOT EXISTS alerts;
CREATE SCHEMA IF NOT EXISTS social;
GRANT ALL ON SCHEMA alerts TO \"AdminDb\";
GRANT ALL ON SCHEMA social TO \"AdminDb\";
"

if [ $? -eq 0 ]; then
    echo "✅ Missing schemas created successfully"
else
    echo "❌ Failed to create missing schemas"
    exit 1
fi

echo "🔧 Step 3: Fixing alert-service enum issue..."

# Drop the existing enum if it exists
docker compose exec postgres psql -U AdminDb -d car_platform -c "DROP TYPE IF EXISTS alerttype CASCADE;"

if [ $? -eq 0 ]; then
    echo "✅ Alerttype enum dropped successfully"
else
    echo "❌ Failed to drop alerttype enum"
    exit 1
fi

echo "🔧 Step 4: Applying alert-service migration..."

# Apply the alert-service migration
run_in_container alert-service "alembic upgrade head"

if [ $? -eq 0 ]; then
    echo "✅ Alert-service migration applied successfully"
else
    echo "❌ Failed to apply alert-service migration"
    exit 1
fi

echo "🔧 Step 5: Applying social-service migration..."

# Apply the social-service migration
run_in_container social-service "alembic upgrade head"

if [ $? -eq 0 ]; then
    echo "✅ Social-service migration applied successfully"
else
    echo "❌ Failed to apply social-service migration"
    exit 1
fi

echo "🎉 Database issues fixed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Provider service view created as proper database view"
echo "   - Missing database schemas (alerts, social) created"
echo "   - Alerttype enum issue resolved"
echo "   - Alert-service migration applied"
echo "   - Social-service migration applied"
echo ""
echo "🌐 All services should now be ready at:"
echo "   Gateway: http://localhost:8000"
echo "   User Service: http://localhost:8001"
echo "   Vehicle Service: http://localhost:8002"
echo "   Service Provider: http://localhost:8003"
echo "   Booking Service: http://localhost:8004"
echo "   Insurance Service: http://localhost:8005"
echo "   Alert Service: http://localhost:8006"
echo "   Expenses Service: http://localhost:8007"
