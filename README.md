# DevOps Final - Product Management System

Hệ thống quản lý sản phẩm fullstack được triển khai trên AWS EKS với kiến trúc microservices.

## 🏗️ Kiến trúc Hệ thống

### Application Stack
- **Frontend**: React 18 + Vite
- **Backend**: Spring Boot 3 + Java 21
- **Database**: AWS DocumentDB (MongoDB-compatible)
- **Storage**: AWS EFS (Elastic File System)

### Infrastructure (AWS)
- **VPC**: Multi-AZ với public/private subnets
- **EKS**: Kubernetes 1.31 với managed node groups
- **DocumentDB**: Managed MongoDB-compatible database
- **EFS**: Shared persistent storage
- **ALB**: Application Load Balancer via Ingress

### CI/CD Pipeline
- **PR CI**: Code quality validation
- **Main CI**: Build & push Docker images với Trivy scanning
- **CD**: Automated deployment to EKS

## 🚀 Quick Start

### Local Development (Docker Compose)
```bash
docker compose up -d --build
```

Truy cập:
- App: http://localhost:5173
- API: http://localhost:8080/api/products

### Production Deployment (AWS EKS)

**Prerequisites:**
- AWS CLI configured
- Terraform >= 1.0
- kubectl installed
- Docker Hub account

**Deploy:**
```bash
# 1. Setup infrastructure
cd terraform
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars với credentials
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region ap-southeast-1 --name devops-final-eks

# 3. Deploy application
cd ../k8s
# Update manifests với EFS ID và DocumentDB endpoint
kubectl apply -f .

# 4. Get Load Balancer URL
kubectl get ingress app-ingress -n devops-final
```

## 📁 Cấu trúc Dự án

```
DevOps_Final/
├── app/
│   ├── backend/common/      # Spring Boot service
│   └── frontend/            # React + Vite UI
├── terraform/               # Infrastructure as Code
│   ├── main.tf             # Provider configuration
│   ├── vpc.tf              # VPC setup
│   ├── eks.tf              # EKS cluster
│   ├── documentdb.tf       # DocumentDB cluster
│   ├── efs.tf              # EFS file system
│   └── helm.tf             # Helm charts (ALB, Metrics)
├── k8s/                    # Kubernetes manifests
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── ingress.yaml
│   ├── efs-storage.yaml
│   └── secret.yaml
├── .github/workflows/      # CI/CD pipelines
│   ├── pr-ci.yml          # Pull request validation
│   ├── main-ci.yml        # Build & push images
│   └── deploy-cd.yml      # Deploy to EKS
├── scripts/               # Automation scripts
│   ├── setup.sh          # Infrastructure setup
│   ├── deploy-k8s.sh     # Deploy to Kubernetes
│   ├── destroy.sh        # Cleanup
│   └── logs.sh           # View pod logs
└── docker-compose.yml     # Local development
```

## 📚 Tài liệu

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Hướng dẫn triển khai chi tiết
- **[README_INFRASTRUCTURE.md](README_INFRASTRUCTURE.md)** - Giải thích kiến trúc hệ thống
- **[architecture-diagram.md](architecture-diagram.md)** - Sơ đồ kiến trúc
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Hướng dẫn setup nhanh (Windows)

## 🔑 Tính năng Chính

### Application Features
- ✅ CRUD operations cho sản phẩm
- ✅ Phân trang và tìm kiếm
- ✅ Metadata runtime (host, tier, version)
- ✅ Responsive UI

### DevOps Features
- ✅ Infrastructure as Code (Terraform)
- ✅ Container orchestration (Kubernetes)
- ✅ Auto-scaling (HPA + Cluster Autoscaler)
- ✅ High availability (Multi-AZ)
- ✅ CI/CD automation (GitHub Actions)
- ✅ Security scanning (Trivy)
- ✅ Zero-downtime deployments
- ✅ Managed services (DocumentDB, EFS)

## 🔐 Security

- VPC isolation với security groups
- TLS encryption cho DocumentDB
- Container image scanning
- Kubernetes Secrets cho credentials
- IAM roles và RBAC
- Encrypted storage (EFS, DocumentDB)

## 📊 Monitoring

- Kubernetes Metrics Server
- CloudWatch Container Insights
- Application logs via kubectl
- Health checks (Liveness/Readiness probes)

## 🛠️ Common Commands

```bash
# View all resources
kubectl get all -n devops-final

# View logs
kubectl logs -f deployment/backend -n devops-final
kubectl logs -f deployment/frontend -n devops-final

# Scale manually
kubectl scale deployment backend --replicas=5 -n devops-final

# Port forward for testing
kubectl port-forward svc/backend-svc 8080:8080 -n devops-final

# Cleanup
kubectl delete namespace devops-final
cd terraform && terraform destroy
```

## 🎯 So sánh với Kiến trúc Mẫu

| Component | Document Mgmt | Product Mgmt | Benefit |
|-----------|--------------|--------------|---------|
| Database | EC2 PostgreSQL | DocumentDB | Managed, HA, Auto-backup |
| Storage | EC2 NFS | EFS | Managed, Multi-AZ |
| Code Quality | EC2 SonarQube | Optional | Cost savings |
| Maintenance | High | Low | Less ops overhead |

## 📝 GitHub Secrets Required

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
EKS_CLUSTER_NAME
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Submit PR (triggers PR CI)
4. Merge to main (triggers Main CI + CD)

## 📄 License

MIT License

## 👥 Authors

DevOps Final Project Team
