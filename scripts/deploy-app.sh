#!/bin/bash
set -e

echo "=== StartupX Application Deployment Script ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Please install kubectl first."
    exit 1
fi

echo -e "${GREEN}Step 1: Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml

echo -e "${GREEN}Step 2: Applying ConfigMap...${NC}"
kubectl apply -f k8s/configmap.yaml

echo -e "${GREEN}Step 3: Creating secrets...${NC}"
if [ ! -f k8s/secret.yaml ]; then
    echo "Creating secret.yaml from template..."
    cp k8s/secret.yaml.template k8s/secret.yaml
    echo -e "${YELLOW}WARNING: Using default secrets. Please update k8s/secret.yaml with secure values!${NC}"
fi
kubectl apply -f k8s/secret.yaml

echo -e "${GREEN}Step 4: Creating persistent volume claims...${NC}"
kubectl apply -f k8s/mongodb-pvc.yaml

echo -e "${GREEN}Step 5: Deploying MongoDB...${NC}"
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml

echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n startupx

echo -e "${GREEN}Step 6: Deploying Backend...${NC}"
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/backend-hpa.yaml

echo "Waiting for Backend to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend -n startupx

echo -e "${GREEN}Step 7: Deploying Frontend...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/frontend-hpa.yaml

echo "Waiting for Frontend to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n startupx

echo -e "${GREEN}Step 8: Applying cert-manager issuer...${NC}"
kubectl apply -f k8s/cert-manager-issuer.yaml

echo -e "${GREEN}Step 9: Applying Ingress...${NC}"
kubectl apply -f k8s/ingress.yaml

echo -e "${GREEN}Step 10: Deploying monitoring stack...${NC}"
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-deployment.yaml

echo ""
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Deployment Status:"
kubectl get deployments -n startupx
echo ""
echo "Pod Status:"
kubectl get pods -n startupx
echo ""
echo "Service Status:"
kubectl get services -n startupx
echo ""
echo "Ingress Status:"
kubectl get ingress -n startupx
echo ""
echo "HPA Status:"
kubectl get hpa -n startupx
echo ""
echo -e "${YELLOW}To access Grafana locally:${NC}"
echo "  kubectl port-forward -n startupx svc/grafana-service 3000:3000"
echo "  Then open: http://localhost:3000 (admin/admin123)"
echo ""
echo -e "${YELLOW}To access Prometheus locally:${NC}"
echo "  kubectl port-forward -n startupx svc/prometheus-service 9090:9090"
echo "  Then open: http://localhost:9090"
