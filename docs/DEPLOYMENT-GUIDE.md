# Application Deployment Guide

## Prerequisites

- K3s cluster is running and accessible
- kubectl configured and working
- Docker images built and pushed to registry
- Domain configured and DNS propagated

## Step 1: Prepare Secrets

1. Create actual secret file from template:
```bash
cp k8s/secret.yaml.template k8s/secret.yaml
```

2. Generate secure passwords:
```bash
# Generate random password
openssl rand -base64 32

# Encode for Kubernetes secret
echo -n 'your-password' | base64
```

3. Update `k8s/secret.yaml` with your encoded values

## Step 2: Update Image References

Update the following files with your Docker registry and image names:

1. `k8s/backend-deployment.yaml`:
```yaml
image: your-dockerhub-username/startupx-backend:v1.0.0
```

2. `k8s/frontend-deployment.yaml`:
```yaml
image: your-dockerhub-username/startupx-frontend:v1.0.0
```

## Step 3: Deploy Using Script

```bash
# Make script executable
chmod +x scripts/deploy-app.sh

# Run deployment
./scripts/deploy-app.sh
```

## Step 4: Manual Deployment (Alternative)

If you prefer manual deployment:

```bash
# 1. Create namespace
kubectl apply -f k8s/namespace.yaml

# 2. Apply configurations
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# 3. Create storage
kubectl apply -f k8s/mongodb-pvc.yaml

# 4. Deploy MongoDB
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml
kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n startupx

# 5. Deploy Backend
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/backend-hpa.yaml
kubectl wait --for=condition=available --timeout=300s deployment/backend -n startupx

# 6. Deploy Frontend
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/frontend-hpa.yaml
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n startupx

# 7. Setup cert-manager
kubectl apply -f k8s/cert-manager-issuer.yaml

# 8. Deploy Ingress
kubectl apply -f k8s/ingress.yaml

# 9. Deploy monitoring
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-deployment.yaml
```

## Step 5: Verify Deployment

```bash
# Check all resources
kubectl get all -n startupx

# Check pods are running
kubectl get pods -n startupx

# Check services
kubectl get svc -n startupx

# Check ingress
kubectl get ingress -n startupx

# Check HPA
kubectl get hpa -n startupx

# Check certificate
kubectl get certificate -n startupx
```

## Step 6: Wait for HTTPS Certificate

```bash
# Watch certificate status
kubectl describe certificate startupx-tls -n startupx

# Check cert-manager logs if issues
kubectl logs -n cert-manager -l app=cert-manager
```

Certificate issuance can take 2-10 minutes.

## Step 7: Access Application

Once certificate is ready:

```bash
# Get ingress address
kubectl get ingress -n startupx

# Access your application
https://your-domain.com
```

## Step 8: Access Monitoring

### Grafana (Local Access)

```bash
# Port forward Grafana
kubectl port-forward -n startupx svc/grafana-service 3000:3000

# Open browser
http://localhost:3000

# Login: admin / admin123
```

### Prometheus (Local Access)

```bash
# Port forward Prometheus
kubectl port-forward -n startupx svc/prometheus-service 9090:9090

# Open browser
http://localhost:9090
```

## Verification Checklist

- [ ] All pods are running: `kubectl get pods -n startupx`
- [ ] All services are created
- [ ] HPA is active and showing metrics
- [ ] Ingress has an address
- [ ] Certificate is issued (Ready: True)
- [ ] Application accessible via HTTPS
- [ ] No certificate warnings in browser
- [ ] Backend API responding: `https://your-domain.com/api/products`
- [ ] Frontend loading correctly
- [ ] Grafana accessible and showing metrics
- [ ] Prometheus collecting metrics

## Testing Self-Healing

### Test 1: Delete a Pod

```bash
# Delete a backend pod
kubectl delete pod -n startupx -l app=backend --force --grace-period=0

# Watch it recreate
kubectl get pods -n startupx -w
```

### Test 2: Scale Down and Watch HPA

```bash
# Manually scale down
kubectl scale deployment backend -n startupx --replicas=1

# Watch HPA restore to minimum
kubectl get hpa -n startupx -w
```

### Test 3: Simulate High Load

```bash
# Install hey (HTTP load generator)
# On Ubuntu/Debian:
sudo apt-get install hey

# Generate load
hey -z 60s -c 50 https://your-domain.com/api/products

# Watch HPA scale up
kubectl get hpa -n startupx -w
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n startupx

# Check logs
kubectl logs <pod-name> -n startupx

# Check events
kubectl get events -n startupx --sort-by='.lastTimestamp'
```

### Certificate not issuing

```bash
# Check certificate status
kubectl describe certificate startupx-tls -n startupx

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check challenge
kubectl get challenges -n startupx
```

### HPA not working

```bash
# Check metrics server
kubectl top nodes
kubectl top pods -n startupx

# If metrics not available, check metrics-server
kubectl logs -n kube-system -l k8s-app=metrics-server
```

### Application not accessible

```bash
# Check ingress
kubectl describe ingress startupx-ingress -n startupx

# Check ingress controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Test internal connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh
# Inside pod:
curl http://backend-service.startupx:8080/api/products
```

## Updating the Application

### Rolling Update

```bash
# Update image tag in deployment
kubectl set image deployment/backend backend=your-registry/startupx-backend:v1.1.0 -n startupx

# Watch rollout
kubectl rollout status deployment/backend -n startupx

# Check rollout history
kubectl rollout history deployment/backend -n startupx
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n startupx

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n startupx
```

## Cleanup

To remove all resources:

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

Or manually:

```bash
kubectl delete namespace startupx
kubectl delete clusterissuer letsencrypt-prod letsencrypt-staging
```

## Next Steps

- Configure CI/CD pipeline: [CI/CD Setup Guide](./CICD-SETUP.md)
- Setup monitoring dashboards: [Monitoring Guide](./MONITORING-GUIDE.md)
