# DevOps Final - ProductX Management System

Hệ thống quản lý sản phẩm với kiến trúc microservices triển khai trên Amazon EKS.

## 🎉 Latest Updates

**✅ All Critical Bugs Fixed (11/11)**
- Security vulnerabilities patched
- Performance optimizations applied
- Comprehensive documentation added

See [BUGS_FIXED_SUMMARY.md](./BUGS_FIXED_SUMMARY.md) for details.

---

## 📚 Tài liệu hướng dẫn

### 🆕 New Documentation (Essential)
1. **[BUGS_FIXED_SUMMARY.md](./BUGS_FIXED_SUMMARY.md)** - ⭐ Summary of all bug fixes
2. **[GITHUB_SECRETS.md](./GITHUB_SECRETS.md)** - ⭐ Complete GitHub secrets configuration
3. **[WORKFLOW_SEQUENCE.md](./WORKFLOW_SEQUENCE.md)** - ⭐ CI/CD workflow execution guide
4. **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - ⭐ Comprehensive testing procedures
5. **[MONITORING_GUIDE.md](./MONITORING_GUIDE.md)** - ⭐ Monitoring & observability guide
6. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - ⭐ Quick command reference

### 🌐 Multi-ALB & SSL Certificates (NEW)
1. **[QUICK_START_MULTI_ALB.md](./QUICK_START_MULTI_ALB.md)** - ⚡ Quick setup guide (5 minutes)
2. **[HOSTINGER_SUBDOMAIN_SETUP.md](./HOSTINGER_SUBDOMAIN_SETUP.md)** - 🔐 DNS & SSL configuration on Hostinger
3. **[MULTI_ALB_DEPLOYMENT_GUIDE.md](./MULTI_ALB_DEPLOYMENT_GUIDE.md)** - 🏗️ Architecture & deployment details
4. **[SSL_CERTIFICATES_README.md](./SSL_CERTIFICATES_README.md)** - 📚 Comprehensive SSL reference
5. **[CHANGELOG_MULTI_ALB.md](./CHANGELOG_MULTI_ALB.md)** - 📝 All changes and migration guide

### 🎯 Original Documentation
1. **[GITHUB_SECRETS_GUIDE.md](./GITHUB_SECRETS_GUIDE.md)** - Hướng dẫn chi tiết cách tìm và thêm GitHub Secrets
2. **[PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md)** - Hướng dẫn triển khai production từng bước
3. **[FIX_IAM_PERMISSIONS.md](./FIX_IAM_PERMISSIONS.md)** - Fix lỗi IAM permissions và instance types
4. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Kiến trúc hệ thống chi tiết

### 🚨 Quick Fixes
- **[QUICK_FIX_IAM_ROLE_ERROR.md](./QUICK_FIX_IAM_ROLE_ERROR.md)** - Fix lỗi "IAM Role already exists" (2 phút)
- **[FIX_ANSIBLE_CALLBACK.md](./FIX_ANSIBLE_CALLBACK.md)** - Fix lỗi Ansible callback plugin (đã fix)
- **[TROUBLESHOOTING_QUICK_REFERENCE.md](./TROUBLESHOOTING_QUICK_REFERENCE.md)** - Quick fixes cho 15+ lỗi thường gặp
- **[SCRIPTS_GUIDE.md](./SCRIPTS_GUIDE.md)** - Hướng dẫn sử dụng cleanup scripts

