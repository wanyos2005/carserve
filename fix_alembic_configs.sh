#!/bin/bash

# Script to fix all Alembic configurations to use external database
# This updates all services to use DATABASE_URL environment variable instead of hardcoded postgres URLs

echo "🔧 Fixing Alembic configurations for all services..."

# List of services to fix
services=(
    "user_service"
    "vehicle_service" 
    "booking_service"
    "insurance_service"
    "expenses_service"
    "service_provider_service"
    "alert_service"
)

for service in "${services[@]}"; do
    echo "📝 Fixing $service..."
    
    # Fix alembic.ini - comment out hardcoded URL
    if [ -f "backend/$service/alembic.ini" ]; then
        sed -i 's/^sqlalchemy\.url = postgresql/# sqlalchemy.url = postgresql/' "backend/$service/alembic.ini"
        echo "  ✅ Updated alembic.ini"
    fi
    
    # Fix env.py - add environment variable support
    if [ -f "backend/$service/alembic/env.py" ]; then
        # Check if already updated
        if ! grep -q "DATABASE_URL" "backend/$service/alembic/env.py"; then
            # Add the environment variable logic before the engine_from_config call
            sed -i '/def run_migrations_online():/a\
    # Get database URL from environment variable\
    database_url = os.getenv("DATABASE_URL")\
    if not database_url:\
        raise ValueError("DATABASE_URL environment variable is not set")\
    \
    # Override the sqlalchemy.url in the config\
    config.set_main_option("sqlalchemy.url", database_url)\
' "backend/$service/alembic/env.py"
            echo "  ✅ Updated env.py"
        else
            echo "  ⚠️  env.py already updated"
        fi
    fi
done

echo "🎉 All Alembic configurations fixed!"
echo "📋 Next steps:"
echo "  1. git add ."
echo "  2. git commit -m 'Fix Alembic configs: use DATABASE_URL instead of hardcoded postgres URLs'"
echo "  3. git push origin main"
echo "  4. Wait for CI/CD to deploy and run migrations"
