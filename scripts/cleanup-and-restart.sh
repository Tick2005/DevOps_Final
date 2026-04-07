#!/bin/bash

set -e

echo "=========================================="
echo "Cleanup and Restart Terraform"
echo "=========================================="

cd terraform

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}WARNING: This will clean up terraform state and restart!${NC}"
echo -e "${YELLOW}Are you sure? (type 'yes' to confirm)${NC}"
read -r response

if [ "$response" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

# Step 1: Kill terraform processes
echo -e "\n${YELLOW}Step 1: Killing terraform processes...${NC}"
pkill -9 terraform 2>/dev/null || echo "No terraform process found"
sleep 2

# Step 2: Remove lock
echo -e "\n${YELLOW}Step 2: Removing lock files...${NC}"
rm -f .terraform.tfstate.lock.info
rm -f .terraform.lock.hcl

# Step 3: Backup current state
echo -e "\n${YELLOW}Step 3: Backing up current state...${NC}"
if [ -f "terraform.tfstate" ]; then
    cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
    echo "State backed up"
fi

# Step 4: Re-initialize
echo -e "\n${YELLOW}Step 4: Re-initializing terraform...${NC}"
terraform init -upgrade

# Step 5: Import existing resources
echo -e "\n${YELLOW}Step 5: Importing existing resources...${NC}"

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=devops-final-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    echo "Found existing VPC: $VPC_ID"
    
    # Import VPC
    terraform import 'module.vpc.aws_vpc.this[0]' $VPC_ID 2>/dev/null || echo "VPC already in state"
    
    # Import other VPC resources
    echo "Importing VPC subnets..."
    for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text); do
        echo "  Found subnet: $subnet"
    done
fi

# Import EFS
echo "Importing EFS..."
terraform import aws_efs_file_system.main fs-0cba603e966ab48c2 2>/dev/null || echo "EFS already in state"

# Import CloudWatch
echo "Importing CloudWatch log group..."
terraform import 'module.eks.aws_cloudwatch_log_group.this[0]' /aws/eks/devops-final-eks/cluster 2>/dev/null || echo "Already in state"

# Import KMS
echo "Importing KMS alias..."
terraform import 'module.eks.module.kms.aws_kms_alias.this["cluster"]' alias/eks/devops-final-eks 2>/dev/null || echo "Already in state"

echo -e "\n${GREEN}=========================================="
echo "Cleanup complete!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. terraform plan"
echo "2. terraform apply"
