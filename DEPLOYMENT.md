# Hướng dẫn Triển khai Hệ thống Product Management trên AWS EKS

## Tổng quan Kiến trúc

Hệ thống được xây dựng dựa trên kiến trúc microservices với các thành phần:

### Infrastructure Layer (AWS)
- **VPC**: 10.0.0.0/16 với 2 AZs
  - Public Subnets: 10.0.1.0/24, 10.0.2.0/24
  - Private Subnets: 10.0.11.0/24, 10.0.12.0/24
  - Database Subnets: 10.0.21.0/24, 10.0.22.0/24
- **EKS Cluster**: Kubernetes 1.31 với managed node groups
- **DocumentDB**: MongoDB-compatible database (thay vì EC2 MongoDB)
- **EFS**: Elastic File System cho persistent storage (thay vì NFS trên EC2)
- **ALB**: Application Load Balancer qua Ingress Controller

### Application Layer
- **Backend**: Spring Boot + Java 21
- **Frontend**: React + Vite
- **Database**: AWS DocumentDB (MongoDB-compatible)

### CI/CD Pipeline
- **PR CI**: Code quality validation
- **Main CI**: Build & push Docker images
- **CD**: Deploy to EKS

## Yêu cầu Cài đặt

### 1. Tools cần thiết
```bash
# Terraform
terraform --version  # >= 1.0

# AWS CLI
aws --version  # >= 2.0

# kubectl
kubectl version --client

# Docker (cho local testing)
docker --version
```

### 2. AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

### 3. Docker Hub Account
- Tạo account tại https://hub.docker.com
- Tạo access token tại Account Settings > Security

## Bước 1: Chuẩn bị Infrastructure

### 1.1. Cấu hình Terraform
```bash
cd terraform

# Copy và chỉnh sửa file cấu hình
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Cập nhật các giá trị trong `terraform.tfvars`:
```hcl
aws_region     = "ap-southeast-1"
project_name   = "devops-final"
environment    = "production"

