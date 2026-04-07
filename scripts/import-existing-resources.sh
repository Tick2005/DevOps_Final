#!/bin/bash

set -e

echo "=========================================="
echo "Importing Existing Resources to Terraform State"
echo "=========================================="

cd terraform

# Import EFS
echo "Importing EFS file system..."
terraform import aws_efs_file_system.main fs-0cba603e966ab48c2 2>/dev/null || echo "EFS already in state or not found"

# Import VPC
echo "Importing VPC..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=devops-final-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
if [ "$VPC_ID" != "None" ] && [ ! -z "$VPC_ID" ]; then
    terraform import 'module.vpc.aws_vpc.this[0]' $VPC_ID 2>/dev/null || echo "VPC already in state"
fi

# Import CloudWatch Log Group
echo "Importing CloudWatch log group..."
terraform import 'module.eks.aws_cloudwatch_log_group.this[0]' /aws/eks/devops-final-eks/cluster 2>/dev/null || echo "Log group already in state"

# Import KMS Alias
echo "Importing KMS alias..."
terraform import 'module.eks.module.kms.aws_kms_alias.this["cluster"]' alias/eks/devops-final-eks 2>/dev/null || echo "KMS alias already in state"

echo ""
echo "=========================================="
echo "Import complete! Now run: terraform apply"
echo "=========================================="
