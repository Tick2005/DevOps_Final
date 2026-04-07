# Hướng dẫn Setup Nhanh

## Lưu ý cho Windows Users

Scripts được viết cho bash shell. Trên Windows, bạn có 2 lựa chọn:

### Option 1: Sử dụng Git Bash (Khuyến nghị)
```bash
# Mở Git Bash và chạy
cd DevOps_Final
./scripts/setup.sh
```

### Option 2: Sử dụng WSL (Windows Subsystem for Linux)
```bash
# Mở WSL terminal
cd /mnt/c/path/to/DevOps_Final
chmod +x scripts/*.sh
./scripts/setup.sh
```

### Option 3: Chạy từng bước thủ công trên PowerShell

#### 1. Setup Infrastructure
```powershell
cd terraform
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars với notepad hoặc editor
terraform plan -out=tfplan
terraform apply tfplan
```

#### 2. Configure kubectl
```powershell
$EKS_CLUSTER_NAME = terraform output -raw eks_cluster_name
$AWS_REGION = terraform output -raw aws_region
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
```

#### 3. Get Infrastructure Outputs
```powershell
$EFS_ID = terraform output -raw efs_id
$DOCDB_ENDPOINT = terraform output -raw documentdb_endpoint
Write-Host "EFS ID: $EFS_ID"
Write-Host "DocumentDB Endpoint: $DOCDB_ENDPOINT"
```

#### 4. Update Kubernetes Manifests
```powershell
cd ../k8s

# Update EFS ID in efs-storage.yaml
# Thay fs-XXXXXXXXX bằng $EFS_ID

# Update DocumentDB endpoint in secret.yaml
# Thay docdb-endpoint bằng $DOCDB_ENDPOINT
```

#### 5. Deploy to Kubernetes
```powershell
kubectl apply -f namespace.yaml
kubectl apply -f efs-storage.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/backend -n devops-final
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n devops-final

# Get status
kubectl get all -n devops-final
kubectl get ingress -n devops-final
```

## Checklist Trước Khi Deploy

- [ ] AWS CLI đã cài đặt và configure
- [ ] Terraform đã cài đặt (>= 1.0)
- [ ] kubectl đã cài đặt
- [ ] Docker Hub account đã tạo
- [ ] GitHub repository đã setup
- [ ] AWS credentials có đủ quyền (EKS, VPC, DocumentDB, EFS)

## Các Bước Chính

1. **Infrastructure Setup** (30-45 phút)
   - Terraform tạo VPC, EKS, DocumentDB, EFS
   - Configure kubectl

2. **Update Manifests** (5 phút)
   - EFS ID
   - DocumentDB endpoint
   - Docker Hub username

3. **Deploy Application** (10-15 phút)
   - Apply Kubernetes manifests
   - Wait for pods ready
   - Get Load Balancer URL

4. **Setup CI/CD** (10 phút)
   - Configure GitHub Secrets
   - Push code to trigger pipeline

## Troubleshooting

### Terraform fails
```powershell
# Check AWS credentials
aws sts get-caller-identity

# Check Terraform version
terraform version

# Re-initialize
terraform init -upgrade
```

### kubectl not connecting
```powershell
# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name devops-final-eks

# Test connection
kubectl get nodes
```

### Pods not starting
```powershell
# Check pod status
kubectl get pods -n devops-final

# Check pod logs
kubectl logs -n devops-final deployment/backend
kubectl logs -n devops-final deployment/frontend

# Describe pod for events
kubectl describe pod -n devops-final <pod-name>
```

## Quick Commands

```powershell
# View all resources
kubectl get all -n devops-final

# View logs
kubectl logs -f deployment/backend -n devops-final
kubectl logs -f deployment/frontend -n devops-final

# Scale manually
kubectl scale deployment backend --replicas=5 -n devops-final

# Get Load Balancer URL
kubectl get ingress app-ingress -n devops-final

# Delete everything
kubectl delete namespace devops-final
cd terraform
terraform destroy -auto-approve
```

## Tài liệu Chi tiết

- [DEPLOYMENT.md](DEPLOYMENT.md) - Hướng dẫn chi tiết từng bước
- [README_INFRASTRUCTURE.md](README_INFRASTRUCTURE.md) - Giải thích kiến trúc
- [architecture-diagram.md](architecture-diagram.md) - Sơ đồ hệ thống
