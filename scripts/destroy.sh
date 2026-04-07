#!/bin/bash

set -e

echo "=========================================="
echo "Destroying Infrastructure"
echo "=========================================="

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}WARNING: This will destroy all infrastructure!${NC}"
echo -e "${YELLOW}Are you sure? (type 'yes' to confirm)${NC}"
read -r response

if [ "$response" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

# Delete K8s resources first
echo -e "\n${YELLOW}Deleting Kubernetes resources...${NC}"
kubectl delete namespace devops-final --ignore-not-found=true

# Wait for namespace deletion
echo -e "${YELLOW}Waiting for namespace deletion...${NC}"
kubectl wait --for=delete namespace/devops-final --timeout=300s || true

# Destroy Terraform infrastructure
echo -e "\n${YELLOW}Destroying Terraform infrastructure...${NC}"
cd terraform
terraform destroy -auto-approve

echo -e "\n${RED}All infrastructure destroyed${NC}"
