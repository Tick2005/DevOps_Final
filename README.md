# ProductX - Cloud-Native DevOps Platform

A complete enterprise-grade DevOps solution featuring a full-stack product management application deployed on AWS EKS with comprehensive infrastructure automation, monitoring, and CI/CD pipelines.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Infrastructure Setup](#infrastructure-setup)
- [Application Deployment](#application-deployment)
- [Monitoring & Observability](#monitoring--observability)
- [CI/CD Pipeline](#cicd-pipeline)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

ProductX is a production-ready cloud-native application demonstrating modern DevOps practices including:

- **Infrastructure as Code (IaC)** using Terraform
- **Container Orchestration** with Kubernetes (EKS)
- **Configuration Management** with Ansible
- **Automated CI/CD** with GitHub Actions
- **Monitoring & Alerting** with Prometheus, Grafana, and Alertmanager
- **Security Scanning** with Trivy
- **High Availability** with auto-scaling and load balancing

### Application Features

- Full-stack product management system (CRUD operations)
- RESTful API backend with Spring Boot
- Modern React frontend with Vite
- PostgreSQL database with persistent storage
- Real-time metrics and health monitoring
- Multi-environment support (development, staging, production)

## 🏗️ Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                  │  │
│  │  ┌─────────────────┐      ┌─────────────────┐         │  │
│  │  │  Public Subnet  │      │  Public Subnet  │         │  │
│  │  │  (AZ-1)         │      │  (AZ-2)         │         │  │
│  │  │  - NAT Gateway  │      │  - NAT Gateway  │         │  │
│  │  │  - ALB          │      │  - ALB          │         │  │
│  │  └─────────────────┘      └─────────────────┘         │  │
│  │  ┌─────────────────┐      ┌─────────────────┐         │  │
│  │  │ Private Subnet  │      │ Private Subnet  │         │  │
│  │  │ (AZ-1)          │      │ (AZ-2)          │         │  │
│  │  │ - EKS Nodes     │      │ - EKS Nodes     │         │  │
│  │  │ - Pods          │      │ - Pods          │         │  │
│  │  └─────────────────┘      └─────────────────┘         │  │
│  │  ┌─────────────────────────────────────────┐          │  │
│  │  │  EC2 Instance (Database + NFS Server)   │          │  │
│  │  │  - PostgreSQL                           │          │  │
│  │  │  - NFS Server for shared storage        │          │  │
│  │  └─────────────────────────────────────────┘          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Application Architecture

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Frontend   │─────▶│   Backend    │─────▶│  PostgreSQL  │
│  (React +    │       │ (Spring Boot)│       │   Database   │
│   Nginx)     │       │   REST API   │       │              │
└──────────────┘       └──────────────┘       └──────────────┘
       │                      │                      │
       └──────────────────────┴──────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Prometheus      │
                    │   Metrics         │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Grafana         │
                    │   Dashboards      │
                    └───────────────────┘
```

## 🛠️ Technology Stack

### Application Layer
- **Frontend**: React 18, Vite 5, Nginx
- **Backend**: Spring Boot 3.5, Java 21, Spring Data JPA
- **Database**: PostgreSQL 16
- **API**: RESTful with JSON

### Infrastructure Layer
- **Cloud Provider**: AWS (EKS, EC2, VPC, ALB, ACM)
- **Container Orchestration**: Kubernetes 1.31
- **IaC**: Terraform 1.x
- **Configuration Management**: Ansible
- **Container Runtime**: Docker

### DevOps & Monitoring
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus, Grafana
- **Alerting**: Alertmanager
- **Security Scanning**: Trivy
- **Metrics**: Micrometer, Spring Boot Actuator
- **Storage**: NFS, EBS CSI Driver

## 📦 Prerequisites

### Required Tools
- **Terraform** >= 1.0
- **kubectl** >= 1.28
- **AWS CLI** >= 2.0
- **Docker** >= 20.10
- **Ansible** >= 2.9
- **Helm** >= 3.0
- **Git**

### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- SSH key pair created in AWS
- (Optional) Domain name for HTTPS

### Local Development
- **Java** 21 (for backend development)
- **Node.js** >= 18 (for frontend development)
- **Maven** >= 3.8 (for backend builds)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd DevOps_Final
```

### 2. Local Development with Docker Compose

```bash
# Start all services locally
docker-compose up -d

# Access the application
# Frontend: http://localhost:5173
# Backend API: http://localhost:8080
# Database: localhost:5432
```

### 3. Deploy to AWS

```bash
# Step 1: Initialize Terraform
cd terraform
terraform init

# Step 2: Create terraform.tfvars
cat > terraform.tfvars <<EOF
key_name     = "your-ssh-key-name"
project_name = "productx"
environment  = "production"
EOF

# Step 3: Deploy infrastructure
terraform plan
terraform apply

# Step 4: Configure kubectl
aws eks update-kubeconfig --name productx-eks-cluster --region ap-southeast-1

# Step 5: Setup database and NFS with Ansible
cd ../ansible
# Update inventory/hosts.ini with EC2 IPs from Terraform output
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# Step 6: Deploy monitoring stack
cd ../monitoring-stack
terraform init
terraform apply

# Step 7: Deploy application to Kubernetes
cd ../kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f secrets.yaml
kubectl apply -f configmap.yaml
kubectl apply -f nfs-pv.yaml
kubectl apply -f base/backend/
kubectl apply -f base/frontend/
kubectl apply -f ingress.yaml
```

## 🏗️ Infrastructure Setup

### Terraform Infrastructure

The Terraform configuration creates:

- **VPC**: Multi-AZ VPC with public and private subnets
- **EKS Cluster**: Managed Kubernetes cluster with auto-scaling node groups
- **EC2 Instance**: Database and NFS server
- **Security Groups**: Properly configured network security
- **IAM Roles**: Service accounts for EKS add-ons
- **EBS CSI Driver**: For persistent volume support
- **AWS Load Balancer Controller**: For ingress management
- **ACM Certificate**: (Optional) For HTTPS support

#### Key Terraform Files

```
terraform/
├── vpc.tf                    # VPC, subnets, NAT gateways
├── eks.tf                    # EKS cluster and node groups
├── ec2.tf                    # Database + NFS server
├── load-balancer-controller.tf  # ALB controller
├── ebs-csi-driver.tf        # EBS storage driver
├── acm.tf                   # SSL certificate
├── variables.tf             # Input variables
├── outputs.tf               # Output values
└── providers.tf             # AWS provider config
```

#### Terraform Variables

Key variables you can customize in `terraform.tfvars`:

```hcl
# Required
key_name = "your-ssh-key"

# Optional (with defaults)
aws_region           = "ap-southeast-1"
cluster_version      = "1.31"
node_instance_type   = "c7i-flex.large"
node_desired_size    = 2
node_min_size        = 2
node_max_size        = 4
db_instance_type     = "t3.micro"

# HTTPS (optional)
enable_https         = true
domain_name          = "yourdomain.com"
```

### Ansible Configuration

Ansible playbooks automate the setup of:

1. **PostgreSQL Database**
   - Installation and configuration
   - Database and user creation
   - Security hardening
   - Backup configuration

2. **NFS Server**
   - NFS server installation
   - Shared storage setup
   - Export configuration
   - Permission management

#### Running Ansible Playbooks

```bash
cd ansible

# Update inventory with your EC2 IP
cat > inventory/hosts.ini <<EOF
[database]
<DB_SERVER_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem

[nfs]
<NFS_SERVER_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/your-key.pem
EOF

# Run all playbooks
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# Or run individually
ansible-playbook -i inventory/hosts.ini playbooks/database.yml
ansible-playbook -i inventory/hosts.ini playbooks/nfs-server.yml
```

## 🚢 Application Deployment

### Kubernetes Resources

The application is deployed using Kubernetes manifests:

```
kubernetes/
├── namespace.yaml           # Namespace isolation
├── secrets.yaml            # Database credentials
├── configmap.yaml          # Application configuration
├── nfs-pv.yaml            # NFS persistent volume
├── base/
│   ├── backend/
│   │   ├── deployment.yaml  # Backend deployment
│   │   ├── service.yaml     # Backend service
│   │   └── hpa.yaml         # Horizontal Pod Autoscaler
│   └── frontend/
│       ├── deployment.yaml  # Frontend deployment
│       ├── service.yaml     # Frontend service
│       └── hpa.yaml         # Horizontal Pod Autoscaler
├── ingress.yaml            # Production ingress
├── ingress-staging.yaml    # Staging ingress
└── servicemonitor.yaml     # Prometheus metrics
```

### Deployment Steps

```bash
# 1. Create namespace
kubectl apply -f kubernetes/namespace.yaml

# 2. Create secrets (update with your values)
kubectl apply -f kubernetes/secrets.yaml

# 3. Create ConfigMap
kubectl apply -f kubernetes/configmap.yaml

# 4. Setup NFS storage
kubectl apply -f kubernetes/nfs-pv.yaml

# 5. Deploy backend
kubectl apply -f kubernetes/base/backend/

# 6. Deploy frontend
kubectl apply -f kubernetes/base/frontend/

# 7. Setup ingress
kubectl apply -f kubernetes/ingress.yaml

# 8. Verify deployment
kubectl get pods -n productx
kubectl get svc -n productx
kubectl get ingress -n productx
```

### Scaling Configuration

The application includes Horizontal Pod Autoscalers (HPA):

**Backend HPA:**
- Min replicas: 2
- Max replicas: 10
- Target CPU: 70%
- Target Memory: 80%

**Frontend HPA:**
- Min replicas: 2
- Max replicas: 10
- Target CPU: 70%
- Target Memory: 80%

## 📊 Monitoring & Observability

### Monitoring Stack

The monitoring stack includes:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and notification
- **Metrics Server**: Kubernetes resource metrics

### Setup Monitoring

```bash
cd monitoring-stack

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
cluster_name            = "productx-eks-cluster"
grafana_admin_password  = "your-secure-password"
alert_email            = "your-email@example.com"
alert_email_password   = "your-app-password"
EOF

# Deploy monitoring stack
terraform init
terraform apply
```

### Access Grafana

```bash
# Get Grafana URL
kubectl get ingress -n monitoring grafana-ingress

# Default credentials
# Username: admin
# Password: (as set in terraform.tfvars)
```

### Available Metrics

The backend exposes Prometheus metrics at `/actuator/prometheus`:

- JVM metrics (memory, threads, GC)
- HTTP request metrics
- Database connection pool metrics
- Custom application metrics
- Spring Boot health indicators

### Pre-configured Dashboards

1. **Kubernetes Cluster Overview**
   - Node resource usage
   - Pod status and health
   - Namespace resource quotas

2. **Application Metrics**
   - Request rate and latency
   - Error rates
   - Database query performance
   - JVM memory and GC

3. **Infrastructure Metrics**
   - CPU and memory usage
   - Network I/O
   - Disk usage
   - Load balancer metrics

### Alerting Rules

Configured alerts include:

- High CPU usage (>80% for 5 minutes)
- High memory usage (>85% for 5 minutes)
- Pod restart loops
- High error rate (>5% for 5 minutes)
- Database connection failures
- Disk space low (<10%)

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

The project includes automated CI/CD pipelines:

```
.github/workflows/
├── backend-ci.yml      # Backend build and test
├── frontend-ci.yml     # Frontend build and test
├── security-scan.yml   # Trivy security scanning
└── deploy.yml          # Automated deployment
```

### Pipeline Features

1. **Continuous Integration**
   - Automated builds on pull requests
   - Unit and integration tests
   - Code quality checks
   - Security vulnerability scanning

2. **Continuous Deployment**
   - Automated deployment to staging
   - Manual approval for production
   - Rollback capabilities
   - Blue-green deployment support

3. **Security Scanning**
   - Container image scanning with Trivy
   - Dependency vulnerability checks
   - Infrastructure security validation

### Triggering Deployments

```bash
# Automatic deployment on push to main
git push origin main

# Manual deployment via GitHub Actions
# Go to Actions tab → Select workflow → Run workflow
```

## 📁 Project Structure

```
DevOps_Final/
├── app/
│   ├── backend/
│   │   └── common/
│   │       ├── src/
│   │       │   └── main/
│   │       │       ├── java/com/startupx/common/
│   │       │       │   ├── CommonApplication.java
│   │       │       │   └── product/
│   │       │       │       ├── ProductController.java
│   │       │       │       ├── ProductService.java
│   │       │       │       ├── ProductRepository.java
│   │       │       │       └── ...
│   │       │       └── resources/
│   │       │           └── application.yml
│   │       ├── Dockerfile
│   │       └── pom.xml
│   └── frontend/
│       ├── src/
│       │   ├── components/
│       │   │   ├── Header.jsx
│       │   │   ├── ProductForm.jsx
│       │   │   └── ProductTable.jsx
│       │   ├── api/
│       │   │   └── client.js
│       │   ├── App.jsx
│       │   └── main.jsx
│       ├── Dockerfile
│       ├── nginx.conf
│       └── package.json
├── terraform/
│   ├── vpc.tf
│   ├── eks.tf
│   ├── ec2.tf
│   ├── load-balancer-controller.tf
│   ├── ebs-csi-driver.tf
│   ├── acm.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
├── kubernetes/
│   ├── base/
│   │   ├── backend/
│   │   └── frontend/
│   ├── namespace.yaml
│   ├── secrets.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   └── servicemonitor.yaml
├── ansible/
│   ├── playbooks/
│   │   ├── database.yml
│   │   ├── nfs-server.yml
│   │   └── site.yml
│   ├── inventory/
│   │   └── hosts.ini.example
│   └── ansible.cfg
├── monitoring-stack/
│   ├── prometheus-grafana.tf
│   ├── metrics-server.tf
│   ├── storage-class.tf
│   └── variables.tf
├── .github/
│   └── workflows/
│       ├── backend-ci.yml
│       ├── frontend-ci.yml
│       └── security-scan.yml
├── docker-compose.yml
└── README.md
```

## ⚙️ Configuration

### Environment Variables

**Backend Configuration:**

```yaml
# Database
SPRING_DATASOURCE_URL: jdbc:postgresql://host:5432/productx_db
SPRING_DATASOURCE_USERNAME: productx_user
SPRING_DATASOURCE_PASSWORD: <password>

# Application
PORT: 8080
APP_TIER: production
```

**Frontend Configuration:**

```bash
# API Proxy
VITE_PROXY_TARGET: http://backend-service:8080
```

### Kubernetes Secrets

Update `kubernetes/secrets.yaml` with base64-encoded values:

```bash
# Encode database password
echo -n "your-password" | base64

# Update secrets.yaml
kubectl apply -f kubernetes/secrets.yaml
```

### ConfigMap

Application configuration in `kubernetes/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: productx
data:
  DATABASE_HOST: "10.0.x.x"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "productx_db"
  APP_TIER: "kubernetes-production"
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod status
kubectl get pods -n productx

# View pod logs
kubectl logs -n productx <pod-name>

# Describe pod for events
kubectl describe pod -n productx <pod-name>
```

#### 2. Database Connection Issues

```bash
# Test database connectivity from pod
kubectl exec -it -n productx <backend-pod> -- bash
nc -zv <db-host> 5432

# Check database logs on EC2
ssh ubuntu@<db-server-ip>
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

#### 3. Ingress Not Working

```bash
# Check ingress status
kubectl get ingress -n productx
kubectl describe ingress -n productx productx-ingress

# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

#### 4. NFS Mount Issues

```bash
# Check NFS server status
ssh ubuntu@<nfs-server-ip>
sudo systemctl status nfs-server
sudo exportfs -v

# Test NFS mount from node
showmount -e <nfs-server-ip>
```

#### 5. Monitoring Not Working

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check Grafana
kubectl get pods -n monitoring
kubectl logs -n monitoring <grafana-pod>
```

### Useful Commands

```bash
# View all resources in namespace
kubectl get all -n productx

# Check resource usage
kubectl top nodes
kubectl top pods -n productx

# View events
kubectl get events -n productx --sort-by='.lastTimestamp'

# Restart deployment
kubectl rollout restart deployment/backend -n productx
kubectl rollout restart deployment/frontend -n productx

# Scale deployment
kubectl scale deployment/backend -n productx --replicas=3

# View HPA status
kubectl get hpa -n productx
```

## 🤝 Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests locally
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow existing code style
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed
- Ensure all CI checks pass

### Testing Locally

```bash
# Backend tests
cd app/backend/common
mvn test

# Frontend tests
cd app/frontend
npm test

# Integration tests with Docker Compose
docker-compose up -d
# Run your tests
docker-compose down
```

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📧 Contact

For questions or support, please open an issue in the repository.