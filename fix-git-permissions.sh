#!/bin/bash

# Script to fix git permissions and pull latest code
# Run this on your EC2 instance

echo "Fixing git permissions..."

# Navigate to project directory
cd /home/ubuntu/carserve || exit 1

# Fix ownership of git directory
sudo chown -R ubuntu:ubuntu .git
sudo chown -R ubuntu:ubuntu .

# Fix git directory permissions
chmod -R u+rw .git
chmod -R u+rw .

echo "Git permissions fixed!"
echo ""
echo "Now you can run:"
echo "  git pull origin main"
echo ""
echo "Or if you have local changes you want to discard:"
echo "  git reset --hard origin/main"
echo "  git pull origin main"

