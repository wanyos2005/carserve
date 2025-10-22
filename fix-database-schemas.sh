#!/bin/bash

# Fix Database Schema Issues
echo "🔧 Fixing database schema issues..."

# Create the missing social schema
echo "📦 Creating missing social schema..."
docker compose exec -T postgres psql -U AdminDb -d car_platform << 'EOF'
-- Create the missing social schema
CREATE SCHEMA IF NOT EXISTS social;
GRANT ALL ON SCHEMA social TO "AdminDb";
EOF

# Create the missing alerts schema
echo "📦 Creating missing alerts schema..."
docker compose exec -T postgres psql -U AdminDb -d car_platform << 'EOF'
-- Create the missing alerts schema
CREATE SCHEMA IF NOT EXISTS alerts;
GRANT ALL ON SCHEMA alerts TO "AdminDb";
EOF

echo "✅ Database schemas fixed!"
echo "🚀 Now you can run the migrations manually:"
echo "   docker compose exec alert-service alembic upgrade head"
echo "   docker compose exec social-service alembic upgrade head"
