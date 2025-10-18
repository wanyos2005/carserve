#!/bin/bash

# Script to verify tables exist in Neon database
# This will help us see what tables are actually created

echo "🔍 Verifying tables in Neon database..."
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

echo "📋 Checking all schemas and tables..."
echo ""

for service in "${!services[@]}"; do
    schema="${services[$service]}"
    echo "🔹 Checking schema: $schema (service: $service)"
    
    # List tables in the schema
    if [ "$service" == "service-provider" ]; then
        docker compose -f docker-compose.oracle.yml run --rm $service sh -c "
cd /app/app
python -c \"
import psycopg2
import os

# Get database URL from environment
database_url = os.getenv('DATABASE_URL')
if not database_url:
    print('❌ DATABASE_URL not set')
    exit(1)

try:
    conn = psycopg2.connect(database_url)
    cur = conn.cursor()
    
    # List tables in the schema
    cur.execute(\"\"\"
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = '$schema'
        ORDER BY table_name;
    \"\"\")
    
    tables = cur.fetchall()
    if tables:
        print(f'✅ Tables in $schema schema:')
        for table in tables:
            print(f'   - {table[0]}')
    else:
        print(f'❌ No tables found in $schema schema')
    
    # Also check if schema exists
    cur.execute(\"\"\"
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name = '$schema';
    \"\"\")
    
    schema_exists = cur.fetchone()
    if not schema_exists:
        print(f'❌ Schema $schema does not exist!')
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f'❌ Error checking $schema: {e}')
\"
"
    else
        docker compose -f docker-compose.oracle.yml run --rm $service python -c "
import psycopg2
import os

# Get database URL from environment
database_url = os.getenv('DATABASE_URL')
if not database_url:
    print('❌ DATABASE_URL not set')
    exit(1)

try:
    conn = psycopg2.connect(database_url)
    cur = conn.cursor()
    
    # List tables in the schema
    cur.execute(\"\"\"
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = '$schema'
        ORDER BY table_name;
    \"\"\")
    
    tables = cur.fetchall()
    if tables:
        print(f'✅ Tables in $schema schema:')
        for table in tables:
            print(f'   - {table[0]}')
    else:
        print(f'❌ No tables found in $schema schema')
    
    # Also check if schema exists
    cur.execute(\"\"\"
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name = '$schema';
    \"\"\")
    
    schema_exists = cur.fetchone()
    if not schema_exists:
        print(f'❌ Schema $schema does not exist!')
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f'❌ Error checking $schema: {e}')
" || echo "    ❌ Failed to check $schema"
    fi
    
    echo ""
done

echo "🔍 Checking all schemas in the database..."
docker compose -f docker-compose.oracle.yml run --rm user-service python -c "
import psycopg2
import os

database_url = os.getenv('DATABASE_URL')
if not database_url:
    print('❌ DATABASE_URL not set')
    exit(1)

try:
    conn = psycopg2.connect(database_url)
    cur = conn.cursor()
    
    # List all schemas
    cur.execute(\"\"\"
        SELECT schema_name 
        FROM information_schema.schemata 
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
        ORDER BY schema_name;
    \"\"\")
    
    schemas = cur.fetchall()
    print('📋 All schemas in database:')
    for schema in schemas:
        print(f'   - {schema[0]}')
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f'❌ Error listing schemas: {e}')
"

echo ""
echo "🎯 Summary:"
echo "   - If you see tables listed above, they exist in Neon"
echo "   - If you don't see them in Neon dashboard, try:"
echo "     1. Refresh the dashboard"
echo "     2. Check if you're looking at the right database"
echo "     3. Check if schema filter is applied"
echo "     4. Try connecting directly to Neon with psql"
