# DevOps Final - Product Management System

Hệ thống quản lý sản phẩm với kiến trúc microservices triển khai trên Amazon EKS.

## 🏗️ Kiến trúc

- **Frontend**: React + Vite
- **Backend**: Spring Boot + PostgreSQL
- **Infrastructure**: Amazon EKS (Kubernetes)
- **CI/CD**: GitHub Actions
- **Code Quality**: SonarCloud
- **Storage**: NFS Persistent Volume

## 📋 Yêu cầu

- AWS Account với IAM user có quyền tạo EKS, EC2, VPC
- AWS CLI đã cài đặt và cấu hình
- Terraform >= 1.7
- Ansible >= 2.9
- kubectl
- SSH key pair trên AWS
- Docker Hub account
- SonarCloud account (miễn phí cho public repos)

## 🚀 Cài đặt nhanh

### 1. Clone repository

```bash
git clone <your-repo-url>
cd DevOps_Final
```

### 2. Cấu hình môi trường

```bash
cp .env.example .env
nano .env
```

Điền các thông tin:
```bash
AWS_KEY_NAME=your-key-name-here
DB_PASSWORD=SecurePassword123!
SONAR_ORGANIZATION=your-org
SONAR_PROJECT_KEY=your-project-key
SONAR_TOKEN=your-token
DOCKER_USERNAME=your-dockerhub-username
```

### 3. Đặt file SSH key

```bash
# Đảm bảo file .pem nằm trong thư mục gốc
chmod 400 your-key-name.pem
```

### 4. Chạy setup tự động

```bash
chmod +x setup.sh
./setup.sh
```

Script sẽ tự động:
- Tạo EKS cluster với managed node groups
- Tạo EC2 instance cho PostgreSQL và NFS
- Cấu hình servers qua Ansible
- Hiển thị thông tin để cấu hình GitHub Actions

### 5. Cấu hình GitHub Actions Secrets

Vào GitHub repo → Settings → Secrets and variables → Actions

Thêm các secrets:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
EKS_CLUSTER_NAME
DATA_SERVER_IP
DB_PASSWORD
DOCKER_USERNAME
DOCKER_PASSWORD
SONAR_TOKEN
SONAR_ORGANIZATION
SONAR_PROJECT_KEY
```

### 6. Deploy ứng dụng

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

## 📖 Hướng dẫn chi tiết

Xem file [HUONG_DAN_CHI_TIET.md](./HUONG_DAN_CHI_TIET.md) để biết:
- Cách tạo VPC, Subnets, Availability Zones
- Cách cấu hình Security Groups
- Cách tạo IAM Roles và Policies
- Cách cài đặt và cấu hình từng thành phần
- Xử lý sự cố chi tiết

## 🔧 Chạy local với Docker Compose

```bash
docker compose up -d --build
```

Truy cập:
- App: http://localhost:5173
- API: http://localhost:8080/api/products

## 📊 Giám sát

```bash
# Xem pods
kubectl get pods -n productx

# Xem logs
kubectl logs -f deployment/backend -n productx

# Xem HPA
kubectl get hpa -n productx

# Lấy URL ứng dụng
kubectl get ingress -n productx
```

## 🧪 Testing

### Test Horizontal Pod Autoscaling

```bash
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# Trong pod:
while true; do wget -q -O- http://backend-svc.productx.svc.cluster.local:8080/api/products; done

# Terminal khác:
kubectl get hpa -n productx -w
```

## 🗑️ Cleanup

```bash
chmod +x cleanup.sh
./cleanup.sh
```

## 📝 Cấu trúc dự án

```
DevOps_Final/
├── app/
│   ├── backend/common/      # Spring Boot service
│   └── frontend/            # React + Vite UI
├── terraform/               # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── eks-addons.tf
├── ansible/                 # Configuration Management
│   ├── playbooks/
│   │   ├── site.yml
│   │   ├── database.yml
│   │   └── nfs-server.yml
│   └── inventory/
├── kubernetes/              # K8s Manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   └── nfs-pv.yaml
├── .github/workflows/       # CI/CD Pipelines
│   ├── main-ci.yml
│   └── deploy-cd.yml
├── docker-compose.yml
├── setup.sh
├── cleanup.sh
├── .env.example
├── HUONG_DAN_CHI_TIET.md
└── README.md
```

## 🔄 Thay đổi so với kiến trúc mẫu

1. **MongoDB → PostgreSQL**: DocumentDB không còn free tier
2. **SonarQube → SonarCloud**: Miễn phí cho public repos, không cần quản lý server
3. **Application**: Document Management → Product Management (tránh trùng code)

## 📄 License

This project is for educational purposes (DevOps Final Exam).

## 👥 Authors

- Your Name - DevOps Engineer
