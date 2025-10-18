#!/bin/bash

# Simple script to verify database tables exist
# Usage: ./verify_database.sh

echo "🔍 Verifying database tables in Neon..."
echo ""

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL environment variable is not set"
    echo "Please set it to your Neon database URL"
    exit 1
fi

echo "📋 Checking all schemas and tables..."
echo ""

# List all schemas
echo "🔹 All schemas in database:"
if command -v psql &> /dev/null; then
    psql "$DATABASE_URL" -c "
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name;
    "
else
    docker run --rm postgres:15-alpine psql "$DATABASE_URL" -c "
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name;
    "
fi

echo ""
echo "🔹 Tables in each schema:"

# List tables in each schema
schemas=("users" "vehicles" "bookings" "insurance" "expenses" "service_providers" "alerts")

for schema in "${schemas[@]}"; do
    echo "📋 Schema: $schema"
    if command -v psql &> /dev/null; then
        psql "$DATABASE_URL" -c "
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = '$schema'
            ORDER BY table_name;
        "
    else
        docker run --rm postgres:15-alpine psql "$DATABASE_URL" -c "
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = '$schema'
            ORDER BY table_name;
        "
    fi
    echo ""
done

echo "✅ Database verification completed!"
echo ""
echo "📋 If you see tables listed above, your database is ready!"
echo "   Next steps:"
echo "   1. Start services: docker compose -f docker-compose.oracle.yml up -d"
echo "   2. Test endpoints through the gateway"
