# 🚀 Manual Deploy Application

## Nếu CI/CD workflows failed, có thể deploy manually

### Bước 1: Update deployment files với Docker username

```bash
cd DevOps_Final

# Update backend deployment
sed -i "s|DOCKER_USERNAME|<your-dockerhub-username>|g" kubernetes/base/backend/deployment.yaml
sed -i "s|PLACEHOLDER_IMAGE_TAG|latest|g" kubernetes/base/backend/deployment.yaml

# Update frontend deployment
sed -i "s|DOCKER_USERNAME|<your-dockerhub-username>|g" kubernetes/base/frontend/deployment.yaml
sed -i "s|PLACEHOLDER_IMAGE_TAG|latest|g" kubernetes/base/frontend/deployment.yaml
```

### Bước 2: Deploy to Kubernetes

```bash
# Configure kubectl
aws eks update-kubeconfig --name productx-eks-cluster --region ap-southeast-1

# Deploy backend
kubectl apply -f kubernetes/base/backend/deployment.yaml

# Deploy frontend
kubectl apply -f kubernetes/base/frontend/deployment.yaml

# Check pods
kubectl get pods -n productx -w
```

### Bước 3: Verify deployment

```bash
# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=backend -n productx --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n productx --timeout=300s

# Check pods
kubectl get pods -n productx

# Check logs
kubectl logs -n productx deployment/backend --tail=50
kubectl logs -n productx deployment/frontend --tail=50
```

### Bước 4: Test application

```bash
# Get ALB URL
ALB_DNS=$(kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test
curl http://$ALB_DNS/
curl http://$ALB_DNS/api/products

# Or test domain
curl http://tranduchuy.site/
```

## Nếu Docker images chưa có

### Build và push manually:

```bash
cd DevOps_Final

# Build backend
cd app/backend/common
docker build -t <your-dockerhub-username>/productx-backend:latest .
docker push <your-dockerhub-username>/productx-backend:latest

# Build frontend
cd ../../frontend
docker build -t <your-dockerhub-username>/productx-frontend:latest .
docker push <your-dockerhub-username>/productx-frontend:latest
```

Sau đó deploy như bước 1-4 ở trên.
