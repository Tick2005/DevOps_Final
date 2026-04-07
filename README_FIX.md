# 🔧 HƯỚNG DẪN SỬA LỖI NHANH

## Bạn đang gặp lỗi này?

```
Error: FileSystemAlreadyExists
Error: AlreadyExistsException  
Error: ResourceAlreadyExistsException
Error: VpcLimitExceeded
```

## ✅ Giải pháp 1 dòng lệnh:

```bash
cd DevOps_Final
chmod +x scripts/fix-terraform-state.sh
./scripts/fix-terraform-state.sh
```

Sau đó:
```bash
cd terraform
terraform plan
terraform apply
```

## 📋 Script sẽ làm gì?

1. ✅ Kill terraform processes đang chạy
2. ✅ Xóa lock files
3. ✅ Refresh terraform state
4. ✅ Import các resources đã tồn tại:
   - EFS file system
   - VPC (nếu có)
   - CloudWatch log group
   - KMS alias

## 🚨 Nếu vẫn lỗi VPC Limit

### Xem VPCs hiện tại:
```bash
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],State]' --output table
```

### Xóa VPC không dùng:
```bash
# Cẩn thận! Chỉ xóa VPC không dùng
aws ec2 delete-vpc --vpc-id vpc-xxxxx
```

### Hoặc request tăng limit:
- Vào AWS Console > Service Quotas > Amazon VPC
- Request tăng từ 5 lên 10 VPCs

## 📖 Tài liệu chi tiết

- [FIX_ERRORS.md](FIX_ERRORS.md) - Hướng dẫn chi tiết tất cả lỗi
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Troubleshooting guide
- [DEPLOYMENT.md](DEPLOYMENT.md) - Hướng dẫn deployment đầy đủ

## ⚡ Quick Commands

```bash
# Fix terraform state
./scripts/fix-terraform-state.sh

# Check status
./scripts/check-status.sh

# Deploy
cd terraform
terraform apply

# Get RDS endpoint
terraform output rds_endpoint

# Deploy to Kubernetes
cd ../k8s
kubectl apply -f .
```

## 🆘 Cần cleanup hoàn toàn?

```bash
./scripts/cleanup-and-restart.sh
```

⚠️ **Lưu ý**: Script này sẽ backup state trước khi cleanup.
