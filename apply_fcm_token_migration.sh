#!/bin/bash

# Script to apply the fcm_token migration to production database
# This fixes the "column tbl_auth.fcm_token does not exist" error

set -e

echo "🔧 FCM Token Migration Script"
echo "=============================="
echo ""

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL environment variable is not set"
    echo "Please set it to your Neon database URL"
    echo ""
    echo "Example:"
    echo "export DATABASE_URL='postgresql://neondb_owner:your_password@ep-damp-violet-ae06n7zk-pooler.c-2.us-east-2.aws.neon.tech/neondb?sslmode=require&channel_binding=require'"
    exit 1
fi

echo "📋 Database: $(echo $DATABASE_URL | sed 's/:[^:]*@/:***@/')"
echo ""

# First, check if the column already exists
echo "🔍 Checking if fcm_token column already exists..."
if command -v psql &> /dev/null; then
    COLUMN_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'users' AND table_name = 'tbl_auth' AND column_name = 'fcm_token');" | xargs)
else
    COLUMN_EXISTS=$(docker run --rm postgres:15-alpine psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'users' AND table_name = 'tbl_auth' AND column_name = 'fcm_token');" | xargs)
fi

if [ "$COLUMN_EXISTS" = "t" ]; then
    echo "✅ fcm_token column already exists! No migration needed."
    exit 0
fi

echo "❌ fcm_token column does not exist. Applying migration..."
echo ""

# Ask for confirmation
read -p "Do you want to apply the fcm_token migration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration cancelled"
    exit 1
fi

echo "🔄 Applying fcm_token migration..."

# Apply the migration
if command -v psql &> /dev/null; then
    echo "Using local psql..."
    psql "$DATABASE_URL" -f "migrations/029_add_fcm_token_to_users.sql"
else
    echo "Using Docker psql..."
    docker run --rm -i postgres:15-alpine psql "$DATABASE_URL" < "migrations/029_add_fcm_token_to_users.sql"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration applied successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Restart your services: docker compose -f docker-compose.oracle.yml restart"
    echo "  2. Test the /send-code endpoint"
    echo "  3. Check that the 500 error is resolved"
    echo ""
    echo "🎉 The fcm_token column has been added to users.tbl_auth!"
else
    echo ""
    echo "❌ Migration failed!"
    echo "Please check the error messages above and fix any issues."
    exit 1
fi
