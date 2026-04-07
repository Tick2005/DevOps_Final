#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git

# Install K3s master
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --node-name k3s-master

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
until kubectl get nodes | grep -q "Ready"; do
  sleep 5
done

echo "K3s master installation completed!"
echo "Node token is available at: /var/lib/rancher/k3s/server/node-token"
