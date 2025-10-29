#!/bin/bash

# Development Environment Setup Script
# This script sets up the development environment with proper configuration

echo "🔧 Setting up Car Platform Development Environment..."

# Copy env.dev to .env for development (always replace for clean dev setup)
if [ -f env.dev ]; then
    echo "📝 Copying env.dev to .env for development..."
    cp env.dev .env
    echo "✅ .env file created from env.dev"
else
    echo "❌ env.dev file not found. Please ensure env.dev exists in the root directory."
    exit 1
fi

echo "ℹ️  Skipping creation of per-service .env files. Using single root .env for all services."

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Run: docker-compose up --build -d"
echo "2. Wait for services to start (about 2-3 minutes)"
echo "3. Check service status: docker-compose ps"
echo "4. View logs: docker-compose logs -f [service-name]"
echo ""
echo "🌐 Service URLs:"
echo "   Gateway: http://localhost:8000"
echo "   User Service: http://localhost:8001"
echo "   Vehicle Service: http://localhost:8002"
echo "   Service Provider: http://localhost:8003"
echo "   Booking Service: http://localhost:8004"
echo "   Insurance Service: http://localhost:8005"
echo "   Alert Service: http://localhost:8006"
echo "   Expenses Service: http://localhost:8007"
echo "   Social Service: http://localhost:8008"
echo "   PostgreSQL: localhost:5432"
echo "   Redis: localhost:6379"
echo ""
echo "📱 Social Hub Features:"
echo "   Posts & Stories: http://localhost:8000/social/"
echo "   API Documentation: http://localhost:8008/docs"
