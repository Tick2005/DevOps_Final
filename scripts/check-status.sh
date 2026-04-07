#!/bin/bash

echo "=========================================="
echo "Checking Infrastructure Status"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check EKS Cluster
echo -e "\n${YELLOW}EKS Cluster Status:${NC}"
aws eks describe-cluster --name devops-final-eks --query 'cluster.status' --output text 2>/dev/null || echo "Not found"

# Check EKS Node Groups
echo -e "\n${YELLOW}EKS Node Groups:${NC}"
aws eks list-nodegroups --cluster-name devops-final-eks --output table 2>/dev/null || echo "Not found"

# Check RDS Instance
echo -e "\n${YELLOW}RDS Instance Status:${NC}"
aws rds describe-db-instances --db-instance-identifier devops-final-postgres --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]' --output table 2>/dev/null || echo "Not found or creating..."

# Check EFS
echo -e "\n${YELLOW}EFS File System:${NC}"
aws efs describe-file-systems --file-system-id fs-0cba603e966ab48c2 --query 'FileSystems[0].[LifeCycleState,FileSystemId]' --output table 2>/dev/null || echo "Not found"

# Check VPCs
echo -e "\n${YELLOW}VPCs:${NC}"
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],State]' --output table

echo -e "\n${GREEN}=========================================="
echo "Check complete!"
echo "==========================================${NC}"
