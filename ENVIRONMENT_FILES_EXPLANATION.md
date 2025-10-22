# Environment Files Explanation

This document explains the purpose and usage of different environment files in the Car Platform project.

## 📁 File Structure

```
car/
├── env.dev                    # Development environment template
├── env.prod                   # Production environment template
├── .env                       # Active environment file (created by scripts)
├── env.oracle.example         # Legacy production environment template
├── setup-dev-env.sh          # Development setup script
├── setup-prod-env.sh         # Production setup script
├── switch-env.sh             # Environment switcher script
└── backend/
    ├── user_service/
    │   └── .env              # Service-specific environment file
    ├── vehicle_service/
    │   └── .env              # Service-specific environment file
    └── ... (other services)
```

## 🔧 File Purposes

### 1. `env.dev` - Development Environment Template
- **Purpose**: Template file containing development environment variables
- **Usage**: Source file for development setup
- **Content**: Internal database URLs, development-specific settings
- **When to edit**: When you need to change development environment variables

### 2. `.env` - Active Environment File
- **Purpose**: The actual environment file used by Docker Compose and services
- **Usage**: Created by setup scripts from templates
- **Content**: Copied from `env.dev` (development) or manually created (production)
- **When to edit**: Usually managed by scripts, but can be edited directly

### 3. `env.prod` - Production Environment Template
- **Purpose**: Template file containing production environment variables
- **Usage**: Source file for production setup
- **Content**: External database URLs, production-specific settings
- **When to edit**: When you need to change production environment variables

### 4. `env.oracle.example` - Legacy Production Environment Template
- **Purpose**: Legacy template for production environment variables
- **Usage**: Reference for production setup (deprecated)
- **Content**: External database URLs, production-specific settings
- **When to edit**: Not recommended, use `env.prod` instead

### 5. Service-specific `.env` files
- **Purpose**: Individual environment files for each microservice
- **Usage**: Created by setup scripts for each service
- **Content**: Service-specific environment variables
- **When to edit**: Usually managed by scripts

## 🚀 How Setup Scripts Work

### Development Setup (`setup-dev-env.sh`)

1. **Copies `env.dev` to `.env`** (always replaces):
   ```bash
   cp env.dev .env
   ```

2. **Creates individual service `.env` files**:
   ```bash
   # For each service (user_service, vehicle_service, etc.)
   backend/user_service/.env
   backend/vehicle_service/.env
   # ... etc
   ```

3. **Result**: All services have their own `.env` files with development settings

### Production Setup (`setup-prod-env.sh`)

1. **Copies `env.prod` to `.env`** (always replaces):
   ```bash
   cp env.prod .env
   ```

2. **Creates individual service `.env` files** with production settings

3. **Result**: All services have their own `.env` files with production settings

### Environment Switcher (`switch-env.sh`)

1. **Interactive script** that helps you switch between environments
2. **Calls the appropriate setup script** based on your choice
3. **Provides confirmation prompts** before making changes

## 🔄 Workflow

### Development Workflow

1. **Edit `env.dev`** with your development settings
2. **Run `./setup-dev-env.sh`** to create all environment files
3. **Run `docker-compose up -d`** to start development environment

### Production Workflow

1. **Edit `env.prod`** with your production settings
2. **Run `./setup-prod-env.sh`** to create all environment files
3. **Edit `.env`** with your actual production values (database URLs, secrets, etc.)
4. **Deploy** using `docker-compose -f docker-compose.oracle.yml`

### Environment Switching Workflow

1. **Use the switcher script**:
   ```bash
   ./switch-env.sh dev   # Switch to development
   ./switch-env.sh prod  # Switch to production
   ```
2. **Follow the prompts** to confirm the switch
3. **Start the appropriate services** based on the environment

## 📝 Environment Variable Hierarchy

1. **Docker Compose environment variables** (highest priority)
2. **Service-specific `.env` files**
3. **Root `.env` file**
4. **Default values in code** (lowest priority)

## 🎯 Key Benefits

### Development
- **Fast setup**: One script creates all environment files
- **Consistent configuration**: All services use the same development settings
- **Easy to modify**: Edit `env.dev` and re-run setup script

### Production
- **Secure**: Production values are in `.env` (not committed to git)
- **Flexible**: Each service can have different settings if needed
- **Automated**: Setup script handles all service configurations

## 🔍 Example Usage

### Setting up Development Environment

```bash
# 1. Edit development settings
vim env.dev

# 2. Run setup script
./setup-dev-env.sh

# 3. Start services
docker-compose up -d
```

### Setting up Production Environment

```bash
# 1. Create production .env file
cp env.oracle.example .env
vim .env  # Edit with production values

# 2. Run setup script
./setup-prod-env.sh

# 3. Deploy
docker-compose -f docker-compose.oracle.yml up -d
```

## ⚠️ Important Notes

1. **Never commit `.env` files** to git (they contain sensitive information)
2. **Always use templates** (`env.dev`, `env.oracle.example`) as source files
3. **Run setup scripts** after making changes to templates
4. **Check service logs** if environment variables aren't loading correctly

## 🐛 Troubleshooting

### Environment variables not loading
- Check if `.env` files exist in service directories
- Verify environment variable names match configuration
- Check Docker Compose logs for environment variable errors

### Services not starting
- Ensure all required environment variables are set
- Check if database URLs are correct
- Verify service dependencies are healthy
