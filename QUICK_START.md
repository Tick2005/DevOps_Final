# Quick Start Guide - DevOps Final

## Trạng thái hiện tại

Terraform đang apply infrastructure. Quá trình này mất khoảng 10-15 phút.

### Đang tạo:
- ✅ RDS PostgreSQL (db.t4g.micro - Free tier)
- ✅ RDS Security Group
- ✅ RDS Subnet Group
- 🔄 EKS Node Group (thay đổi từ c7i-flex.large → t3.medium)

### Đã xóa:
- ✅ DocumentDB Subnet Group
- ✅ DocumentDB Security Group

## Sau khi Terraform hoàn thành

### 1. Kiểm tra trạng thái
```bash
cd terraform
terraform output
```

### 2. Lấy RDS endpoint
```bash
terraform output rds_endpoint
# Output: devops-final-postgres.xxxxx.ap-southeast-1.rds.amazonaws.com:5432
```

### 3. Configure kubectl
```bash
aws eks update-kubeconfig --region ap-southeast-1 --name devops-final-eks
kubectl get nodes
```

### 4. Cập nhật Kubernetes Secret
```bash
cd ../k8s
nano secret.yaml
```

Thay đổi:
```yaml
stringData:
  DATABASE_URL: "jdbc:postgresql://YOUR-RDS-ENDPOINT:5432/productdb"
  DATABASE_USERNAME: "postgres"
  DATABASE_PASSWORD: "YourSecurePassword123!"
```

### 5. Deploy to Kubernetes
```bash
kubectl apply -f namespace.yaml
kubectl apply -f efs-storage.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml
```

### 6. Kiểm tra deployment
```bash
kubectl get pods -n devops-final
kubectl get svc -n devops-final
kubectl get ingress -n devops-final
```

### 7. Lấy Application URL
```bash
kubectl get ingress app-ingress -n devops-final -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Đợi vài phút để ALB được tạo, sau đó truy cập URL.

## Test Local trước

Nếu muốn test local trước khi deploy to EKS:

```bash
cd DevOps_Final
docker compose up -d --build

# Access
# Frontend: http://localhost:5173
# Backend: http://localhost:8080/api/products
```

## Troubleshooting

### Terraform vẫn đang chạy
```bash
# Kiểm tra process
ps aux | grep terraform

# Nếu cần cancel (không khuyến nghị)
# Ctrl+C trong terminal đang chạy terraform
```

### RDS Free Tier Issues
Nếu gặp lỗi free tier:
- Đã đổi sang `db.t4g.micro` (ARM-based, free tier eligible)
- Tắt encryption (`storage_encrypted = false`)
- Tắt backup (`backup_retention_period = 0`)
- Tắt CloudWatch logs

### EKS Node Group đang update
Quá trình này mất 10-15 phút. Terraform sẽ:
1. Tạo node group mới với t3.medium
2. Chờ nodes ready
3. Xóa node group cũ

## Kiến trúc Final

```
Internet
    │
    ▼
  ALB (Ingress)
    │
    ├─► Frontend Pods (2-10 replicas)
    │
    └─► Backend Pods (2-10 replicas)
          │
          ├─► RDS PostgreSQL (db.t4g.micro)
          │
          └─► EFS (Shared storage)
```

## Cost Estimate

- EKS Control Plane: $0.10/hour (~$73/month)
- EC2 t3.medium x2: $0.0416/hour x2 (~$60/month)
- RDS db.t4g.micro: Free tier (750 hours/month)
- EFS: $0.30/GB-month (minimal usage)
- NAT Gateway: $0.045/hour (~$32/month)
- ALB: $0.0225/hour (~$16/month)

**Total: ~$181/month** (excluding free tier)

## Next Steps

1. Đợi terraform apply hoàn thành
2. Update k8s/secret.yaml với RDS endpoint
3. Deploy to Kubernetes
4. Setup CI/CD (GitHub Actions)
5. Configure monitoring (optional)
