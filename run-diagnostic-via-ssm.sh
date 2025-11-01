#!/bin/bash

# Quick script to upload and run diagnostic script via AWS SSM
# Usage: ./run-diagnostic-via-ssm.sh

INSTANCE_ID="i-0ec6c2b1be34e3c5f"
AWS_REGION="${AWS_REGION:-us-east-1}"  # Change if needed

echo "Uploading diagnostic script to EC2..."
aws ssm send-command \
  --targets "Key=InstanceIds,Values=$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[
    'cat > /tmp/diagnose-aws-connection.sh << \"DIAGEOF\"
$(cat diagnose-aws-connection.sh)
DIAGEOF
',
    'chmod +x /tmp/diagnose-aws-connection.sh',
    '/tmp/diagnose-aws-connection.sh'
  ]" \
  --region $AWS_REGION \
  --query "Command.CommandId" \
  --output text

echo ""
echo "Check the command output in AWS Console → Systems Manager → Run Command"
echo "Or run: aws ssm list-command-invocations --command-id <CommandId> --details"

