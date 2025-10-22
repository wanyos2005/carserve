# Car Platform Development Setup

This document explains how to set up the Car Platform for both development and production environments.

## 🚀 Quick Start

### Development Environment (Local with Internal Databases)

1. **Setup Development Environment:**
   ```bash
   # Make scripts executable (Linux/Mac)
   chmod +x setup-dev-env.sh dev-start.sh
   
   # Setup development environment
   ./setup-dev-env.sh
   ```

2. **Start Development Services:**
   ```bash
   # Start all services with internal databases
   docker-compose up --build -d
   
   # Or use the development script
   ./dev-start.sh
   ```

3. **Check Service Status:**
   ```bash
   docker-compose ps
   ```

### Production Environment (External Databases)

1. **Setup Production Environment:**
   ```bash
   # Make script executable (Linux/Mac)
   chmod +x setup-prod-env.sh
   
   # Setup production environment
   ./setup-prod-env.sh
   ```

2. **Deploy to Production:**
   ```bash
   # Use production docker-compose file
   docker-compose -f docker-compose.oracle.yml up -d
   ```

## 📁 Environment Configuration

### Development Environment

- **Database**: Internal PostgreSQL container
- **Redis**: Internal Redis container
- **Configuration**: Uses `docker-compose.yml` with internal database URLs
- **Environment Variables**: Set in individual service `.env` files

### Production Environment

- **Database**: External Neon PostgreSQL
- **Redis**: External Upstash Redis
- **Configuration**: Uses `docker-compose.oracle.yml` with external database URLs
- **Environment Variables**: Set in main `.env` file and referenced by services

## 🔧 Service Configuration

Each microservice has been configured to:

1. **Use DATABASE_URL from environment variables** (for external databases)
2. **Fallback to individual DB components** (for local development)
3. **Support both development and production configurations**

### Service URLs

| Service | Development URL | Production URL |
|---------|----------------|----------------|
| Gateway | http://localhost:8000 | https://yourdomain.com |
| User Service | http://localhost:8001 | Internal |
| Vehicle Service | http://localhost:8002 | Internal |
| Service Provider | http://localhost:8003 | Internal |
| Booking Service | http://localhost:8004 | Internal |
| Insurance Service | http://localhost:8005 | Internal |
| Alert Service | http://localhost:8006 | Internal |
| Expenses Service | http://localhost:8007 | Internal |

## 🗄️ Database Configuration

### Development
- **PostgreSQL**: `postgresql://AdminDb:Ngojakwanza@postgres:5432/car_platform`
- **Redis**: `redis://redis:6379`

### Production
- **PostgreSQL**: Uses `NEON_DATABASE_URL` from environment
- **Redis**: Uses `UPSTASH_REDIS_URL` from environment

## 🔄 CI/CD Pipeline

The CI/CD pipeline (`build-and-deploy.yml`) is configured to:

1. **Build Docker images** for all services
2. **Push to GitHub Container Registry**
3. **Deploy to Oracle Cloud** using `docker-compose.oracle.yml`
4. **Use external databases** for production

## 🛠️ Development Workflow

1. **Make changes** to your code
2. **Test locally** using development environment
3. **Commit and push** to GitHub
4. **CI/CD automatically deploys** to production

## 📝 Environment Variables

### Required for Development
- `DATABASE_URL` (or individual DB components)
- `REDIS_URL`
- `SECRET_KEY`
- `ALLOWED_ORIGINS`

### Required for Production
- `NEON_DATABASE_URL`
- `UPSTASH_REDIS_URL`
- `JWT_SECRET_KEY`
- `ALLOWED_ORIGINS`
- Email and SMS configuration

## 🐛 Troubleshooting

### Common Issues

1. **PostgreSQL connection failed:**
   - Check if postgres container is running: `docker-compose ps`
   - Verify database credentials in environment variables

2. **Services not starting:**
   - Check logs: `docker-compose logs [service-name]`
   - Ensure all dependencies are healthy

3. **Environment variables not loading:**
   - Verify `.env` files exist in each service directory
   - Check environment variable names match configuration

### Useful Commands

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f user-service

# Restart a specific service
docker-compose restart user-service

# Rebuild and restart all services
docker-compose up --build -d

# Clean up everything
docker-compose down -v
```

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
