#!/bin/bash

# GCP Always Free Tier Bootstrap Script
# This script sets up a Compute Engine VM for your car platform backend

set -e

echo "🚀 Starting GCP Always Free Tier setup for Car Platform Backend"

# Update system
echo "📦 Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
echo "🛠️ Installing additional tools..."
sudo apt-get install -y git curl wget unzip

# Install Caddy for automatic SSL
echo "🔒 Installing Caddy for automatic SSL..."
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install -y caddy

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/car-platform
sudo chown $USER:$USER /opt/car-platform

# Create systemd service for auto-start
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/car-platform.service > /dev/null <<EOF
[Unit]
Description=Car Platform Backend
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/car-platform
ExecStart=/usr/local/bin/docker-compose -f docker-compose.gcp.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.gcp.yml down
TimeoutStartSec=0
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable car-platform.service

# Create backup script
echo "💾 Creating backup script..."
sudo tee /opt/car-platform/backup.sh > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/opt/car-platform/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup environment file
cp .env $BACKUP_DIR/.env.$DATE

# Backup database (if using local postgres)
if docker-compose -f docker-compose.prod.yml ps postgres | grep -q "Up"; then
    docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/db_backup_$DATE.sql
fi

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name ".env.*" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/car-platform/backup.sh

# Create log rotation
echo "📋 Setting up log rotation..."
sudo tee /etc/logrotate.d/car-platform > /dev/null <<EOF
/opt/car-platform/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
EOF

echo "✅ Bootstrap completed!"
echo ""
echo "Next steps:"
echo "1. Clone your repository: git clone <your-repo-url> /opt/car-platform"
echo "2. Set up your .env file with external database URLs"
echo "3. Run: cd /opt/car-platform && docker-compose -f docker-compose.prod.yml up -d"
echo "4. Configure Caddy for your domain"
echo ""
echo "🔧 Useful commands:"
echo "  - Check status: sudo systemctl status car-platform"
echo "  - View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  - Backup: /opt/car-platform/backup.sh"
echo "  - Restart: sudo systemctl restart car-platform"
