#!/bin/bash

# Oracle Cloud Deployment Script for Car Platform
# Run this after setting up your ARM A1 instance and external databases

set -e

echo "🚀 Deploying Car Platform to Oracle Cloud"

# Check if we're in the right directory
if [ ! -f "docker-compose.oracle.yml" ]; then
    echo "❌ Error: docker-compose.oracle.yml not found. Please run this from your project root."
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found. Please create it first."
    exit 1
fi

# Create logs directory
mkdir -p logs

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.oracle.yml down || true

# Pull latest images
echo "📥 Pulling latest images..."
docker-compose -f docker-compose.oracle.yml pull

# Build custom images
echo "🔨 Building custom images..."
docker-compose -f docker-compose.oracle.yml build

# Start services
echo "🚀 Starting services..."
docker-compose -f docker-compose.oracle.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
services=("user-service" "vehicle-service" "service-provider" "booking-service" "insurance-service" "alert-service" "expenses-service")

for service in "${services[@]}"; do
    if docker-compose -f docker-compose.oracle.yml ps $service | grep -q "healthy\|Up"; then
        echo "✅ $service is running"
    else
        echo "❌ $service is not healthy"
        docker-compose -f docker-compose.oracle.yml logs --tail=20 $service
    fi
done

# Test gateway
echo "🌐 Testing gateway..."
if curl -sf http://localhost/health > /dev/null; then
    echo "✅ Gateway is responding"
else
    echo "❌ Gateway is not responding"
    docker-compose -f docker-compose.oracle.yml logs --tail=20 gateway
fi

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Service Status:"
docker-compose -f docker-compose.oracle.yml ps

echo ""
echo "🔗 Access URLs:"
echo "  - Gateway: http://$(curl -s ifconfig.me)/health"
echo "  - Prometheus: http://$(curl -s ifconfig.me):9090"
echo "  - Grafana: http://$(curl -s ifconfig.me):3000"
echo ""
echo "📝 Next steps:"
echo "  1. Configure your domain DNS to point to this server's IP"
echo "  2. Set up Caddy for automatic SSL"
echo "  3. Update your frontend to use the new API URL"
echo ""
echo "🖥️ System Resources:"
echo "  - CPU cores: $(nproc)"
echo "  - Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "  - Architecture: $(uname -m)"
