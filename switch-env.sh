#!/bin/bash

# Environment Switcher Script
# This script helps you switch between development and production environments

if [ $# -eq 0 ]; then
    echo "🔄 Car Platform Environment Switcher"
    echo ""
    echo "Usage: $0 [dev|prod]"
    echo ""
    echo "Commands:"
    echo "  dev   - Switch to development environment (internal databases)"
    echo "  prod  - Switch to production environment (external databases)"
    echo ""
    echo "Examples:"
    echo "  $0 dev   # Switch to development"
    echo "  $0 prod  # Switch to production"
    exit 1
fi

ENVIRONMENT=$1

case $ENVIRONMENT in
    "dev"|"development")
        echo "🔧 Switching to Development Environment..."
        echo "📝 This will:"
        echo "   - Copy env.dev to .env"
        echo "   - Create development .env files for all services"
        echo "   - Use internal PostgreSQL and Redis"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./setup-dev-env.sh
            echo ""
            echo "✅ Switched to development environment!"
            echo "🚀 Run: docker-compose up -d"
        else
            echo "❌ Cancelled"
        fi
        ;;
    "prod"|"production")
        echo "🚀 Switching to Production Environment..."
        echo "📝 This will:"
        echo "   - Copy env.prod to .env"
        echo "   - Create production .env files for all services"
        echo "   - Use external PostgreSQL and Redis"
        echo ""
        echo "⚠️  WARNING: Make sure to edit .env with your actual production values!"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./setup-prod-env.sh
            echo ""
            echo "✅ Switched to production environment!"
            echo "⚠️  IMPORTANT: Edit .env file with your actual production values!"
            echo "🚀 Run: docker-compose -f docker-compose.oracle.yml up -d"
        else
            echo "❌ Cancelled"
        fi
        ;;
    *)
        echo "❌ Invalid environment: $ENVIRONMENT"
        echo "Valid options: dev, development, prod, production"
        exit 1
        ;;
esac
