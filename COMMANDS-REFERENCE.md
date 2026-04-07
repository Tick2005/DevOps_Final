# Commands Reference - Quick Copy-Paste Guide

## Terraform Commands

```bash
# Initialize Terraform
cd terraform
terraform init

# Validate configuration
terraform validate

# Plan infrastructure
terraform plan

# Apply infrastructure
terraform apply

# Show outputs
terraform output

# Destroy infrastructure (careful!)
terraform destroy

# Format Terraform files
terraform fmt -recursive
```

## Kubernetes - Cluster Management

```bash
# Check cluster info
kubectl cluster-info
kubectl version

# Get nodes
kubectl get nodes
kubectl get nodes -o wide

# Describe node
kubectl describe node <node-name>

# Check cluster components
kubectl get componentstatuses
```

## Kubernetes - Namespace Operations

```bash
# Create namespace
kubectl create namespace startupx

# List namespaces
kubectl get namespaces

# Set default namespace
kubectl config set-context --current --namespace=startupx

# Delete namespace
kubectl delete namespace startupx
```

## Kubernetes - Deployment Operations

```bash
# Apply all manifests
kubectl apply -f k8s/

# Apply specific file
kubectl apply -f k8s/backend-deployment.yaml

# Get all resources
kubectl get all -n startupx

# Get deployments
kubectl get deployments -n startupx
kubectl get deploy -n startupx -o wide

# Describe deployment
kubectl describe deployment backend -n startupx

# Scale deployment
kubectl scale deployment backend --replicas=3 -n startupx

# Delete deployment
kubectl delete deployment backend -n startupx
```

## Kubernetes - Pod Operations

```bash
# Get pods
kubectl get pods -n startupx
kubectl get pods -n startupx -o wide
kubectl get pods -n startupx --watch

# Describe pod
kubectl describe pod <pod-name> -n startupx

# Get pod logs
kubectl logs <pod-name> -n startupx
kubectl logs <pod-name> -n startupx --tail=50
kubectl logs <pod-name> -n startupx --follow

# Get logs from all pods with label
kubectl logs -n startupx -l app=backend --tail=50

# Execute command in pod
kubectl exec -it <pod-name> -n startupx -- /bin/sh
kubectl exec -it <pod-name> -n startupx -- bash

# Delete pod
kubectl delete pod <pod-name> -n startupx
kubectl delete pod -n startupx -l app=backend --force --grace-period=0

# Copy files to/from pod
kubectl cp <pod-name>:/path/to/file ./local-file -n startupx
kubectl cp ./local-file <pod-name>:/path/to/file -n startupx
```

## Kubernetes - Service Operations

```bash
# Get services
kubectl get services -n startupx
kubectl get svc -n startupx

# Describe service
kubectl describe service backend-service -n startupx

# Port forward service
kubectl port-forward svc/backend-service 8080:8080 -n startupx
kubectl port-forward svc/grafana-service 3000:3000 -n startupx

# Delete service
kubectl delete service backend-service -n startupx
```

## Kubernetes - ConfigMap & Secrets

```bash
# Get configmaps
kubectl get configmap -n startupx
kubectl describe configmap app-config -n startupx

# Get secrets
kubectl get secrets -n startupx
kubectl describe secret mongodb-secret -n startupx

# Create secret from literal
kubectl create secret generic my-secret --from-literal=key=value -n startupx

# Create secret from file
kubectl create secret generic my-secret --from-file=./secret.txt -n startupx

# Decode secret
kubectl get secret mongodb-secret -n startupx -o jsonpath='{.data.mongodb-root-password}' | base64 -d

# Delete configmap/secret
kubectl delete configmap app-config -n startupx
kubectl delete secret mongodb-secret -n startupx
```

## Kubernetes - Ingress Operations

```bash
# Get ingress
kubectl get ingress -n startupx
kubectl describe ingress startupx-ingress -n startupx

# Get ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check ingress controller
kubectl get pods -n ingress-nginx
```

## Kubernetes - HPA Operations

```bash
# Get HPA
kubectl get hpa -n startupx
kubectl get hpa -n startupx --watch

# Describe HPA
kubectl describe hpa backend-hpa -n startupx

# Delete HPA
kubectl delete hpa backend-hpa -n startupx

# Check metrics
kubectl top nodes
kubectl top pods -n startupx
```

## Kubernetes - Rollout Management

```bash
# Check rollout status
kubectl rollout status deployment/backend -n startupx

# Check rollout history
kubectl rollout history deployment/backend -n startupx

# Rollback to previous version
kubectl rollout undo deployment/backend -n startupx

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n startupx

# Pause rollout
kubectl rollout pause deployment/backend -n startupx

# Resume rollout
kubectl rollout resume deployment/backend -n startupx

# Restart deployment
kubectl rollout restart deployment/backend -n startupx
```

## Kubernetes - Certificate Management

```bash
# Get certificates
kubectl get certificate -n startupx
kubectl get certificate -n startupx --watch

# Describe certificate
kubectl describe certificate startupx-tls -n startupx

# Get certificate issuer
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Get certificate challenges
kubectl get challenges -n startupx
kubectl describe challenge <challenge-name> -n startupx
```

## Kubernetes - Events & Debugging

```bash
# Get events
kubectl get events -n startupx
kubectl get events -n startupx --sort-by='.lastTimestamp'
kubectl get events -n startupx --watch

# Get events for specific resource
kubectl get events --field-selector involvedObject.name=<pod-name> -n startupx

# Debug pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh

# Test DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup backend-service.startupx

# Test connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://backend-service.startupx:8080/api/products
```

