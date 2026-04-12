# 🎯 Các bước tiếp theo để fix lỗi IAM Role

## 📋 Tình trạng hiện tại

❌ **Lỗi:** IAM Role `productx-eks-cluster-aws-load-balancer-controller` đã tồn tại

❌ **Nguyên nhân:** Deployment trước đó failed nhưng đã tạo IAM role, Terraform không thể tạo lại

✅ **Giải pháp:** Cleanup IAM roles và re-deploy

---

## ⚡ Quick Fix (5 phút)

### Bước 1: Chạy cleanup script

```bash
cd DevOps_Final
chmod +x cleanup-iam-roles.sh
./cleanup-iam-roles.sh
```

**Khi script hỏi "Do you want to continue? (yes/no):"** → Gõ `yes` và Enter

### Bước 2: Đợi IAM propagation

```bash
# Đợi 1-2 phút để AWS cập nhật
sleep 120
```

### Bước 3: Re-run GitHub Actions

**Cách 1: Qua GitHub UI (Khuyến nghị)**
1. Mở browser → GitHub repository
2. Click tab **Actions**
3. Chọn workflow **Infrastructure Provisioning & Configuration** (failed)
4. Click nút **Re-run all jobs**

**Cách 2: Chạy Terraform local (Nhanh hơn)**
```bash
cd terraform
terraform apply -var="key_name=productx-key"
```

---

## 📚 Tài liệu chi tiết

Nếu cần hiểu rõ hơn hoặc gặp vấn đề:

1. **[QUICK_FIX_IAM_ROLE_ERROR.md](./QUICK_FIX_IAM_ROLE_ERROR.md)**
   - Hướng dẫn chi tiết từng bước
   - Giải thích tại sao lỗi xảy ra
   - Cách tránh lỗi trong tương lai

2. **[TROUBLESHOOTING_QUICK_REFERENCE.md](./TROUBLESHOOTING_QUICK_REFERENCE.md)**
   - Error #14: EntityAlreadyExists: IAM Role already exists
   - 13+ lỗi khác và cách fix nhanh

3. **[SCRIPTS_GUIDE.md](./SCRIPTS_GUIDE.md)**
   - Hướng dẫn sử dụng tất cả cleanup scripts
   - Khi nào dùng script nào

---

## 🔍 Verify cleanup thành công

Sau khi chạy cleanup script, verify IAM role đã bị xóa:

```bash
aws iam get-role --role-name productx-eks-cluster-aws-load-balancer-controller
```

**Kết quả mong đợi:**
```
An error occurred (NoSuchEntity) when calling the GetRole operation: 
The role with name productx-eks-cluster-aws-load-balancer-controller cannot be found.
```

✅ Nếu thấy error "NoSuchEntity" → Đã xóa thành công!

❌ Nếu thấy role details → Chưa xóa, chạy lại script

---

## ⚠️ Nếu cleanup script không chạy được

### Lỗi: "Permission denied"

```bash
# Cho phép thực thi
chmod +x cleanup-iam-roles.sh
./cleanup-iam-roles.sh
```

### Lỗi: "AWS credentials not configured"

```bash
# Cấu hình AWS CLI
aws configure

# Nhập:
# - AWS Access Key ID: [từ GitHub Secret AWS_ACCESS_KEY_ID]
# - AWS Secret Access Key: [từ GitHub Secret AWS_SECRET_ACCESS_KEY]
# - Default region: ap-southeast-1
# - Default output format: json
```

### Lỗi: "Access Denied" khi xóa IAM role

```bash
# User không có quyền xóa IAM roles
# Fix bằng cách thêm IAM permissions
./fix-iam-permissions.sh devops-final-ci
```

---

## 🆘 Alternative: Cleanup toàn bộ resources

Nếu cleanup-iam-roles.sh không work, dùng script mạnh hơn:

```bash
# Cleanup tất cả leftover resources
./cleanup-failed-resources.sh

# Hoặc full cleanup (destroy everything)
./full-cleanup.sh
```

**Lưu ý:** `full-cleanup.sh` sẽ xóa toàn bộ infrastructure, cần deploy lại từ đầu.

---

## ✅ Checklist

- [ ] Chạy `cleanup-iam-roles.sh` thành công
- [ ] Verify IAM role đã bị xóa (command trên)
- [ ] Đợi 1-2 phút
- [ ] Re-run GitHub Actions workflow
- [ ] Check workflow logs để verify deployment thành công

---

## 📞 Cần trợ giúp?

Nếu vẫn gặp vấn đề:

1. Check logs chi tiết:
   ```bash
   # GitHub Actions logs
   Repository → Actions → Click failed workflow → Expand steps
   
   # Terraform logs (nếu chạy local)
   cd terraform
   export TF_LOG=DEBUG
   terraform apply -var="key_name=productx-key" 2>&1 | tee debug.log
   ```

2. Đọc tài liệu troubleshooting:
   - [QUICK_FIX_IAM_ROLE_ERROR.md](./QUICK_FIX_IAM_ROLE_ERROR.md)
   - [TROUBLESHOOTING_QUICK_REFERENCE.md](./TROUBLESHOOTING_QUICK_REFERENCE.md)

3. Check AWS resources:
   ```bash
   # List IAM roles
   aws iam list-roles --query "Roles[?contains(RoleName, 'productx')].RoleName"
   
   # List EKS clusters
   aws eks list-clusters --region ap-southeast-1
   
   # List EC2 instances
   aws ec2 describe-instances \
     --filters "Name=tag:Project,Values=productx" \
     --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name}"
   ```

---

## 🎉 Sau khi fix thành công

Deployment sẽ tiếp tục và hoàn thành trong 30-40 phút:

1. ✅ Terraform Apply (20-30 phút)
   - Tạo VPC, EKS cluster, EC2 instance
   - Tạo IAM roles, Security Groups
   - Cài AWS Load Balancer Controller

2. ✅ Ansible Configuration (5-10 phút)
   - Cài PostgreSQL 16
   - Cài NFS server
   - Cấu hình database

3. ✅ Kubernetes Setup (3-5 phút)
   - Apply namespace, configmap, secrets
   - Apply PV/PVC
   - Apply services, ingress

4. ✅ Application Deployment (3-5 phút)
   - Deploy backend pods
   - Deploy frontend pods
   - Wait for rollout

**Tổng thời gian:** ~40-50 phút

---

**Thời gian fix:** 5 phút

**Độ khó:** ⭐ (Rất dễ)

**Success rate:** 99%
