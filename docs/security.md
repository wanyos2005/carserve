# Security Configuration Guide

This document outlines the security measures implemented in the production deployment.

## 🔒 Security Features Implemented

### 1. Container Security
- **Non-root users**: All containers run as non-root users (`appuser`)
- **Minimal base images**: Using Alpine Linux for smaller attack surface
- **Multi-stage builds**: Separate build and runtime environments
- **Resource limits**: CPU and memory limits to prevent resource exhaustion

### 2. Network Security
- **Internal network isolation**: Services communicate through internal Docker network
- **SSL/TLS termination**: All external traffic encrypted with HTTPS
- **Rate limiting**: API endpoints protected against abuse
- **CORS configuration**: Proper cross-origin resource sharing setup

### 3. Application Security
- **JWT authentication**: Secure token-based authentication
- **Input validation**: Pydantic models for request validation
- **SQL injection prevention**: SQLAlchemy ORM with parameterized queries
- **Environment variable protection**: Sensitive data in environment variables

### 4. Infrastructure Security
- **Health checks**: All services have health monitoring
- **Restart policies**: Automatic restart on failure
- **Volume encryption**: Database and cache data encrypted at rest
- **Security headers**: HSTS, XSS protection, content type sniffing prevention

## 🛡️ Security Headers

The Nginx configuration includes the following security headers:

```nginx
# Security headers
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

## 🔐 SSL/TLS Configuration

### Modern Cipher Suites
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
```

### SSL Session Management
```nginx
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
```

## 🚦 Rate Limiting

### API Rate Limits
```nginx
# General API rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

# Authentication endpoints (stricter)
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/s;
```

## 🔑 Environment Variables Security

### Required Environment Variables
```bash
# Database
DB_USER=car_platform_user
DB_PASSWORD=your_secure_password_here

# JWT Security
JWT_SECRET_KEY=your_jwt_secret_key_here
JWT_ALGORITHM=HS256

# Email (use app passwords)
SMTP_PASSWORD=your_app_password_here

# SMS API
AT_API_KEY=your_api_key_here

# Monitoring
GRAFANA_PASSWORD=your_grafana_password_here
```

## 🛠️ Security Best Practices

### 1. Password Security
- Use strong, unique passwords for all services
- Enable 2FA where possible (Gmail, monitoring tools)
- Use app-specific passwords for email services
- Rotate passwords regularly

### 2. SSL Certificate Management
- Use Let's Encrypt for production SSL certificates
- Monitor certificate expiration
- Implement certificate auto-renewal
- Use strong private keys (2048+ bits)

### 3. Database Security
- Use strong database passwords
- Limit database user permissions
- Enable SSL for database connections
- Regular security updates

### 4. Monitoring and Logging
- Monitor failed authentication attempts
- Log all security-relevant events
- Set up alerts for suspicious activity
- Regular security audits

## 🔍 Security Monitoring

### Prometheus Metrics
- Failed authentication attempts
- Rate limit violations
- SSL certificate expiration
- Service health status

### Grafana Dashboards
- Security overview dashboard
- Authentication metrics
- Rate limiting statistics
- SSL certificate monitoring

## 🚨 Incident Response

### Security Incident Checklist
1. **Identify**: Determine the scope and impact
2. **Contain**: Isolate affected systems
3. **Eradicate**: Remove the threat
4. **Recover**: Restore normal operations
5. **Learn**: Document lessons learned

### Emergency Procedures
```bash
# Stop all services
docker-compose -f docker-compose.prod.yml down

# Check logs for suspicious activity
docker-compose -f docker-compose.prod.yml logs | grep -i "error\|fail\|unauthorized"

# Update all services
./update.sh --all --force

# Run health check
./health-check.sh
```

## 🔄 Security Updates

### Regular Security Tasks
- **Weekly**: Review logs for suspicious activity
- **Monthly**: Update dependencies and base images
- **Quarterly**: Security audit and penetration testing
- **Annually**: Review and update security policies

### Update Dependencies
```bash
# Update Python dependencies
pip install --upgrade -r requirements.txt

# Update Docker images
docker-compose -f docker-compose.prod.yml pull

# Rebuild services
./update.sh --all
```

## 📋 Security Checklist

### Pre-deployment
- [ ] All passwords are strong and unique
- [ ] SSL certificates are valid and not expired
- [ ] Environment variables are properly set
- [ ] Security headers are configured
- [ ] Rate limiting is enabled
- [ ] Health checks are working

### Post-deployment
- [ ] All services are running and healthy
- [ ] SSL/TLS is working correctly
- [ ] Authentication is functioning
- [ ] Monitoring is active
- [ ] Logs are being collected
- [ ] Backups are working

### Ongoing
- [ ] Regular security updates
- [ ] Monitor for vulnerabilities
- [ ] Review access logs
- [ ] Test backup and recovery
- [ ] Update security documentation

## 🆘 Security Contacts

### Emergency Contacts
- **System Administrator**: [Your contact]
- **Security Team**: [Security contact]
- **Hosting Provider**: [Provider support]

### Useful Commands
```bash
# Check SSL certificate
openssl x509 -in ssl/cert.pem -text -noout

# Test SSL configuration
nmap --script ssl-enum-ciphers -p 443 yourdomain.com

# Check for vulnerabilities
docker scout cves

# Monitor network connections
netstat -tulpn | grep :443
```

## 📚 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Nginx Security Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)
