#!/bin/bash

# Quick script to update code on EC2 VM via SSH
# Usage: ./QUICK_UPDATE_VM.sh

echo "Updating code on EC2 VM..."

# Option 1: Using SSH (if you have SSH access)
# Replace with your actual SSH command
# ssh -i your-key.pem ubuntu@16.16.124.14 << 'EOF'
#   cd /home/ubuntu/carserve
#   git pull origin main
#   chmod +x init-all-schemas-and-migrations-docker-compose.sh
#   echo "Code updated successfully!"
# EOF

# Option 2: Using AWS SSM Session Manager (if SSM is configured)
# aws ssm send-command \
#   --targets "Key=InstanceIds,Values=i-0ec6c2b1be34e3c5f" \
#   --document-name "AWS-RunShellScript" \
#   --parameters "commands=[
#     'cd /home/ubuntu/carserve',
#     'git pull origin main',
#     'chmod +x init-all-schemas-and-migrations-docker-compose.sh',
#     'echo \"Code updated successfully!\"'
#   ]" \
#   --region us-east-1

echo "Choose one of the methods above to update your VM code."

