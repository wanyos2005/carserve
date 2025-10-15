# Environment Configuration Guide

This guide explains how to properly configure environment variables for the Car Platform microservices architecture.

## 🎯 **Single .env File Approach (Recommended)**

### **Why Single .env File?**

✅ **Centralized Management**: All configuration in one place  
✅ **Consistency**: Same values across all services  
✅ **Docker Compose Integration**: Automatic variable sharing  
✅ **Security**: Single point of control for secrets  
✅ **Maintenance**: Update once, affects all services  

### **File Structure**

```
c:\systemc\car\
├── .env                    # ← Single shared environment file
├── env.prod.example        # ← Template (keep this)
├── docker-compose.prod.yml # ← References .env
├── backend/
│   ├── user_service/       # ← No .env file here
│   ├── vehicle_service/    # ← No .env file here
│   ├── booking_service/    # ← No .env file here
│   └── ... (other services)
```

## 🚀 **Quick Setup**

### **1. Create Environment File**

```bash
# Copy template to .env
cp env.prod.example .env

# Or use the setup script
chmod +x setup-env.sh
./setup-env.sh
```

### **2. Configure Your Values**

Edit the `.env` file with your production values:

```bash
nano .env
```

### **3. Deploy**

```bash
./deploy.sh
```

## 🔧 **Environment Variables Explained**

### **Database Configuration**
```bash
DB_USER=car_platform_user          # Database username
DB_PASSWORD=your_secure_password   # Strong database password
DB_NAME=car_platform              # Database name
DB_HOST=postgres                  # Database host (Docker service name)
```

### **Redis Configuration**
```bash
REDIS_HOST=redis                  # Redis host (Docker service name)
REDIS_PORT=6379                   # Redis port
```

### **Email Configuration (Gmail Example)**
```bash
SMTP_HOST=smtp.gmail.com          # SMTP server
SMTP_PORT=587                     # SMTP port
SMTP_USERNAME=your_email@gmail.com # Your Gmail address
SMTP_PASSWORD=your_app_password   # Gmail App Password (not regular password)
SMTP_FROM_EMAIL=your_email@gmail.com
SMTP_FROM_NAME=DRIVEon.fit
SMTP_TLS=True
SMTP_SSL=False
```

### **SMS Configuration (Africa's Talking)**
```bash
SMS_PROVIDER=africastalking       # SMS provider
AT_USERNAME=your_username         # Africa's Talking username
AT_API_KEY=your_api_key_here      # Africa's Talking API key
AT_SENDER_ID=your_sender_id       # Sender ID
```

### **Security Configuration**
```bash
JWT_SECRET_KEY=your_jwt_secret_key_here  # Random secret for JWT tokens
JWT_ALGORITHM=HS256                      # JWT algorithm
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30       # Token expiration time
```

### **Monitoring Configuration**
```bash
GRAFANA_PASSWORD=your_grafana_password_here  # Grafana admin password
```

### **CORS Configuration**
```bash
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

## 🔒 **Security Best Practices**

### **1. Strong Passwords**
- Use complex passwords with mixed characters
- Different passwords for each service
- Consider using a password manager

### **2. Gmail App Passwords**
For Gmail SMTP, use App Passwords instead of your regular password:

1. Enable 2-Factor Authentication on Gmail
2. Go to Google Account Settings → Security
3. Generate an App Password for "Mail"
4. Use this App Password in `SMTP_PASSWORD`

### **3. JWT Secret Key**
Generate a strong random secret:

```bash
# Generate random JWT secret
openssl rand -base64 32
```

### **4. API Keys**
- Use environment-specific API keys
- Rotate keys regularly
- Monitor API key usage

## 🏗️ **How Docker Compose Uses .env**

The `docker-compose.prod.yml` file automatically loads variables from `.env`:

```yaml
services:
  user-service:
    environment:
      - DATABASE_URL=postgresql+psycopg2://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}
      - DB_HOST=postgres
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
```

Variables are substituted at runtime: `${DB_USER}` becomes `car_platform_user`.

## 🔄 **Environment-Specific Configurations**

### **Development vs Production**

You can use different `.env` files for different environments:

```bash
# Development
cp env.prod.example .env.dev

# Production
cp env.prod.example .env.prod

# Use specific environment
docker-compose --env-file .env.prod -f docker-compose.prod.yml up
```

### **Service-Specific Overrides**

If a service needs additional variables, add them to the main `.env` file:

```bash
# Add to .env
USER_SERVICE_SPECIFIC_VAR=value
VEHICLE_SERVICE_SPECIFIC_VAR=value
```

Then reference in `docker-compose.prod.yml`:

```yaml
services:
  user-service:
    environment:
      - USER_SERVICE_SPECIFIC_VAR=${USER_SERVICE_SPECIFIC_VAR}
```

## 🚨 **Common Issues and Solutions**

### **Issue 1: Variables Not Loading**
```bash
# Check if .env file exists
ls -la .env

# Check if variables are set
docker-compose config
```

### **Issue 2: Wrong Variable Names**
Ensure variable names match exactly between `.env` and `docker-compose.prod.yml`.

### **Issue 3: Special Characters in Passwords**
Escape special characters or use quotes:

```bash
# In .env file
DB_PASSWORD="my@password#123"
```

### **Issue 4: Missing Variables**
Check that all required variables are set:

```bash
# Validate environment
./health-check.sh
```

## 📋 **Environment Checklist**

### **Before Deployment**
- [ ] `.env` file created from template
- [ ] All passwords are strong and unique
- [ ] JWT secret key is random and secure
- [ ] API keys are valid and active
- [ ] Email credentials are working
- [ ] CORS origins are correct
- [ ] Database credentials are tested

### **After Deployment**
- [ ] All services start successfully
- [ ] Database connections work
- [ ] Email sending works
- [ ] SMS sending works
- [ ] Authentication works
- [ ] Monitoring is accessible

## 🔧 **Management Commands**

### **View Current Environment**
```bash
# Show all environment variables
docker-compose config

# Show specific service environment
docker-compose config user-service
```

### **Update Environment**
```bash
# Edit environment file
nano .env

# Restart services with new environment
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

### **Validate Environment**
```bash
# Check service health
./health-check.sh

# Check logs for environment issues
docker-compose -f docker-compose.prod.yml logs | grep -i "error\|config"
```

## 🎯 **Best Practices Summary**

1. **Single .env file** at root level
2. **Strong, unique passwords** for all services
3. **App-specific passwords** for email services
4. **Random JWT secrets** generated securely
5. **Environment-specific** configurations
6. **Regular rotation** of secrets and keys
7. **Validation** before deployment
8. **Monitoring** of configuration changes

This approach ensures consistency, security, and maintainability across all your microservices!
