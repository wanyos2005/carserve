#!/bin/bash

# Development Environment Startup Script
# This script starts the development environment with internal databases

echo "🚀 Starting Car Platform Development Environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Clean up any existing containers and volumes
echo "🧹 Cleaning up existing containers and volumes..."
docker-compose down -v

# Remove any orphaned containers
docker-compose down --remove-orphans

# Start the development environment
echo "🏗️  Building and starting services..."
docker-compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check service status
echo "📊 Checking service status..."
docker-compose ps

# Show logs for any failed services
echo "📋 Checking for any startup issues..."
docker-compose logs --tail=20

echo "✅ Development environment started!"
echo "🌐 Gateway: http://localhost:8000"
echo "👤 User Service: http://localhost:8001"
echo "🚗 Vehicle Service: http://localhost:8002"
echo "🔧 Service Provider: http://localhost:8003"
echo "📅 Booking Service: http://localhost:8004"
echo "🛡️  Insurance Service: http://localhost:8005"
echo "🔔 Alert Service: http://localhost:8006"
echo "💰 Expenses Service: http://localhost:8007"
echo "🗄️  PostgreSQL: localhost:5432"
echo "📦 Redis: localhost:6379"

echo ""
echo "📝 To view logs: docker-compose logs -f [service-name]"
echo "🛑 To stop: docker-compose down"
echo "🧹 To clean up: docker-compose down -v"
