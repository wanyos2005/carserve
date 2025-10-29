#!/bin/bash

# Production Environment Setup Script
# This script sets up the production environment with external databases

echo "🚀 Setting up Car Platform Production Environment..."

# Copy env.prod to .env for production (always replace for clean prod setup)
if [ -f env.prod ]; then
    echo "📝 Copying env.prod to .env for production..."
    cp env.prod .env
    echo "✅ .env file created from env.prod"
    echo "⚠️  IMPORTANT: Please edit .env file with your actual production values before deploying!"
else
    echo "❌ env.prod file not found. Please ensure env.prod exists in the root directory."
    exit 1
fi

echo "ℹ️  Skipping creation of per-service .env files. Using single root .env for all services."

echo ""
echo "🎉 Production environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Ensure your .env file has all required production values"
echo "2. Run: docker-compose -f docker-compose.oracle.yml up -d"
echo "3. Or use your CI/CD pipeline to deploy"
echo ""
echo "⚠️  Important Notes:"
echo "   - Production uses external databases (Neon PostgreSQL + Upstash Redis)"
echo "   - Make sure your external database credentials are correct"
echo "   - Update ALLOWED_ORIGINS with your production domain"
echo "   - Use strong JWT_SECRET_KEY for production"
echo "   - Social service uses Cloudflare R2 for media storage (configured)"
echo "   - Set up content moderation API key for social content filtering"
echo ""
echo "🌐 Social Hub Production URLs:"
echo "   Social API: https://yourdomain.com/social/"
echo "   Social Docs: https://yourdomain.com:8008/docs"
