#!/bin/bash

set -e

echo "=========================================="
echo "Deploying to Kubernetes"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd k8s

# Create namespace
echo -e "\n${YELLOW}Creating namespace...${NC}"
kubectl apply -f namespace.yaml

# Create storage
echo -e "\n${YELLOW}Creating storage...${NC}"
kubectl apply -f efs-storage.yaml

# Create configmap and secret
echo -e "\n${YELLOW}Creating ConfigMap and Secret...${NC}"
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# Deploy backend
echo -e "\n${YELLOW}Deploying backend...${NC}"
kubectl apply -f backend-deployment.yaml

# Deploy frontend
echo -e "\n${YELLOW}Deploying frontend...${NC}"
kubectl apply -f frontend-deployment.yaml

# Create ingress
echo -e "\n${YELLOW}Creating ingress...${NC}"
kubectl apply -f ingress.yaml

# Wait for deployments
echo -e "\n${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/backend -n devops-final
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n devops-final

# Get status
echo -e "\n${GREEN}=========================================="
echo "Deployment completed!"
echo "==========================================${NC}"
echo ""
kubectl get all -n devops-final
echo ""
echo -e "${YELLOW}Getting Load Balancer URL (may take a few minutes)...${NC}"
kubectl get ingress app-ingress -n devops-final
