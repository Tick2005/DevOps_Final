# HƯỚNG DẪN CHI TIẾT - TRIỂN KHAI HỆ THỐNG PRODUCTX TRÊN AWS EKS

## 📋 MỤC LỤC

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Yêu cầu hệ thống](#2-yêu-cầu-hệ-thống)
3. [Chuẩn bị môi trường AWS](#3-chuẩn-bị-môi-trường-aws)
4. [Cài đặt công cụ](#4-cài-đặt-công-cụ)
5. [Cấu hình dự án](#5-cấu-hình-dự-án)
6. [Triển khai Infrastructure](#6-triển-khai-infrastructure)
7. [Cấu hình CI/CD](#7-cấu-hình-cicd)
8. [Kiểm tra và giám sát](#8-kiểm-tra-và-giám-sát)
9. [Xử lý sự cố](#9-xử-lý-sự-cố)
10. [Dọn dẹp tài nguyên](#10-dọn-dẹp-tài-nguyên)

---

## 1. TỔNG QUAN KIẾN TRÚC

### 1.1. Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Application Load    │
              │     Balancer (ALB)   │
              └──────────┬───────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────┐           ┌─────────────────┐
│   Frontend      │           │    Backend      │
│   (React)       │           │  (Spring Boot)  │
│   Pods (2-6)    │           │   Pods (2-10)   │
└─────────────────┘           └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
            ┌──────────────┐   ┌──────────────┐  ┌──────────────┐
            │  PostgreSQL  │   │  NFS Server  │  │  SonarCloud  │
            │  (EC2)       │   │  (EC2)       │  │  (External)  │
            └──────────────┘   └──────────────┘  └──────────────┘
```

### 1.2. Các thành phần chính

- **VPC**: Virtual Private Cloud với CIDR 10.0.0.0/16
- **Subnets**: 2 Public + 2 Private subnets trên 2 AZ
- **EKS Cluster**: Kubernetes cluster với managed node group
- **EC2 Instance**: Database (PostgreSQL) + NFS Server
- **ALB**: Application Load Balancer cho routing
- **SonarCloud**: Code quality analysis (thay thế SonarQube)

### 1.3. Thay đổi so với kiến trúc mẫu

| Thành phần | Kiến trúc mẫu | Kiến trúc mới | Lý do |
|------------|---------------|---------------|-------|
| Database | MongoDB (DocumentDB) | PostgreSQL | DocumentDB không còn free tier |
| Code Quality | SonarQube (EC2) | SonarCloud | Miễn phí cho public repos, không cần quản lý server |
| Application | Document Management | Product Management | Tránh trùng code |

---

## 2. YÊU CẦU HỆ THỐNG

### 2.1. Tài khoản và dịch vụ

- ✅ AWS Account (Free Tier hoặc có credit)
- ✅ GitHub Account
- ✅ Docker Hub Account
- ✅ SonarCloud Account (đăng ký tại https://sonarcloud.io)

### 2.2. Máy tính cá nhân

- **OS**: Linux, macOS, hoặc Windows (với WSL2)
- **RAM**: Tối thiểu 8GB
- **Disk**: Tối thiểu 20GB trống
- **Internet**: Kết nối ổn định

---

## 3. CHUẨN BỊ MÔI TRƯỜNG AWS

### 3.1. Tạo IAM User

1. Đăng nhập AWS Console
2. Vào **IAM** → **Users** → **Create user**
3. Đặt tên: `devops-user`
4. Chọn **Attach policies directly**
5. Gán các policies sau:
   - `AdministratorAccess` (hoặc tạo custom policy với quyền hạn chế hơn)
6. **Create user**

### 3.2. Tạo Access Key

1. Vào user vừa tạo → **Security credentials**
2. **Create access key**
3. Chọn **Command Line Interface (CLI)**
4. Lưu lại:
   - Access Key ID
   - Secret Access Key

⚠️ **LƯU Ý**: Không chia sẻ Access Key với ai!

### 3.3. Tạo SSH Key Pair

1. Vào **EC2** → **Key Pairs** → **Create key pair**
2. Đặt tên: `productx-key` (hoặc tên khác)
3. Key pair type: **RSA**
4. Private key format: **.pem**
5. **Create key pair**
6. File `.pem` sẽ được tải về → Di chuyển vào thư mục project

```bash
mv ~/Downloads/productx-key.pem ~/DevOps_Final/
chmod 400 ~/DevOps_Final/productx-key.pem
```

### 3.4. Tạo VPC và Subnets (Terraform sẽ tự động tạo)

Terraform sẽ tự động tạo:
- 1 VPC với CIDR 10.0.0.0/16
- 2 Public Subnets (10.0.0.0/20, 10.0.16.0/20)
- 2 Private Subnets (10.0.32.0/20, 10.0.48.0/20)
- Internet Gateway
- NAT Gateway
- Route Tables

---

## 4. CÀI ĐẶT CÔNG CỤ

### 4.1. AWS CLI

**Linux/macOS:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows (PowerShell):**
```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

**Cấu hình:**
```bash
aws configure
# AWS Access Key ID: <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region name: ap-southeast-1
# Default output format: json
```

**Kiểm tra:**
```bash
aws sts get-caller-identity
```

### 4.2. Terraform

**Linux:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**macOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Windows:**
```powershell
choco install terraform
```

**Kiểm tra:**
```bash
terraform version
```

### 4.3. Ansible

**Linux:**
```bash
sudo apt update
sudo apt install ansible python3-pip
pip3 install boto3 botocore
```

**macOS:**
```bash
brew install ansible
pip3 install boto3 botocore
```

**Kiểm tra:**
```bash
ansible --version
```

### 4.4. kubectl

**Linux:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**macOS:**
```bash
brew install kubectl
```

**Windows:**
```powershell
choco install kubernetes-cli
```

**Kiểm tra:**
```bash
kubectl version --client
```

---

## 5. CẤU HÌNH DỰ ÁN

### 5.1. Clone repository

```bash
git clone <your-repo-url>
cd DevOps_Final
```

### 5.2. Tạo file .env

```bash
cp .env.example .env
nano .env  # hoặc vim, code, notepad++
```

**Điền các giá trị:**

```bash
# AWS Configuration
AWS_KEY_NAME=productx-key  # Tên SSH key (KHÔNG có .pem)
AWS_REGION=ap-southeast-1

# Database Configuration
DB_PASSWORD=MySecurePassword123!
DB_NAME_PROD=productx_db
DB_NAME_STAGING=productx_db_staging
DB_USER_PROD=productx_user
DB_USER_STAGING=productx_staging_user

# SonarCloud Configuration
SONAR_ORGANIZATION=your-org-name
SONAR_PROJECT_KEY=your-project-key
SONAR_TOKEN=your-sonar-token

# Docker Hub
DOCKER_USERNAME=your-dockerhub-username

# Domain & HTTPS (Optional - để trống nếu chưa có)
DOMAIN_NAME=
ENABLE_HTTPS=false
```

### 5.3. Cấu hình SonarCloud

1. Truy cập https://sonarcloud.io
2. Đăng nhập bằng GitHub
3. **Create Organization**:
   - Chọn GitHub organization hoặc tạo mới
   - Lưu lại tên organization
4. **Create Project**:
   - Import repository từ GitHub
   - Hoặc tạo project manually
   - Lưu lại Project Key
5. **Generate Token**:
   - Vào **My Account** → **Security** → **Generate Tokens**
   - Đặt tên: `productx-ci`
   - Lưu lại token

---

## 6. TRIỂN KHAI INFRASTRUCTURE

### 6.1. Chạy script tự động

```bash
chmod +x setup.sh
./setup.sh
```

Script sẽ tự động:
1. Kiểm tra dependencies
2. Tạo infrastructure với Terraform (10-15 phút)
3. Cấu hình kubectl
4. Cài đặt AWS Load Balancer Controller
5. Chạy Ansible để cài PostgreSQL và NFS (5-10 phút)

### 6.2. Hoặc chạy thủ công

#### Bước 1: Terraform

```bash
cd terraform

# Initialize
terraform init

# Plan
terraform plan -var="key_name=productx-key" -out=tfplan

# Apply
terraform apply tfplan

# Lấy outputs
terraform output
```

Lưu lại các giá trị:
- `eks_cluster_name`
- `database_public_ip`
- `database_private_ip`

#### Bước 2: Cấu hình kubectl

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name <eks-cluster-name>

# Kiểm tra
kubectl get nodes
```

#### Bước 3: Cài AWS Load Balancer Controller

```bash
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
```

#### Bước 4: Ansible

```bash
cd ../ansible

# Tạo inventory
cp inventory/hosts.ini.example inventory/hosts.ini

# Sửa IP trong hosts.ini
nano inventory/hosts.ini
# Thay REPLACE_WITH_DATABASE_PUBLIC_IP bằng database_public_ip

# Chạy playbooks
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -e "db_password=YOUR_PASSWORD"
```

---

## 7. CẤU HÌNH CI/CD

### 7.1. Tạo GitHub Secrets

Vào GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Thêm các secrets sau:

| Secret Name | Giá trị | Ghi chú |
|-------------|---------|---------|
| `AWS_ACCESS_KEY_ID` | Access Key từ IAM | |
| `AWS_SECRET_ACCESS_KEY` | Secret Key từ IAM | |
| `AWS_REGION` | `ap-southeast-1` | Hoặc region bạn chọn |
| `EKS_CLUSTER_NAME` | Từ Terraform output | VD: `productx-eks` |
| `DATA_SERVER_IP` | `database_private_ip` từ Terraform | Private IP, không phải Public |
| `DB_PASSWORD` | Password trong .env | |
| `DOCKER_USERNAME` | Docker Hub username | |
| `DOCKER_PASSWORD` | Docker Hub password | |
| `SONAR_TOKEN` | Token từ SonarCloud | |
| `SONAR_ORGANIZATION` | Organization name | |
| `SONAR_PROJECT_KEY` | Project key | |

### 7.2. Trigger CI/CD

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

### 7.3. Theo dõi deployment

**Trên GitHub:**
- Vào **Actions** tab
- Xem workflow **Main CI Pipeline**
- Sau khi CI hoàn thành, workflow **Deploy to Production** sẽ tự động chạy

**Trên terminal:**
```bash
# Xem pods
kubectl get pods -n productx -w

# Xem logs
kubectl logs -f deployment/backend -n productx
kubectl logs -f deployment/frontend -n productx

# Xem ingress
kubectl get ingress -n productx
```

### 7.4. Lấy URL ứng dụng

```bash
kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Truy cập: `http://<alb-url>`

---

## 8. KIỂM TRA VÀ GIÁM SÁT

### 8.1. Kiểm tra Pods

```bash
# Xem tất cả pods
kubectl get pods -n productx

# Xem chi tiết pod
kubectl describe pod <pod-name> -n productx

# Xem logs
kubectl logs <pod-name> -n productx

# Exec vào pod
kubectl exec -it <pod-name> -n productx -- /bin/sh
```

### 8.2. Kiểm tra Services

```bash
kubectl get svc -n productx
```

### 8.3. Kiểm tra HPA (Horizontal Pod Autoscaler)

```bash
kubectl get hpa -n productx

# Xem chi tiết
kubectl describe hpa backend-hpa -n productx
```

### 8.4. Test Auto-scaling

```bash
# Tạo load generator
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# Trong pod, chạy:
while true; do wget -q -O- http://backend-svc.productx.svc.cluster.local:8080/api/products; done

# Terminal khác, xem HPA
kubectl get hpa -n productx -w
```

### 8.5. Kiểm tra Database

```bash
# SSH vào DB server
ssh -i productx-key.pem ubuntu@<database-public-ip>

# Kiểm tra PostgreSQL
sudo systemctl status postgresql

# Kết nối database
sudo -u postgres psql -d productx_db

# Trong psql:
\dt  # Xem tables
SELECT * FROM products LIMIT 5;
\q   # Thoát
```

### 8.6. Kiểm tra NFS

```bash
# Trên DB server
sudo exportfs -v

# Kiểm tra mount từ pod
kubectl exec -it <backend-pod> -n productx -- df -h | grep nfs
```

---

## 9. XỬ LÝ SỰ CỐ

### 9.1. Pod không start

**Triệu chứng:**
```bash
kubectl get pods -n productx
# STATUS: CrashLoopBackOff, Error, ImagePullBackOff
```

**Xử lý:**

```bash
# Xem logs
kubectl logs <pod-name> -n productx

# Xem events
kubectl describe pod <pod-name> -n productx

# Xem previous logs (nếu pod restart)
kubectl logs <pod-name> -n productx --previous
```

**Nguyên nhân thường gặp:**
- Image không tồn tại → Kiểm tra Docker Hub
- ConfigMap/Secret sai → Kiểm tra `kubectl get cm,secret -n productx`
- Database connection failed → Kiểm tra DB_HOST trong ConfigMap
- NFS mount failed → Kiểm tra NFS server

### 9.2. Database connection failed

**Kiểm tra:**

```bash
# Từ pod
kubectl exec -it <backend-pod> -n productx -- /bin/sh
nc -zv <DB_PRIVATE_IP> 5432

# Từ DB server
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"
```

**Xử lý:**
- Kiểm tra Security Group cho phép port 5432 từ VPC CIDR
- Kiểm tra PostgreSQL listen trên 0.0.0.0
- Kiểm tra pg_hba.conf cho phép VPC CIDR

### 9.3. NFS mount failed

**Kiểm tra:**

```bash
# Từ DB server
sudo systemctl status nfs-kernel-server
sudo exportfs -v

# Từ pod
kubectl exec -it <backend-pod> -n productx -- mount | grep nfs
```

**Xử lý:**
- Kiểm tra Security Group cho phép port 2049
- Kiểm tra NFS exports: `sudo exportfs -ra`
- Kiểm tra PV/PVC: `kubectl get pv,pvc -n productx`

### 9.4. ALB không tạo

**Kiểm tra:**

```bash
kubectl get ingress -n productx
kubectl describe ingress app-ingress -n productx
```

**Xử lý:**
- Kiểm tra AWS Load Balancer Controller đã cài: `kubectl get deployment -n kube-system`
- Kiểm tra IAM policy cho node role
- Xem logs: `kubectl logs -n kube-system deployment/aws-load-balancer-controller`

### 9.5. CI/CD failed

**Kiểm tra:**
- GitHub Actions logs
- SonarCloud analysis results
- Docker Hub images

**Xử lý:**
- Kiểm tra GitHub Secrets đã đầy đủ
- Kiểm tra SonarCloud token còn hiệu lực
- Kiểm tra Docker Hub credentials

---

## 10. DỌN DẸP TÀI NGUYÊN

### 10.1. Xóa Kubernetes resources

```bash
kubectl delete namespace productx
```

### 10.2. Xóa Infrastructure

```bash
cd terraform
terraform destroy -var="key_name=productx-key" -auto-approve
```

### 10.3. Hoặc dùng script

```bash
chmod +x cleanup.sh
./cleanup.sh
```

### 10.4. Xóa thủ công (nếu cần)

1. **EKS Cluster**: AWS Console → EKS → Delete cluster
2. **EC2 Instances**: AWS Console → EC2 → Terminate instances
3. **VPC**: AWS Console → VPC → Delete VPC
4. **Load Balancers**: AWS Console → EC2 → Load Balancers → Delete
5. **Security Groups**: AWS Console → EC2 → Security Groups → Delete

---

## 📚 TÀI LIỆU THAM KHẢO

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [React Documentation](https://react.dev/)

---

## 🤝 HỖ TRỢ

Nếu gặp vấn đề, vui lòng:
1. Kiểm tra logs: `kubectl logs`, `terraform output`, `ansible-playbook -vvv`
2. Tham khảo phần **Xử lý sự cố**
3. Tạo issue trên GitHub repository

---

**Chúc bạn triển khai thành công! 🚀**
