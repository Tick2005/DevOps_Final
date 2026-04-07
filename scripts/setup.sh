#!/bin/bash

set -e

echo "=========================================="
echo "DevOps Final - Infrastructure Setup"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is required but not installed.${NC}" >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI is required but not installed.${NC}" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required but not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✓ All prerequisites installed${NC}"

# Check AWS credentials
echo -e "\n${YELLOW}Checking AWS credentials...${NC}"
aws sts get-caller-identity >/dev/null 2>&1 || { echo -e "${RED}AWS credentials not configured${NC}" >&2; exit 1; }
echo -e "${GREEN}✓ AWS credentials configured${NC}"

# Initialize Terraform
echo -e "\n${YELLOW}Initializing Terraform...${NC}"
cd terraform
terraform init

# Create terraform.tfvars if not exists
if [ ! -f terraform.tfvars ]; then
    echo -e "${YELLOW}Creating terraform.tfvars from example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${RED}Please edit terraform.tfvars with your values before continuing${NC}"
    exit 1
fi

# Plan
echo -e "\n${YELLOW}Planning infrastructure...${NC}"
terraform plan -out=tfplan

# Apply
echo -e "\n${YELLOW}Do you want to apply this plan? (yes/no)${NC}"
read -r response
if [ "$response" = "yes" ]; then
    terraform apply tfplan
    echo -e "${GREEN}✓ Infrastructure created successfully${NC}"
else
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Get outputs
echo -e "\n${YELLOW}Getting infrastructure outputs...${NC}"
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
AWS_REGION=$(terraform output -raw aws_region || echo "ap-southeast-1")
EFS_ID=$(terraform output -raw efs_id)
DOCDB_ENDPOINT=$(terraform output -raw documentdb_endpoint)

# Configure kubectl
echo -e "\n${YELLOW}Configuring kubectl...${NC}"
aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
echo -e "${GREEN}✓ kubectl configured${NC}"

# Update K8s manifests with actual values
echo -e "\n${YELLOW}Updating Kubernetes manifests...${NC}"
cd ../k8s

# Update EFS ID in storage manifest
sed -i.bak "s/fs-XXXXXXXXX/$EFS_ID/g" efs-storage.yaml && rm efs-storage.yaml.bak

# Update DocumentDB endpoint in secret
echo -e "${YELLOW}Please update k8s/secret.yaml with DocumentDB endpoint: $DOCDB_ENDPOINT${NC}"

echo -e "\n${GREEN}=========================================="
echo "Setup completed successfully!"
echo "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Update k8s/secret.yaml with DocumentDB credentials"
echo "2. Update k8s/*-deployment.yaml with your Docker Hub username"
echo "3. Run: ./scripts/deploy-k8s.sh"
echo ""
echo "EKS Cluster: $EKS_CLUSTER_NAME"
echo "DocumentDB Endpoint: $DOCDB_ENDPOINT"
echo "EFS ID: $EFS_ID"
