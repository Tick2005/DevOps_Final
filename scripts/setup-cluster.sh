#!/bin/bash
set -e

echo "=== K3s Cluster Setup Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}Please run as root or with sudo${NC}"
  exit 1
fi

echo -e "${GREEN}Step 1: Installing required packages...${NC}"
apt-get update
apt-get install -y curl wget git

echo -e "${GREEN}Step 2: Installing K3s...${NC}"
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.5+k3s1" sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik

echo -e "${GREEN}Step 3: Waiting for K3s to be ready...${NC}"
until kubectl get nodes | grep -q "Ready"; do
  echo "Waiting for node to be ready..."
  sleep 5
done

echo -e "${GREEN}Step 4: Installing Helm...${NC}"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo -e "${GREEN}Step 5: Installing Nginx Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

echo -e "${GREEN}Step 6: Installing cert-manager...${NC}"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

echo -e "${GREEN}Step 7: Waiting for cert-manager to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager

echo -e "${GREEN}Step 8: Installing Metrics Server...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics server for K3s
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo ""
echo -e "${GREEN}=== Cluster Setup Complete! ===${NC}"
echo ""
echo "Cluster Information:"
kubectl cluster-info
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo -e "${YELLOW}Kubeconfig location: /etc/rancher/k3s/k3s.yaml${NC}"
echo -e "${YELLOW}To use kubectl from remote machine:${NC}"
echo "  1. Copy kubeconfig: scp root@<server-ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config"
echo "  2. Edit ~/.kube/config and replace 127.0.0.1 with your server IP"
echo ""
echo -e "${YELLOW}Node token (for adding workers): ${NC}"
cat /var/lib/rancher/k3s/server/node-token
