#!/bin/bash

# Script to stamp all services to head since tables already exist
# This tells Alembic that the database is already at the latest migration state

echo "🚀 Stamping all services to head (tables already exist)..."

# List of all services
services=(
    "user-service"
    "vehicle-service" 
    "booking-service"
    "insurance-service"
    "expenses-service"
    "service-provider"
    "alert-service"
)

for service in "${services[@]}"; do
    echo "📝 Stamping $service to head..."
    docker compose -f docker-compose.oracle.yml run --rm $service alembic stamp head
    echo "  ✅ $service stamped successfully"
    echo ""
done

echo "🎉 All services stamped to head!"
echo ""
echo "📋 Next steps:"
echo "  1. Start the services:"
echo "     docker compose -f docker-compose.oracle.yml up -d"
echo ""
echo "  2. Check service health:"
echo "     docker compose -f docker-compose.oracle.yml ps"
echo ""
echo "  3. Test the gateway:"
echo "     curl http://localhost/health"
echo "     curl http://localhost/booking-health"
echo "     curl http://localhost/users/health"
