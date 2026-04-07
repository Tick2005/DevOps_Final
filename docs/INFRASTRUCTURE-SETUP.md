# Infrastructure Setup Guide

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- SSH key pair generated
- Domain name registered

## Step 1: Generate SSH Key Pair

Use the command for your shell:

Linux/macOS/WSL/Git Bash:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k3s-key -N ""
```

Windows PowerShell:

```powershell
ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/k3s-key"
```

When prompted for passphrase, press Enter twice to leave it empty.

## Step 2: Configure Terraform Variables

1. Copy the example variables file:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` and update:
   - `aws_region`: Your preferred AWS region
   - `ssh_public_key`: Content of `~/.ssh/k3s-key.pub`
   - Other variables as needed

## Step 3: Initialize and Apply Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

**Important**: Save the outputs! You'll need them for cluster access.

## Step 4: Verify Idempotency

Run terraform apply again to verify idempotency:

```bash
terraform apply
```

Expected output: "No changes. Your infrastructure matches the configuration."

Take a screenshot of this output for your report.

## Step 5: Access the Master Node

Use the command for your shell:

Linux/macOS/WSL/Git Bash:

```bash
# Get the master IP from terraform output
terraform output master_public_ip

# SSH into the master
ssh -i ~/.ssh/k3s-key ubuntu@52.76.185.212
```

Windows PowerShell:

```powershell
$MASTER_IP = terraform output -raw master_public_ip
ssh -i "$HOME/.ssh/k3s-key" "ubuntu@$MASTER_IP"
```

## Step 6: Setup K3s Cluster

On the master node:

```bash
# Run the setup script
sudo bash /var/lib/cloud/instance/scripts/part-001

# Or manually install
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.5+k3s1" sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable traefik
```

## Step 7: Configure kubectl Locally

Use the command for your shell:

Linux/macOS/WSL/Git Bash:

```bash
mkdir -p ~/.kube

# Copy kubeconfig from master
scp -i ~/.ssh/k3s-key ubuntu@52.76.185.212:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Keep kubeconfig server as 127.0.0.1 and create an SSH tunnel
ssh -i ~/.ssh/k3s-key -N -L 6443:127.0.0.1:6443 ubuntu@<master-ip>

# In another terminal, verify connection
kubectl get nodes
```

Windows PowerShell:

```powershell
$MASTER_IP = terraform output -raw master_public_ip
New-Item -ItemType Directory -Force -Path "$HOME/.kube" | Out-Null

# Copy kubeconfig from master
scp -i "$HOME/.ssh/k3s-key" "ubuntu@${MASTER_IP}:/etc/rancher/k3s/k3s.yaml" "$HOME/.kube/config"

# Keep kubeconfig server as 127.0.0.1 and create an SSH tunnel
ssh -i "$HOME/.ssh/k3s-key" -N -L 6443:127.0.0.1:6443 "ubuntu@${MASTER_IP}"

# In another PowerShell terminal, verify connection
kubectl get nodes
```

Keep the SSH tunnel terminal running while you use kubectl from your local machine.

## Step 8: Install Required Components

```bash
# Install Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# Wait for cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager

# Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics server for K3s
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

## Step 9: Configure DNS

1. Get your master node's public IP:
```bash
terraform output master_public_ip
```

2. In your domain registrar (e.g., Namecheap, GoDaddy):
   - Create an A record: `@` → `<master-ip>`
   - Create an A record: `www` → `<master-ip>`

3. Verify DNS propagation:
```bash
nslookup your-domain.com
```

## Step 10: Update Kubernetes Manifests

Update the following files with your domain:

1. `k8s/ingress.yaml`:
   - Replace `your-domain.com` with your actual domain

2. `k8s/cert-manager-issuer.yaml`:
   - Replace `your-email@example.com` with your email

## Verification Checklist

- [ ] Terraform apply completes successfully
- [ ] Terraform apply is idempotent (no changes on second run)
- [ ] Can SSH into master node
- [ ] K3s is running: `kubectl get nodes` shows Ready
- [ ] Ingress controller is running
- [ ] cert-manager is running
- [ ] Metrics server is running
- [ ] DNS resolves to master IP
- [ ] All screenshots captured for report

## Troubleshooting

### Cannot connect to cluster
- Check security group rules allow port 6443
- Verify kubeconfig has correct IP address
- Check K3s is running: `sudo systemctl status k3s`

### Metrics server not working
- Ensure the insecure-tls patch is applied
- Check logs: `kubectl logs -n kube-system -l k8s-app=metrics-server`

### DNS not resolving
- Wait for DNS propagation (can take up to 48 hours)
- Use `dig your-domain.com` to check DNS records

## Next Steps

Proceed to [Application Deployment Guide](./DEPLOYMENT-GUIDE.md)
