#!/bin/bash

set -e

echo "=========================================="
echo "Fixing Terraform State Issues"
echo "=========================================="

cd terraform

# Step 1: Kill any running terraform processes
echo "Step 1: Checking for running terraform processes..."
if pgrep -x "terraform" > /dev/null; then
    echo "Found running terraform process. Killing..."
    pkill -9 terraform || true
    sleep 2
fi

# Step 2: Remove lock file if exists
echo "Step 2: Removing lock file..."
if [ -f ".terraform.tfstate.lock.info" ]; then
    rm -f .terraform.tfstate.lock.info
    echo "Lock file removed"
fi

# Step 3: Refresh state
echo "Step 3: Refreshing terraform state..."
terraform refresh -lock=false || true

# Step 4: Import existing resources
echo "Step 4: Importing existing resources..."

# Import EFS
echo "  - Importing EFS..."
terraform import -lock=false aws_efs_file_system.main fs-0cba603e966ab48c2 2>/dev/null || echo "    Already in state or not found"

# Import VPC
echo "  - Importing VPC..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=devops-final-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    terraform import -lock=false 'module.vpc.aws_vpc.this[0]' $VPC_ID 2>/dev/null || echo "    Already in state"
else
    echo "    VPC not found, will be created"
fi

# Import CloudWatch Log Group
echo "  - Importing CloudWatch log group..."
terraform import -lock=false 'module.eks.aws_cloudwatch_log_group.this[0]' /aws/eks/devops-final-eks/cluster 2>/dev/null || echo "    Already in state"

# Import KMS Alias
echo "  - Importing KMS alias..."
terraform import -lock=false 'module.eks.module.kms.aws_kms_alias.this["cluster"]' alias/eks/devops-final-eks 2>/dev/null || echo "    Already in state"

echo ""
echo "=========================================="
echo "Fix complete!"
echo "=========================================="
echo ""
echo "Now you can run:"
echo "  terraform plan"
echo "  terraform apply"