## Docker Commands

```bash
# Build image
docker build -t your-username/startupx-backend:v1.0.0 .

# Tag image
docker tag startupx-backend:latest your-username/startupx-backend:v1.0.0

# Push image
docker push your-username/startupx-backend:v1.0.0

# Pull image
docker pull your-username/startupx-backend:v1.0.0

# List images
docker images

# Remove image
docker rmi your-username/startupx-backend:v1.0.0

# Login to Docker Hub
docker login

# Logout
docker logout
```

## Git Commands

```bash
# Clone repository
git clone <repository-url>

# Check status
git status

# Add files
git add .
git add <file>

# Commit
git commit -m "message"

# Push
git push origin main

# Pull
git pull origin main

# Create branch
git checkout -b feature-branch

# Switch branch
git checkout main

# Merge branch
git merge feature-branch

# View log
git log --oneline
git log --graph --oneline --all

# View diff
git diff
git diff <file>

# Undo changes
git checkout -- <file>
git reset --hard HEAD
```

## SSH Commands

```bash
# SSH to server
ssh -i ~/.ssh/k3s-key ubuntu@<server-ip>

# Copy file to server
scp -i ~/.ssh/k3s-key file.txt ubuntu@<server-ip>:/path/

# Copy file from server
scp -i ~/.ssh/k3s-key ubuntu@<server-ip>:/path/file.txt ./

# Copy directory
scp -r -i ~/.ssh/k3s-key directory/ ubuntu@<server-ip>:/path/

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k3s-key -N ""
```

## Monitoring Commands

```bash
# Port forward Grafana
kubectl port-forward -n startupx svc/grafana-service 3000:3000

# Port forward Prometheus
kubectl port-forward -n startupx svc/prometheus-service 9090:9090

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Query Prometheus
curl 'http://localhost:9090/api/v1/query?query=up'

# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
```

## Load Testing Commands

```bash
# Install hey
go install github.com/rakyll/hey@latest

# Generate load
hey -z 60s -c 50 https://your-domain.com/api/products

# Apache Bench (alternative)
ab -n 1000 -c 50 https://your-domain.com/api/products

# Curl loop
for i in {1..100}; do curl https://your-domain.com/api/products; done
```

## Useful One-Liners

```bash
# Get all pod IPs
kubectl get pods -n startupx -o wide | awk '{print $1, $6}'

# Get all container images
kubectl get pods -n startupx -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Count pods by status
kubectl get pods -n startupx --no-headers | awk '{print $3}' | sort | uniq -c

# Get pod resource usage
kubectl top pods -n startupx --sort-by=cpu
kubectl top pods -n startupx --sort-by=memory

# Watch pod status
watch -n 1 kubectl get pods -n startupx

# Get all pod logs
kubectl get pods -n startupx -o name | xargs -I {} kubectl logs {} -n startupx --tail=10

# Delete all pods with label
kubectl delete pods -n startupx -l app=backend

# Force delete stuck pod
kubectl delete pod <pod-name> -n startupx --force --grace-period=0

# Get pod YAML
kubectl get pod <pod-name> -n startupx -o yaml

# Edit deployment
kubectl edit deployment backend -n startupx

# Set image
kubectl set image deployment/backend backend=your-username/startupx-backend:v2.0.0 -n startupx

# Get deployment revision
kubectl rollout history deployment/backend -n startupx --revision=2
```

## Base64 Encoding/Decoding

```bash
# Encode
echo -n 'password123' | base64

# Decode
echo 'cGFzc3dvcmQxMjM=' | base64 -d

# Encode file
cat file.txt | base64

# Decode file
cat encoded.txt | base64 -d > decoded.txt
```

## DNS Testing

```bash
# nslookup
nslookup your-domain.com

# dig
dig your-domain.com
dig your-domain.com +short

# host
host your-domain.com

# Check DNS propagation
curl https://dns.google/resolve?name=your-domain.com
```

## Certificate Testing

```bash
# Check certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Check certificate expiry
echo | openssl s_client -connect your-domain.com:443 -servername your-domain.com 2>/dev/null | openssl x509 -noout -dates

# Test HTTPS
curl -I https://your-domain.com
curl -v https://your-domain.com
```

## Cleanup Commands

```bash
# Delete all resources in namespace
kubectl delete all --all -n startupx

# Delete namespace (deletes everything)
kubectl delete namespace startupx

# Delete specific resources
kubectl delete -f k8s/

# Terraform destroy
cd terraform
terraform destroy

# Docker cleanup
docker system prune -a
docker volume prune
```

## Quick Deployment Script

```bash
#!/bin/bash
# Quick deploy script

# Apply all manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/mongodb-pvc.yaml
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n startupx
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/backend-hpa.yaml
kubectl wait --for=condition=available --timeout=300s deployment/backend -n startupx
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/frontend-hpa.yaml
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n startupx
kubectl apply -f k8s/cert-manager-issuer.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/monitoring/

echo "Deployment complete!"
kubectl get all -n startupx
```

## Environment Variables

```bash
# Set kubeconfig
export KUBECONFIG=~/.kube/config

# Set default namespace
export NAMESPACE=startupx

# Use in commands
kubectl get pods -n $NAMESPACE
```

---

**Tip**: Bookmark this file for quick reference during implementation and demo!
