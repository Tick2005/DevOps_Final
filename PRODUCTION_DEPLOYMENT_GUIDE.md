# Hướng dẫn triển khai môi trường Production

## 📋 Mục lục
1. [Tổng quan quy trình](#tổng-quan-quy-trình)
2. [Chuẩn bị môi trường](#chuẩn-bị-môi-trường)
3. [Cấu hình AWS](#cấu-hình-aws)
4. [Chạy Bootstrap Script](#chạy-bootstrap-script)
5. [Cấu hình GitHub](#cấu-hình-github)
6. [Push code và Deploy](#push-code-và-deploy)
7. [Cấu hình Domain (Hostinger)](#cấu-hình-domain-hostinger)
8. [Kiểm tra logs](#kiểm-tra-logs)
9. [Truy cập HTTPS](#truy-cập-https)
10. [Troubleshooting](#troubleshooting)

---

## Tổng quan quy trình

```
┌─────────────────┐
│ 1. Chuẩn bị AWS │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. Bootstrap    │ ← Tạo S3, DynamoDB
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. Setup GitHub │ ← Thêm Secrets
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. Push Code    │ ← Trigger CI/CD
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5. Cấu hình DNS │ ← Point domain
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 6. Truy cập App │ ← HTTPS ready!
└─────────────────┘
```

**Thời gian ước tính:** 45-60 phút

---

## Chuẩn bị môi trường

### Yêu cầu hệ thống

**Máy tính local:**
- OS: Windows 10/11, macOS, hoặc Linux
- RAM: Tối thiểu 4GB
- Disk: Tối thiểu 10GB trống
- Internet: Kết nối ổn định

**Tài khoản cần có:**
- ✅ AWS Account (Free Tier hoặc có credit)
- ✅ GitHub Account
- ✅ Docker Hub Account
- ✅ Domain (Hostinger/Namecheap) - Optional cho HTTPS

### Cài đặt công cụ

#### 1. AWS CLI

**Windows:**
```powershell
# Download installer
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Kiểm tra
aws --version
```

**macOS:**
```bash
# Dùng Homebrew
brew install awscli

# Hoặc download installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Kiểm tra
aws --version
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Kiểm tra
aws --version
```

#### 2. Git

**Windows:**
```powershell
# Download từ: https://git-scm.com/download/win
# Hoặc dùng winget
winget install Git.Git
```

**macOS:**
```bash
brew install git
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install git
```

#### 3. Terraform (Optional - script sẽ tự cài)

**Tất cả platforms:**
```bash
# Script bootstrap-backend.sh sẽ tự động cài Terraform
# Hoặc cài thủ công: https://developer.hashicorp.com/terraform/downloads
```

---

## Cấu hình AWS

### Bước 1: Tạo IAM User

#### 1.1. Đăng nhập AWS Console
```
URL: https://console.aws.amazon.com/
```

#### 1.2. Tạo IAM User mới
```
1. Vào IAM Console: https://console.aws.amazon.com/iam/
2. Sidebar → Users → Create user
3. User name: productx-ci-user
4. Click "Next"
```

#### 1.3. Gán quyền (Permissions)
```
Chọn: "Attach policies directly"

Thêm các policies sau:
✅ AmazonEC2FullAccess
✅ AmazonEKSClusterPolicy  
✅ AmazonEKSWorkerNodePolicy
✅ AmazonVPCFullAccess
✅ IAMFullAccess
✅ AmazonS3FullAccess
✅ AmazonDynamoDBFullAccess
✅ CloudWatchLogsFullAccess (BẮT BUỘC - cho EKS logs)
✅ AWSKeyManagementServicePowerUser (BẮT BUỘC - cho KMS encryption)
✅ AmazonRoute53FullAccess (nếu dùng domain)
✅ AWSCertificateManagerFullAccess (nếu dùng HTTPS)

Click "Next" → "Create user"
```

**⚠️ LƯU Ý QUAN TRỌNG:**
- CloudWatchLogsFullAccess và AWSKeyManagementServicePowerUser là BẮT BUỘC
- Nếu thiếu sẽ gặp lỗi AccessDeniedException khi chạy Terraform
- Xem chi tiết: [FIX_IAM_PERMISSIONS.md](./FIX_IAM_PERMISSIONS.md)

#### 1.4. Tạo Access Key
```
1. Click vào user vừa tạo
2. Tab "Security credentials"
3. Scroll xuống "Access keys"
4. Click "Create access key"
5. Chọn "Command Line Interface (CLI)"
6. Check "I understand..." → Next
7. Description: "ProductX CI/CD Pipeline"
8. Click "Create access key"
9. ⚠️ LƯU NGAY: Access Key ID và Secret Access Key
```

**Lưu thông tin:**
```
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### Bước 2: Tạo SSH Key Pair

#### 2.1. Vào EC2 Console
```
URL: https://console.aws.amazon.com/ec2/
Region: Chọn ap-southeast-1 (Singapore)
```

#### 2.2. Tạo Key Pair
```
1. Sidebar → Network & Security → Key Pairs
2. Click "Create key pair"
3. Name: productx-key
4. Key pair type: RSA
5. Private key file format: .pem
6. Click "Create key pair"
7. File productx-key.pem sẽ tự động download
```

#### 2.3. Lưu file .pem
```bash
# Linux/macOS: Di chuyển vào thư mục dự án
mv ~/Downloads/productx-key.pem ~/DevOps_Final/

# Windows: Copy file vào thư mục dự án
# Đảm bảo file nằm trong DevOps_Final/productx-key.pem

# Set permissions (Linux/macOS)
chmod 400 productx-key.pem
```

### Bước 3: Cấu hình AWS CLI

```bash
aws configure

# Nhập thông tin:
AWS Access Key ID: (paste AWS_ACCESS_KEY_ID)
AWS Secret Access Key: (paste AWS_SECRET_ACCESS_KEY)
Default region name: ap-southeast-1
Default output format: json
```

**Kiểm tra cấu hình:**
```bash
aws sts get-caller-identity
```

Kết quả mong đợi:
```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/productx-ci-user"
}
```

---

## Chạy Bootstrap Script

### Bước 1: Clone repository

```bash
git clone https://github.com/your-username/DevOps_Final.git
cd DevOps_Final
```

### Bước 2: Cấu hình file .env

```bash
# Copy file mẫu
cp .env.example .env

# Chỉnh sửa file .env
nano .env  # hoặc dùng editor khác
```

**Nội dung file .env:**
```bash
# AWS Configuration
AWS_KEY_NAME=productx-key              # Tên key pair (KHÔNG có .pem)
DB_PASSWORD=SecurePassword123!         # Password cho PostgreSQL

# Optional - Chỉ điền nếu có domain
DOMAIN_NAME=                           # VD: myapp.online
ENABLE_HTTPS=false                     # Đặt true khi có domain
```

### Bước 3: Chạy bootstrap-backend.sh

Script này sẽ tạo S3 bucket và DynamoDB table cho Terraform remote state.

```bash
# Cấp quyền thực thi
chmod +x bootstrap-backend.sh

# Chạy script
./bootstrap-backend.sh
```

**Output mong đợi:**
```
=============================================
     REMOTE STATE BACKEND ĐÃ SẴN SÀNG
=============================================

📦 S3 BUCKET:
   - Name: productx-tfstate-1234567890
   - Region: ap-southeast-1
   - Versioning: Enabled
   - Encryption: AES256

🗄️  DYNAMODB TABLE:
   - Name: productx-tflock
   - Region: ap-southeast-1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Copy value này:

productx-tfstate-1234567890
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**⚠️ LƯU Ý:** Copy bucket name này, cần dùng cho GitHub Secret!

---

## Cấu hình GitHub

### Bước 1: Tạo repository trên GitHub

```
1. Vào https://github.com/new
2. Repository name: DevOps_Final
3. Visibility: Private (khuyến nghị)
4. KHÔNG check "Initialize with README"
5. Click "Create repository"
```

### Bước 2: Thêm GitHub Secrets

```
1. Vào repository → Settings
2. Sidebar → Secrets and variables → Actions
3. Click "New repository secret"
```

**Danh sách Secrets cần thêm:**

| Secret Name | Giá trị | Nguồn |
|------------|---------|-------|
| `AWS_ACCESS_KEY_ID` | `AKIAIOSFODNN7EXAMPLE` | Từ IAM User |
| `AWS_SECRET_ACCESS_KEY` | `wJalrXUtnFEMI/K7MDENG/...` | Từ IAM User |
| `AWS_KEY_NAME` | `productx-key` | Tên key pair |
| `EC2_SSH_PRIVATE_KEY` | `-----BEGIN RSA PRIVATE KEY-----...` | Nội dung file .pem |
| `EKS_CLUSTER_NAME` | `productx-eks-cluster` | Tự đặt tên |
| `DB_PASSWORD` | `SecurePassword123!` | Từ file .env |
| `DOCKER_USERNAME` | `yourusername` | Docker Hub username |
| `DOCKER_PASSWORD` | `dckr_pat_...` | Docker Hub token |
| `TF_BACKEND_BUCKET` | `productx-tfstate-1234567890` | Từ bootstrap script |

**Optional (nếu có domain):**
| Secret Name | Giá trị | Nguồn |
|------------|---------|-------|
| `DOMAIN_NAME` | `myapp.online` | Domain của bạn |

**Chi tiết cách lấy từng secret:** Xem file [GITHUB_SECRETS_GUIDE.md](./GITHUB_SECRETS_GUIDE.md)

### Bước 3: Xác nhận Secrets

Sau khi thêm xong, kiểm tra danh sách:
```
✅ AWS_ACCESS_KEY_ID
✅ AWS_SECRET_ACCESS_KEY
✅ AWS_KEY_NAME
✅ EC2_SSH_PRIVATE_KEY
✅ EKS_CLUSTER_NAME
✅ DB_PASSWORD
✅ DOCKER_USERNAME
✅ DOCKER_PASSWORD
✅ TF_BACKEND_BUCKET
```

---

## Push code và Deploy

### Bước 1: Khởi tạo Git repository

```bash
cd DevOps_Final

# Khởi tạo git (nếu chưa có)
git init

# Thêm remote
git remote add origin https://github.com/your-username/DevOps_Final.git

# Kiểm tra remote
git remote -v
```

### Bước 2: Commit code

```bash
# Thêm tất cả files
git add .

# Commit
git commit -m "Initial commit: ProductX Management System"

# Đổi branch thành main (nếu cần)
git branch -M main
```

### Bước 3: Push code lên GitHub

```bash
# Push lần đầu
git push -u origin main
```

**⚠️ LƯU Ý:** Push code sẽ tự động trigger CI/CD pipeline!

### Bước 4: Theo dõi CI/CD Pipeline

```
1. Vào GitHub repository
2. Click tab "Actions"
3. Xem workflow đang chạy
```

**Workflow sẽ chạy theo thứ tự:**
```
1. Infrastructure Provisioning (30-40 phút)
   ├─ Security Scan
   ├─ Terraform Plan
   ├─ Terraform Apply (cần manual approval)
   ├─ Ansible Configuration
   └─ Kubernetes Setup

2. Build & Release Docker (5-10 phút)
   ├─ Build Backend Image
   ├─ Trivy Security Scan
   ├─ Build Frontend Image
   └─ Push to Docker Hub

3. Continuous Deployment (3-5 phút)
   ├─ Deploy to EKS
   ├─ Rolling Update
   └─ Verify Deployment
```

### Bước 5: Manual Approval (Infrastructure)

Khi Terraform Plan hoàn tất, workflow sẽ dừng lại chờ approval:

```
1. Vào Actions → Click vào workflow run
2. Xem Terraform Plan output
3. Click "Review deployments"
4. Check "production-infrastructure"
5. Click "Approve and deploy"
```

**⏳ Đợi 30-40 phút để infrastructure được tạo**

### Bước 6: Lấy thông tin sau khi deploy

Sau khi workflow hoàn tất, lấy thông tin:

```bash
# Configure kubectl
aws eks update-kubeconfig --name productx-eks-cluster --region ap-southeast-1

# Lấy ALB URL
kubectl get ingress -n productx

# Output:
# NAME          CLASS   HOSTS   ADDRESS                                    PORTS
# app-ingress   alb     *       k8s-productx-xxx.ap-southeast-1.elb.amazonaws.com   80, 443
```

**Lưu ALB URL:** `k8s-productx-xxx.ap-southeast-1.elb.amazonaws.com`

---

## Cấu hình Domain (Hostinger)

### Option 1: Sử dụng ALB URL trực tiếp (Không cần domain)

```
Truy cập: http://k8s-productx-xxx.ap-southeast-1.elb.amazonaws.com
```

**✅ Ưu điểm:** Miễn phí, không cần cấu hình
**❌ Nhược điểm:** URL dài, không có HTTPS

### Option 2: Cấu hình Domain với Hostinger

#### Bước 1: Mua domain trên Hostinger

```
1. Truy cập: https://www.hostinger.com/domain-name-search
2. Tìm domain (VD: productx.online)
3. Thêm vào giỏ hàng và thanh toán
4. Đợi domain active (5-10 phút)
```

#### Bước 2: Lấy Public IP của ALB

```bash
# Resolve ALB URL sang IP
nslookup k8s-productx-xxx.ap-southeast-1.elb.amazonaws.com

# Hoặc
dig k8s-productx-xxx.ap-southeast-1.elb.amazonaws.com

# Lưu IP đầu tiên (VD: 52.77.123.456)
```

#### Bước 3: Cấu hình DNS trên Hostinger

```
1. Đăng nhập Hostinger: https://hpanel.hostinger.com/
2. Domains → Click vào domain của bạn
3. DNS / Name Servers → DNS Records
4. Xóa tất cả A records cũ (nếu có)
5. Thêm A record mới:
```

**A Record cho root domain:**
```
Type: A
Name: @ (hoặc để trống)
Points to: 52.77.123.456 (IP của ALB)
TTL: 3600
```

**A Record cho www:**
```
Type: A
Name: www
Points to: 52.77.123.456 (IP của ALB)
TTL: 3600
```

**CNAME Record cho Grafana (Optional):**
```
Type: CNAME
Name: grafana
Points to: k8s-productx-xxx.ap-southeast-1.elb.amazonaws.com
TTL: 3600
```

#### Bước 4: Đợi DNS propagation

```bash
# Kiểm tra DNS đã propagate chưa (5-15 phút)
nslookup productx.online

# Hoặc dùng online tool
https://dnschecker.org/
```

#### Bước 5: Cập nhật DOMAIN_NAME secret

```
1. GitHub → Repository → Settings → Secrets
2. Thêm/Update secret:
   Name: DOMAIN_NAME
   Value: productx.online
3. Click "Update secret"
```

#### Bước 6: Re-run Infrastructure workflow

```
1. Actions → Infrastructure Provisioning
2. Click "Re-run all jobs"
3. Workflow sẽ tự động:
   - Tạo ACM Certificate
   - Cấu hình ALB với HTTPS
   - Update Ingress với certificate
```

**⏳ Đợi 5-10 phút để certificate được validate**

---

## Kiểm tra logs

### 1. GitHub Actions Logs

```
1. Repository → Actions
2. Click vào workflow run
3. Click vào job cần xem
4. Xem logs chi tiết
```

### 2. Kubernetes Pods Logs

```bash
# List tất cả pods
kubectl get pods -n productx

# Xem logs của backend
kubectl logs -f deployment/backend -n productx

# Xem logs của frontend
kubectl logs -f deployment/frontend -n productx

# Xem logs của pod cụ thể
kubectl logs <pod-name> -n productx

# Xem logs 100 dòng gần nhất
kubectl logs --tail=100 deployment/backend -n productx
```

### 3. Kubernetes Events

```bash
# Xem events của namespace
kubectl get events -n productx --sort-by='.lastTimestamp'

# Xem events của pod cụ thể
kubectl describe pod <pod-name> -n productx
```

### 4. AWS CloudWatch Logs

```
1. AWS Console → CloudWatch
2. Logs → Log groups
3. Tìm log group: /aws/eks/productx-eks-cluster/cluster
4. Xem logs
```

### 5. ALB Access Logs (Optional)

```bash
# Enable ALB access logs
aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn <alb-arn> \
  --attributes Key=access_logs.s3.enabled,Value=true \
              Key=access_logs.s3.bucket,Value=<bucket-name>
```

---

## Truy cập HTTPS

### Kiểm tra HTTPS đã hoạt động

```bash
# Test HTTPS
curl -I https://productx.online

# Kết quả mong đợi:
# HTTP/2 200
# server: nginx
# ...
```

### Truy cập ứng dụng

**Production:**
```
URL: https://productx.online
```

**Grafana Monitoring:**
```
URL: https://grafana.productx.online
Username: admin
Password: (xem trong Kubernetes secret)
```

**Staging:**
```
URL: https://staging.productx.online
```

### Kiểm tra SSL Certificate

```
1. Truy cập: https://www.ssllabs.com/ssltest/
2. Nhập domain: productx.online
3. Click "Submit"
4. Đợi kết quả (2-3 phút)
```

**Kết quả mong đợi:** Grade A hoặc A+

### Force HTTPS Redirect

Ingress đã được cấu hình tự động redirect HTTP → HTTPS:

```yaml
alb.ingress.kubernetes.io/ssl-redirect: '443'
```

Test redirect:
```bash
curl -I http://productx.online
# Kết quả: HTTP/1.1 301 Moved Permanently
# Location: https://productx.online/
```

---

## Troubleshooting

### ❌ Lỗi: "AccessDeniedException: acm:RequestCertificate" hoặc "kms:TagResource"

**Nguyên nhân:** IAM user thiếu permissions cho ACM, KMS, hoặc CloudWatch Logs

**Giải pháp:**

**Option 1: Thêm IAM Policies (Khuyến nghị)**
```bash
# Vào IAM Console
1. IAM → Users → Click vào user của bạn
2. Tab "Permissions" → "Add permissions"
3. "Attach policies directly"
4. Thêm các policies:
   - CloudWatchLogsFullAccess
   - AWSKeyManagementServicePowerUser
   - AWSCertificateManagerFullAccess (nếu dùng HTTPS)
5. Click "Add permissions"
```

**Option 2: Disable HTTPS tạm thời**
```bash
# Nếu không cần HTTPS ngay
# Xóa hoặc để trống GitHub Secret: DOMAIN_NAME
# Workflow sẽ tự động skip ACM certificate
```

**Xem chi tiết:** [FIX_IAM_PERMISSIONS.md](./FIX_IAM_PERMISSIONS.md)

**Nguyên nhân:** Chưa chạy bootstrap-backend.sh hoặc TF_BACKEND_BUCKET sai

**Giải pháp:**
```bash
# Chạy lại bootstrap
./bootstrap-backend.sh

# Copy bucket name và update GitHub Secret
```

### ❌ Lỗi: "AWS credentials not configured"

**Nguyên nhân:** AWS_ACCESS_KEY_ID hoặc AWS_SECRET_ACCESS_KEY sai

**Giải pháp:**
```bash
# Test credentials locally
aws sts get-caller-identity

# Nếu lỗi, cấu hình lại
aws configure

# Update GitHub Secrets
```

### ❌ Lỗi: "Permission denied (publickey)"

**Nguyên nhân:** EC2_SSH_PRIVATE_KEY không đúng

**Giải pháp:**
```bash
# Kiểm tra file .pem
cat productx-key.pem

# Copy TOÀN BỘ nội dung (bao gồm BEGIN/END)
# Update GitHub Secret: EC2_SSH_PRIVATE_KEY
```

### ❌ Lỗi: "EKS cluster not found"

**Nguyên nhân:** EKS_CLUSTER_NAME không khớp với tên cluster thực tế

**Giải pháp:**
```bash
# List clusters
aws eks list-clusters --region ap-southeast-1

# Update GitHub Secret với tên đúng
```

### ❌ Lỗi: "Docker authentication failed"

**Nguyên nhân:** DOCKER_USERNAME hoặc DOCKER_PASSWORD sai

**Giải pháp:**
```bash
# Test login locally
docker login -u yourusername

# Tạo lại Access Token trên Docker Hub
# Update GitHub Secret: DOCKER_PASSWORD
```

### ❌ Lỗi: "Certificate validation timeout"

**Nguyên nhân:** DNS chưa propagate hoặc domain chưa point đúng

**Giải pháp:**
```bash
# Kiểm tra DNS
nslookup productx.online

# Kiểm tra nameservers
dig NS productx.online

# Đợi thêm 10-15 phút cho DNS propagation
```

### ❌ Lỗi: "Pods in CrashLoopBackOff"

**Nguyên nhân:** Database connection failed hoặc config sai

**Giải pháp:**
```bash
# Xem logs
kubectl logs <pod-name> -n productx

# Kiểm tra ConfigMap
kubectl get configmap app-config -n productx -o yaml

# Kiểm tra Secrets
kubectl get secret app-secrets -n productx -o yaml

# Kiểm tra database connectivity
kubectl exec -it <backend-pod> -n productx -- nc -zv <db-ip> 5432
```

### ❌ Lỗi: "ALB not created"

**Nguyên nhân:** AWS Load Balancer Controller chưa cài hoặc Ingress config sai

**Giải pháp:**
```bash
# Kiểm tra Load Balancer Controller
kubectl get deployment -n kube-system aws-load-balancer-controller

# Xem logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Kiểm tra Ingress
kubectl describe ingress app-ingress -n productx
```

---

## Checklist hoàn tất

Sau khi deploy xong, kiểm tra:

- [ ] Infrastructure workflow completed successfully
- [ ] Build & Release workflow completed successfully
- [ ] Deployment workflow completed successfully
- [ ] Pods đang chạy: `kubectl get pods -n productx`
- [ ] Services đã được tạo: `kubectl get svc -n productx`
- [ ] Ingress có ALB URL: `kubectl get ingress -n productx`
- [ ] Database connection OK (xem logs backend)
- [ ] NFS mount OK (xem logs backend)
- [ ] Domain đã point đúng (nếu có)
- [ ] HTTPS hoạt động (nếu có domain)
- [ ] Application accessible qua browser
- [ ] Grafana accessible (monitoring)

---

## Tài liệu tham khảo

- [GitHub Secrets Guide](./GITHUB_SECRETS_GUIDE.md)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Hostinger DNS Guide](https://support.hostinger.com/en/articles/1583227-how-to-manage-dns-records)

---

## Liên hệ hỗ trợ

Nếu gặp vấn đề không giải quyết được:

1. Kiểm tra GitHub Actions logs
2. Kiểm tra Kubernetes events và logs
3. Kiểm tra AWS CloudWatch logs
4. Tham khảo Troubleshooting section
5. Tạo issue trên GitHub repository

**Good luck with your deployment! 🚀**
