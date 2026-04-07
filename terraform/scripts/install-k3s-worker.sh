#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget

# Wait for master to be ready and get token
echo "Waiting for master node to be ready..."
sleep 60

# Get K3s token from master (this will be handled manually or via Ansible)
# For now, this is a placeholder - actual token retrieval needs to be done after master is up

# Install K3s worker
# Note: K3S_TOKEN needs to be set manually or via configuration management
# curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" K3S_URL=https://${master_ip}:6443 K3S_TOKEN=<token> sh -

echo "K3s worker node prepared. Manual token configuration required."
echo "Run: curl -sfL https://get.k3s.io | K3S_URL=https://${master_ip}:6443 K3S_TOKEN=<token> sh -"