documentdb_master_username = "admin"
documentdb_master_password = "YourSecurePassword123!"  # Đổi password mạnh
```

### 1.2. Chạy Setup Script
```bash
cd ..
chmod +x scripts/*.sh
./scripts/setup.sh
```

Script sẽ:
- Kiểm tra prerequisites
- Initialize Terraform
- Tạo infrastructure (VPC, EKS, DocumentDB, EFS)
- Configure kubectl

### 1.3. Lấy thông tin Infrastructure
```bash
cd terraform
terraform output
```

Lưu lại các giá trị:
- `eks_cluster_name`
- `documentdb_endpoint`
- `efs_id`

## Bước 2: Cấu hình Kubernetes

### 2.1. Cập nhật EFS ID
```bash
cd ../k8s

# Thay thế fs-XXXXXXXXX bằng EFS ID thực tế
nano efs-storage.yaml
```

### 2.2. Cập nhật DocumentDB Connection
```bash
nano secret.yaml
```

Cập nhật `MONGODB_URI` với format:
```
mongodb://admin:password@your-docdb-endpoint:27017/startupx?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false
```

### 2.3. Cập nhật Docker Hub Username
```bash
# Thay YOUR_DOCKERHUB_USERNAME bằng username thực tế
nano backend-deployment.yaml
nano frontend-deployment.yaml
```

## Bước 3: Setup CI/CD

### 3.1. GitHub Secrets
Vào GitHub repository > Settings > Secrets and variables > Actions

Thêm các secrets:
```
AWS_ACCESS_KEY_ID=<your-aws-access-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret-key>
AWS_REGION=ap-southeast-1
EKS_CLUSTER_NAME=<from-terraform-output>
DOCKERHUB_USERNAME=<your-dockerhub-username>
DOCKERHUB_TOKEN=<your-dockerhub-token>

# Optional: SonarQube
SONAR_TOKEN=<your-sonar-token>
SONAR_HOST_URL=<your-sonar-url>
```

### 3.2. Build và Push Images lần đầu
```bash
# Build backend
cd app/backend/common
docker build -t <dockerhub-username>/product-management-backend:latest .
docker push <dockerhub-username>/product-management-backend:latest

# Build frontend
cd ../../frontend
docker build -t <dockerhub-username>/product-management-frontend:latest .
docker push <dockerhub-username>/product-management-frontend:latest
```

## Bước 4: Deploy Application

### 4.1. Deploy lần đầu
```bash
cd ../../..
./scripts/deploy-k8s.sh
```

### 4.2. Kiểm tra trạng thái
```bash
# Xem tất cả resources
kubectl get all -n devops-final

# Xem pods
kubectl get pods -n devops-final

# Xem logs
./scripts/logs.sh backend
./scripts/logs.sh frontend

# Xem ingress và Load Balancer URL
kubectl get ingress -n devops-final
```

### 4.3. Lấy Application URL
```bash
kubectl get ingress app-ingress -n devops-final -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Truy cập URL này để xem ứng dụng.

## Bước 5: CI/CD Workflow

### Workflow tự động
1. **Pull Request**: Trigger PR CI
   - Code quality check
   - Build validation
   - Tests

2. **Merge to main**: Trigger Main CI
   - Build Docker images
   - Security scan với Trivy
   - Push to Docker Hub
   - Trigger CD deployment

3. **CD Deploy**: Tự động deploy to EKS
   - Update deployments
   - Rolling restart
   - Verify deployment

### Manual deployment
```bash
# Trigger manual deployment từ GitHub Actions
# Go to Actions > CD - Deploy to EKS > Run workflow
# Nhập backend_tag và frontend_tag
```

## Monitoring & Debugging

### Xem logs
```bash
# Backend logs
kubectl logs -f deployment/backend -n devops-final

# Frontend logs
kubectl logs -f deployment/frontend -n devops-final

# Hoặc dùng script
./scripts/logs.sh backend
./scripts/logs.sh frontend
```

### Xem metrics
```bash
# Pod metrics
kubectl top pods -n devops-final

# Node metrics
kubectl top nodes
```

### Debug pods
```bash
# Describe pod
kubectl describe pod <pod-name> -n devops-final

# Exec into pod
kubectl exec -it <pod-name> -n devops-final -- /bin/sh

# Port forward để test local
kubectl port-forward svc/backend-svc 8080:8080 -n devops-final
kubectl port-forward svc/frontend-svc 5173:80 -n devops-final
```

## Scaling

### Manual scaling
```bash
# Scale backend
kubectl scale deployment backend --replicas=5 -n devops-final

# Scale frontend
kubectl scale deployment frontend --replicas=5 -n devops-final
```

### Auto-scaling
HPA đã được cấu hình:
- Min replicas: 2
- Max replicas: 10
- CPU threshold: 70%

Xem HPA status:
```bash
kubectl get hpa -n devops-final
```

## Cleanup

### Xóa Kubernetes resources
```bash
kubectl delete namespace devops-final
```

### Xóa toàn bộ infrastructure
```bash
./scripts/destroy.sh
```

## Troubleshooting

### Pods không start
```bash
# Xem events
kubectl get events -n devops-final --sort-by='.lastTimestamp'

# Xem pod details
kubectl describe pod <pod-name> -n devops-final
```

### Load Balancer không tạo
```bash
# Kiểm tra AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Xem logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### DocumentDB connection issues
```bash
# Test connection từ pod
kubectl run -it --rm debug --image=mongo:7 --restart=Never -n devops-final -- \
  mongosh "mongodb://admin:password@docdb-endpoint:27017/?tls=true&replicaSet=rs0"
```

### EFS mount issues
```bash
# Kiểm tra EFS CSI driver
kubectl get pods -n kube-system | grep efs

# Xem PV/PVC status
kubectl get pv,pvc -n devops-final
```

## Best Practices

1. **Security**
   - Luôn dùng strong passwords cho DocumentDB
   - Rotate AWS credentials định kỳ
   - Enable encryption cho EFS và DocumentDB
   - Sử dụng HTTPS với ACM certificates

2. **Cost Optimization**
   - Sử dụng t3.medium cho dev/test
   - Enable auto-scaling để tối ưu resources
   - Xóa unused resources
   - Sử dụng EFS Infrequent Access cho cold data

3. **High Availability**
   - Deploy across multiple AZs
   - Minimum 2 replicas cho mỗi service
   - Configure health checks properly
   - Regular backups cho DocumentDB

4. **Monitoring**
   - Setup CloudWatch alarms
   - Monitor EKS cluster metrics
   - Track application logs
   - Regular security scans

## Tài liệu tham khảo

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AWS DocumentDB Documentation](https://docs.aws.amazon.com/documentdb/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
