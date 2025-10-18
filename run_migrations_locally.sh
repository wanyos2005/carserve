#!/bin/bash

# Run migrations outside Docker containers
# This requires Python and dependencies to be installed locally

echo "🚀 Running migrations outside Docker containers..."
echo "⚠️  WARNING: This requires Python and dependencies to be installed locally!"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed. Please install Python3 first."
    exit 1
fi

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip3 first."
    exit 1
fi

# List of services
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
    echo "📝 Processing $service..."
    
    # Get the correct service path
    if [ "$service" == "service-provider" ]; then
        service_path="backend/service_provider_service"
    else
        service_path="backend/${service//-/_}"
    fi
    
    echo "  🔹 Installing dependencies for $service..."
    cd "$service_path"
    
    # Install dependencies
    pip3 install -r requirements.txt
    
    echo "  🔹 Running Alembic migration for $service..."
    
    # Run migration
    alembic upgrade head
    
    echo "  ✅ $service migration completed"
    echo ""
    
    # Go back to root directory
    cd - > /dev/null
done

echo "🎉 All migrations completed successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Start the services:"
echo "     docker compose -f docker-compose.oracle.yml up -d"
echo ""
echo "  2. Test the services:"
echo "     curl http://localhost/booking-health"
echo "     curl http://localhost/users/health"
echo "     curl http://localhost/vehicles/health"