### 📖 Nội dung chính
- [Tổng quan](#tổng-quan)
- [Yêu cầu](#yêu-cầu)
- [Cài đặt nhanh](#cài-đặt-nhanh)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## Tổng quan

ProductX là hệ thống quản lý sản phẩm enterprise-grade với:

### 🏗️ Kiến trúc
- **Frontend**: React 18 + Vite 5
- **Backend**: Spring Boot 3.x + Java 21
- **Database**: PostgreSQL 16
- **Infrastructure**: Amazon EKS (Kubernetes 1.28+)
- **CI/CD**: GitHub Actions
- **Storage**: NFS Persistent Volume
- **Monitoring**: Prometheus + Grafana

### ✨ Tính năng
- ✅ Auto-scaling (HPA) cho frontend và backend
- ✅ Rolling updates với zero-downtime
- ✅ Self-healing containers
- ✅ HTTPS với ACM Certificate
- ✅ **Multi-ALB Architecture** - 3 ALB riêng biệt cho Production, Staging, Monitoring
- ✅ **SSL Certificates** - Tự động tạo và validate certificates cho subdomain
- ✅ Infrastructure as Code (Terraform)
- ✅ Configuration Management (Ansible)
- ✅ Container security scanning (Trivy)
- ✅ Secrets scanning (TruffleHog)

---

## Yêu cầu

### Tài khoản cần có
- ✅ AWS Account (Free Tier hoặc có credit)
- ✅ GitHub Account
- ✅ Docker Hub Account
- ✅ Domain (Optional - cho HTTPS)

### Công cụ cần cài
- AWS CLI 2.x
- Git
- (Optional) Terraform 1.7+
- (Optional) kubectl

**Lưu ý:** Bootstrap script sẽ tự động cài Terraform nếu chưa có.

---

## Cài đặt nhanh

### Bước 1: Clone repository

```bash
git clone https://github.com/your-username/DevOps_Final.git
cd DevOps_Final
```

### Bước 2: Cấu hình AWS

```bash
# Cấu hình AWS CLI
aws configure

# Tạo SSH key pair trên AWS (Region: ap-southeast-1)
# EC2 Console → Key Pairs → Create key pair
# Name: productx-key
# Download file productx-key.pem vào thư mục dự án
chmod 400 productx-key.pem
```

### Bước 3: Chạy Bootstrap Script

```bash
# Tạo S3 bucket và DynamoDB table cho Terraform state
chmod +x bootstrap-backend.sh
./bootstrap-backend.sh

# Lưu bucket name từ output (cần cho GitHub Secret)
```

### Bước 4: Cấu hình GitHub Secrets

**Xem hướng dẫn chi tiết:** [GITHUB_SECRETS_GUIDE.md](./GITHUB_SECRETS_GUIDE.md)

Vào GitHub repo → Settings → Secrets and variables → Actions

Thêm các secrets sau:

| Secret Name | Mô tả | Xem hướng dẫn |
|------------|-------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | [Link](./GITHUB_SECRETS_GUIDE.md#1-aws_access_key_id--aws_secret_access_key) |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | [Link](./GITHUB_SECRETS_GUIDE.md#1-aws_access_key_id--aws_secret_access_key) |
| `AWS_KEY_NAME` | Tên SSH key pair | [Link](./GITHUB_SECRETS_GUIDE.md#2-aws_key_name) |
| `EC2_SSH_PRIVATE_KEY` | Nội dung file .pem | [Link](./GITHUB_SECRETS_GUIDE.md#3-ec2_ssh_private_key) |
| `EKS_CLUSTER_NAME` | Tên EKS cluster | [Link](./GITHUB_SECRETS_GUIDE.md#4-eks_cluster_name) |
| `DB_PASSWORD` | Password PostgreSQL | [Link](./GITHUB_SECRETS_GUIDE.md#5-db_password) |
| `DOCKER_USERNAME` | Docker Hub username | [Link](./GITHUB_SECRETS_GUIDE.md#6-docker_username--docker_password) |
| `DOCKER_PASSWORD` | Docker Hub token | [Link](./GITHUB_SECRETS_GUIDE.md#6-docker_username--docker_password) |
| `TF_BACKEND_BUCKET` | S3 bucket name | [Link](./GITHUB_SECRETS_GUIDE.md#7-tf_backend_bucket) |
| `DOMAIN_NAME` (Optional) | Domain của bạn | [Link](./GITHUB_SECRETS_GUIDE.md#8-domain_name-optional) |

### Bước 5: Push code và Deploy

```bash
# Khởi tạo Git repository
git init
git remote add origin https://github.com/your-username/DevOps_Final.git

# Commit và push
git add .
git commit -m "Initial commit: ProductX Management System"
git branch -M main
git push -u origin main
```

**⚠️ Push code sẽ tự động trigger CI/CD pipeline!**

### Bước 6: Theo dõi Deployment

```
1. Vào GitHub → Actions
2. Xem workflow "Infrastructure Provisioning" (30-40 phút)
3. Approve manual deployment khi được yêu cầu
4. Đợi "Build & Release Docker" (5-10 phút)
5. Đợi "Continuous Deployment" (3-5 phút)
```

### Bước 7: Truy cập ứng dụng

```bash
# Lấy ALB URL
kubectl get ingress -n productx

# Truy cập qua browser
http://<alb-url>
```

**Nếu có domain:** Xem [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md#cấu-hình-domain-hostinger)

---

## Cấu trúc dự án

```
DevOps_Final/
├── app/
│   ├── backend/common/          # Spring Boot service
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── pom.xml
│   └── frontend/                # React + Vite UI
│       ├── src/
│       ├── Dockerfile
│       └── package.json
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                  # VPC, EKS, EC2
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf               # S3 remote state
├── ansible/                     # Configuration Management
│   ├── playbooks/
│   │   ├── site.yml            # Main playbook
│   │   ├── database.yml        # PostgreSQL setup
│   │   └── nfs-server.yml      # NFS setup
│   ├── inventory/
│   │   └── hosts.ini.example
│   └── ansible.cfg
├── kubernetes/                  # K8s Manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── nfs-pv.yaml
│   ├── ingress.yaml
│   └── base/
│       ├── backend/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   └── hpa.yaml
│       └── frontend/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── hpa.yaml
├── .github/workflows/           # CI/CD Pipelines
│   ├── infrastructure-cd.yml   # Terraform + Ansible
│   ├── main-ci.yml             # Build Docker images
│   └── deploy-cd.yml           # Deploy to EKS
├── bootstrap-backend.sh         # Setup Terraform backend
├── docker-compose.yml           # Local development
├── GITHUB_SECRETS_GUIDE.md      # Hướng dẫn Secrets
├── PRODUCTION_DEPLOYMENT_GUIDE.md # Hướng dẫn Deploy
├── ARCHITECTURE.md              # Kiến trúc chi tiết
└── README.md                    # File này
```

---

## CI/CD Pipeline

### 1. Infrastructure Provisioning (infrastructure-cd.yml)

**Trigger:** Push to main (terraform/** or ansible/**)

```
Security Scan → Terraform Plan → Manual Approval → Terraform Apply
    ↓
Ansible Configuration (DB + NFS) → Kubernetes Base Setup
```

**Thời gian:** 30-40 phút

### 2. Build & Release (main-ci.yml)

**Trigger:** Push to main (app/**)

```
Wait for Infrastructure → Build Backend → Build Frontend
    ↓                          ↓              ↓
                        Trivy Scan      Trivy Scan
                             ↓              ↓
                        Push to Hub    Push to Hub
```

**Thời gian:** 5-10 phút

### 3. Continuous Deployment (deploy-cd.yml)

**Trigger:** After "Build & Release" success

```
Configure kubectl → Update Manifests → Deploy to EKS
    ↓
Rolling Update → Wait for Rollout → Verify
```

**Thời gian:** 3-5 phút

---

## Monitoring

### Kubernetes Resources

```bash
# Xem tất cả resources
kubectl get all -n productx

# Xem pods
kubectl get pods -n productx -o wide

# Xem logs
kubectl logs -f deployment/backend -n productx
kubectl logs -f deployment/frontend -n productx

# Xem events
kubectl get events -n productx --sort-by='.lastTimestamp'

# Xem HPA status
kubectl get hpa -n productx

# Xem Ingress
kubectl get ingress -n productx
```

### Application Health

```bash
# Backend health check
curl http://<alb-url>/api/actuator/health

# Frontend health check
curl http://<alb-url>/
```

---

## Troubleshooting

### ❌ Pods không start

```bash
# Xem logs
kubectl logs <pod-name> -n productx

# Xem events
kubectl describe pod <pod-name> -n productx

# Xem previous logs (nếu pod restart)
kubectl logs <pod-name> -n productx --previous
```

### ❌ IAM Role already exists

```bash
# Quick fix (2 phút)
./cleanup-iam-roles.sh
```

**Chi tiết:** [QUICK_FIX_IAM_ROLE_ERROR.md](./QUICK_FIX_IAM_ROLE_ERROR.md)

### ❌ Elastic IP limit exceeded

```bash
# Quick fix
./release-elastic-ips.sh
```

### ❌ Resources already exist (KMS, CloudWatch, etc.)

```bash
# Quick fix
./cleanup-failed-resources.sh
```

### ❌ Complete cleanup and restart

```bash
# Run full cleanup
./full-cleanup.sh

# Wait 5-10 minutes, then re-deploy
cd terraform
terraform apply -var="key_name=productx-key"
```

**Xem thêm:** 
- [QUICK_FIX_IAM_ROLE_ERROR.md](./QUICK_FIX_IAM_ROLE_ERROR.md) - Fix lỗi IAM Role conflict (2 phút)
- [TROUBLESHOOTING_QUICK_REFERENCE.md](./TROUBLESHOOTING_QUICK_REFERENCE.md) - Quick fixes cho 14+ lỗi thường gặp
- [FIX_IAM_PERMISSIONS.md](./FIX_IAM_PERMISSIONS.md) - Fix IAM và resource issues
- [SCRIPTS_GUIDE.md](./SCRIPTS_GUIDE.md) - Hướng dẫn sử dụng tất cả scripts
- [PRODUCTION_DEPLOYMENT_GUIDE.md - Troubleshooting](./PRODUCTION_DEPLOYMENT_GUIDE.md#troubleshooting)

---

## Cleanup

### ❌ Pods không start

```bash
# Xem logs
kubectl logs <pod-name> -n productx

# Xem events
kubectl describe pod <pod-name> -n productx

# Xem previous logs (nếu pod restart)
kubectl logs <pod-name> -n productx --previous
```

### ❌ Database connection failed

```bash
# Test connectivity từ pod
kubectl exec -it <backend-pod> -n productx -- nc -zv <db-ip> 5432

# Kiểm tra ConfigMap
kubectl get configmap app-config -n productx -o yaml

# Kiểm tra Secrets
kubectl get secret app-secrets -n productx -o yaml
```

### ❌ NFS mount failed

```bash
# Kiểm tra PV/PVC
kubectl get pv,pvc -n productx

# Describe PVC
kubectl describe pvc nfs-uploads-pvc -n productx

# SSH vào DB server và check NFS
ssh -i productx-key.pem ubuntu@<db-ip>
sudo systemctl status nfs-kernel-server
sudo exportfs -v
```

### ❌ ALB không được tạo

```bash
# Kiểm tra AWS Load Balancer Controller
kubectl get deployment -n kube-system aws-load-balancer-controller

# Xem logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Describe Ingress
kubectl describe ingress app-ingress -n productx
```

**Xem thêm:** [PRODUCTION_DEPLOYMENT_GUIDE.md - Troubleshooting](./PRODUCTION_DEPLOYMENT_GUIDE.md#troubleshooting)

---

## Testing

### Quick Testing Commands

```bash
# Set your domain
DOMAIN="www.tranduchuy.site"

# Run complete E2E test suite
./e2e-test.sh

# Or test manually
curl https://$DOMAIN/actuator/health
curl https://$DOMAIN/api/products
```

**For comprehensive testing guide, see:** [TESTING_GUIDE.md](./TESTING_GUIDE.md)

### Test Horizontal Pod Autoscaling

```bash
# Tạo load generator
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# Trong pod, chạy:
while true; do wget -q -O- http://backend-svc.productx.svc.cluster.local:8080/api/products; done

# Terminal khác, xem HPA scaling:
kubectl get hpa -n productx -w
```

### Test Self-healing

```bash
# Xóa một pod
kubectl delete pod <pod-name> -n productx

# Kubernetes sẽ tự động tạo pod mới
kubectl get pods -n productx -w
```

---

## Monitoring & Observability

### Access Monitoring Tools

```bash
# Grafana (via port forward)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open: http://localhost:3000
# Default: admin / prom-operator

# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open: http://localhost:9090
```

### Key Metrics to Monitor

```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) by (pod)

# Memory usage by pod
sum(container_memory_working_set_bytes{namespace="productx"}) by (pod)

# HTTP request rate
rate(http_server_requests_seconds_count{namespace="productx"}[5m])

# Error rate
sum(rate(http_server_requests_seconds_count{namespace="productx",status=~"5.."}[5m])) / 
sum(rate(http_server_requests_seconds_count{namespace="productx"}[5m])) * 100
```

**For complete monitoring guide, see:** [MONITORING_GUIDE.md](./MONITORING_GUIDE.md)

---

## Cleanup

### Xóa ứng dụng (giữ infrastructure)

```bash
kubectl delete namespace productx
```

### Xóa toàn bộ infrastructure

```bash
# Qua GitHub Actions
1. Actions → Infrastructure Provisioning
2. Run workflow
3. Action: destroy
4. Confirm: DESTROY

# Hoặc local
cd terraform
terraform destroy -var="key_name=productx-key"
```

---

## So sánh với kiến trúc mẫu

| Thành phần | Example | DevOps_Final | Lý do thay đổi |
|-----------|---------|--------------|----------------|
| Application | Document Management | Product Management | Tránh trùng code |
| Database | PostgreSQL | PostgreSQL | Giữ nguyên |
| Code Quality | SonarQube (self-hosted) | (Removed) | Đơn giản hóa |
| Namespace | devops-final | productx | Tên riêng biệt |
| Docker Images | document-management-* | productx-* | Tên riêng biệt |

---

## Tài liệu tham khảo

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [React Documentation](https://react.dev/)

---

## License

This project is for educational purposes (DevOps Final Exam).

---

## Contributors

- Your Name - DevOps Engineer
- GitHub: [@yourusername](https://github.com/yourusername)

---

**🚀 Happy Deploying!**
