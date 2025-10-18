#!/bin/bash

# Script to apply database migrations
# Usage: ./apply_migration.sh [migration_file]

set -e

MIGRATION_FILE=${1:-"migrations/001_initial_schema.sql"}

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "🚀 Applying migration: $MIGRATION_FILE"
echo ""

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL environment variable is not set"
    echo "Please set it to your Neon database URL"
    exit 1
fi

echo "📋 Migration details:"
echo "   File: $MIGRATION_FILE"
echo "   Database: $(echo $DATABASE_URL | sed 's/:[^:]*@/:***@/')"
echo ""

# Read the migration file and extract metadata
MIGRATION_NAME=$(basename "$MIGRATION_FILE" .sql)
MIGRATION_DESC=$(head -n 5 "$MIGRATION_FILE" | grep "Description:" | cut -d':' -f2- | xargs)
MIGRATION_DATE=$(head -n 5 "$MIGRATION_FILE" | grep "Created:" | cut -d':' -f2- | xargs)

echo "📝 Migration Info:"
echo "   Name: $MIGRATION_NAME"
echo "   Description: $MIGRATION_DESC"
echo "   Created: $MIGRATION_DATE"
echo ""

# Ask for confirmation
read -p "Do you want to apply this migration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration cancelled"
    exit 1
fi

echo "🔄 Applying migration..."

# Apply the migration using psql
if command -v psql &> /dev/null; then
    echo "Using local psql..."
    psql "$DATABASE_URL" -f "$MIGRATION_FILE"
else
    echo "Using Docker psql..."
    docker run --rm -i postgres:15-alpine psql "$DATABASE_URL" < "$MIGRATION_FILE"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration applied successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Verify tables in Neon dashboard"
    echo "  2. Start services: docker compose -f docker-compose.oracle.yml up -d"
    echo "  3. Test endpoints"
else
    echo ""
    echo "❌ Migration failed!"
    echo "Please check the error messages above and fix any issues."
    exit 1
fi
