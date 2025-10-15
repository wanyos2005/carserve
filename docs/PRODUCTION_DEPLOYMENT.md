# Production Deployment Guide

This guide provides comprehensive instructions for deploying the Car Platform backend services in a production environment.

## 🚀 Quick Start

1. **Prerequisites**
   - Docker and Docker Compose installed
   - WSL2 (for Windows users) or Linux environment
   - SSL certificates (or use self-signed for testing)

2. **Environment Setup**
   ```bash
   # Copy the environment template
   cp env.prod.example .env
   
   # Edit the .env file with your production values
   nano .env
   ```

3. **Deploy**
   ```bash
   # Make the deployment script executable
   chmod +x deploy.sh
   
   # Run the deployment
   ./deploy.sh
   ```

## 📋 Architecture Overview

The production setup includes:

- **7 Microservices**: user, vehicle, service-provider, booking, insurance, alert, expenses
- **API Gateway**: Nginx with SSL termination and load balancing
- **Database**: PostgreSQL with health checks and backups
- **Cache**: Redis for session management and caching
- **Message Queue**: Redis-based Celery for background tasks
- **Monitoring**: Prometheus + Grafana for metrics and dashboards

## 🔧 Configuration

### Environment Variables

Key environment variables to configure in `.env`:

```bash
# Database
DB_USER=car_platform_user
DB_PASSWORD=your_secure_password_here
DB_NAME=car_platform

# Email (Gmail example)
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password_here

# SMS (Africa's Talking)
AT_USERNAME=your_username
AT_API_KEY=your_api_key_here

# Security
JWT_SECRET_KEY=your_jwt_secret_key_here
GRAFANA_PASSWORD=your_grafana_password_here
```

### SSL Certificates

For production, replace the self-signed certificates:

```bash
# Place your SSL certificates in the ssl/ directory
ssl/
├── cert.pem    # Your SSL certificate
└── key.pem     # Your private key
```

## 🏗️ Production Optimizations

### Docker Optimizations
- **Multi-stage builds** for smaller image sizes
- **Non-root users** for security
- **Health checks** for all services
- **Resource limits** to prevent resource exhaustion
- **Alpine Linux** base images for minimal attack surface

### Nginx Optimizations
- **SSL/TLS termination** with modern cipher suites
- **Gzip compression** for better performance
- **Rate limiting** to prevent abuse
- **Security headers** (HSTS, XSS protection, etc.)
- **Connection pooling** with upstream keepalive

### Database Optimizations
- **Health checks** with proper timeouts
- **Connection pooling** configuration
- **Backup volume** mounting
- **Resource limits** for memory and CPU

## 📊 Monitoring & Logging

### Prometheus Metrics
- Service health and performance metrics
- Database connection metrics
- Redis cache metrics
- Nginx request metrics

### Grafana Dashboards
- Service overview dashboard
- Database performance dashboard
- API request metrics dashboard
- Error rate monitoring

### Access Monitoring
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/your_grafana_password)

## 🔒 Security Features

### Network Security
- **Internal network** isolation
- **SSL/TLS encryption** for all traffic
- **Rate limiting** on API endpoints
- **CORS** configuration for cross-origin requests

### Application Security
- **Non-root containers** for all services
- **Security headers** in Nginx
- **JWT token** authentication
- **Input validation** and sanitization

### Infrastructure Security
- **Resource limits** to prevent DoS
- **Health checks** for service monitoring
- **Restart policies** for high availability
- **Volume encryption** for sensitive data

## 🚦 Service Endpoints

| Service | Internal Port | External Access |
|---------|---------------|-----------------|
| API Gateway | 80/443 | https://yourdomain.com |
| User Service | 8001 | /users/ |
| Vehicle Service | 8002 | /vehicles |
| Service Provider | 8003 | /service-providers/ |
| Booking Service | 8004 | /bookings |
| Insurance Service | 8005 | /insurance/ |
| Alert Service | 8006 | /alerts/ |
| Expenses Service | 8007 | /expense/ |

## 🔄 Maintenance Operations

### Database Backups
```bash
# Create backup
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U $DB_USER $DB_NAME > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U $DB_USER $DB_NAME < backup_file.sql
```

### Service Updates
```bash
# Update a specific service
docker-compose -f docker-compose.prod.yml up --build -d service-name

# Update all services
docker-compose -f docker-compose.prod.yml up --build -d
```

### Log Management
```bash
# View logs for all services
docker-compose -f docker-compose.prod.yml logs -f

# View logs for specific service
docker-compose -f docker-compose.prod.yml logs -f service-name

# View last 100 lines
docker-compose -f docker-compose.prod.yml logs --tail=100 service-name
```

### Health Checks
```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# Check specific service health
curl -f https://yourdomain.com/health
```

## 🚨 Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   # Check logs
   docker-compose -f docker-compose.prod.yml logs service-name
   
   # Check resource usage
   docker stats
   ```

2. **Database connection issues**
   ```bash
   # Check database health
   docker-compose -f docker-compose.prod.yml exec postgres pg_isready -U $DB_USER
   
   # Check database logs
   docker-compose -f docker-compose.prod.yml logs postgres
   ```

3. **SSL certificate issues**
   ```bash
   # Verify certificate
   openssl x509 -in ssl/cert.pem -text -noout
   
   # Check certificate expiration
   openssl x509 -in ssl/cert.pem -dates -noout
   ```

### Performance Tuning

1. **Database Performance**
   - Monitor slow queries in PostgreSQL logs
   - Adjust connection pool settings
   - Consider read replicas for high traffic

2. **Application Performance**
   - Monitor memory usage with `docker stats`
   - Adjust worker counts in Dockerfiles
   - Enable Redis caching for frequently accessed data

3. **Nginx Performance**
   - Monitor upstream response times
   - Adjust worker processes and connections
   - Enable HTTP/2 for better performance

## 📈 Scaling Considerations

### Horizontal Scaling
- Use Docker Swarm or Kubernetes for multi-host deployment
- Implement load balancing across multiple service instances
- Use external Redis cluster for shared caching

### Vertical Scaling
- Increase resource limits in docker-compose.prod.yml
- Add more workers to services
- Upgrade to more powerful hardware

### Database Scaling
- Implement read replicas
- Use connection pooling (PgBouncer)
- Consider database sharding for very large datasets

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy to Production
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to production
        run: |
          scp -r . user@production-server:/opt/car-platform/
          ssh user@production-server "cd /opt/car-platform && ./deploy.sh"
```

## 📞 Support

For issues and questions:
1. Check the logs first: `docker-compose -f docker-compose.prod.yml logs`
2. Verify environment configuration
3. Check service health endpoints
4. Review this documentation

## 🎯 Next Steps

1. **Set up monitoring alerts** in Grafana
2. **Configure log aggregation** (ELK stack)
3. **Implement automated backups**
4. **Set up CI/CD pipeline**
5. **Configure load balancing** for high availability
6. **Implement blue-green deployments**
