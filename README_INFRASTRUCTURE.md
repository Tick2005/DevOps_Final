# Kiến trúc Hạ tầng Product Management System

## Tổng quan

Hệ thống Product Management được triển khai trên AWS với kiến trúc microservices, sử dụng EKS (Elastic Kubernetes Service) để orchestration và các AWS managed services để tối ưu hóa vận hành.

## So sánh với Kiến trúc Mẫu (Document Management)

### Điểm giống nhau
- ✅ VPC với public/private subnets (2 AZs)
- ✅ EKS cluster với managed node groups
- ✅ Auto-scaling (HPA + Node Auto-scaling)
- ✅ Application Load Balancer qua Ingress
- ✅ CI/CD pipeline (PR CI → Main CI → CD)
- ✅ Security scanning với Trivy
- ✅ High availability setup

### Điểm khác biệt (Tối ưu hóa)

| Component | Document Management | Product Management | Lý do thay đổi |
|-----------|-------------------|-------------------|----------------|
| Database | PostgreSQL trên EC2 | AWS DocumentDB | Managed service, auto-backup, HA built-in |
| File Storage | NFS trên EC2 | AWS EFS | Managed, scalable, multi-AZ |
| Code Quality | SonarQube trên EC2 | Optional (GitHub Actions) | Giảm chi phí, có thể dùng SonarCloud |
| Database Type | PostgreSQL (SQL) | MongoDB (NoSQL) | Phù hợp với product catalog |

## Kiến trúc Chi tiết

### 1. Network Architecture

```
VPC (10.0.0.0/16)
│
├── Public Subnets (Internet-facing)
│   ├── 10.0.1.0/24 (AZ-1)
│   ├── 10.0.2.0/24 (AZ-2)
│   ├── Internet Gateway
│   └── Application Load Balancer
│
├── Private Subnets (Application tier)
│   ├── 10.0.11.0/24 (AZ-1)
│   ├── 10.0.12.0/24 (AZ-2)
│   ├── NAT Gateway
│   └── EKS Worker Nodes
│
└── Database Subnets (Data tier)
    ├── 10.0.21.0/24 (AZ-1)
    ├── 10.0.22.0/24 (AZ-2)
    └── DocumentDB Cluster
```

### 2. EKS Cluster

**Specifications:**
- Kubernetes Version: 1.31
- Node Type: t3.medium (có thể upgrade)
- Node Group: Managed
  - Min: 2 nodes
  - Desired: 2 nodes
  - Max: 4 nodes
- Network: Private subnets only
- Addons:
  - CoreDNS
  - kube-proxy
  - VPC-CNI
  - EBS CSI Driver
  - EFS CSI Driver

### 3. AWS DocumentDB

**Specifications:**
- Engine: MongoDB-compatible
- Instance Class: db.t3.medium
- Instances: 1 (có thể scale)
- Backup: 7 days retention
- Network: Database subnets (private)
- Security: VPC security group
- Features:
  - Automatic failover
  - Point-in-time recovery
  - Encryption at rest
  - TLS connections

**Connection String:**
```
mongodb://username:password@endpoint:27017/database?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false
```

### 4. AWS EFS (Elastic File System)

**Specifications:**
- Performance Mode: General Purpose
- Throughput Mode: Bursting
- Encryption: Enabled
- Lifecycle Policy: Transition to IA after 30 days
- Mount Targets: 2 (one per AZ)
- Access: NFS v4.1

**Use Cases:**
- Shared storage cho multiple pods
- File uploads từ backend
- Persistent data across pod restarts

### 5. Application Load Balancer

**Configuration:**
- Type: Application Load Balancer
- Scheme: Internet-facing
- Subnets: Public subnets
- Managed by: AWS Load Balancer Controller
- Routing:
  - `/api/*` → Backend Service (8080)
  - `/*` → Frontend Service (80)
- Health Checks: Configured
- Optional: HTTPS với ACM certificate

## Kubernetes Architecture

### Namespace: devops-final

### Deployments

**Backend Deployment:**
```yaml
Replicas: 2 (min) → 10 (max)
Image: product-management-backend
Resources:
  Requests: CPU 250m, Memory 512Mi
  Limits: CPU 1000m, Memory 1Gi
Health Checks:
  Liveness: /actuator/health
  Readiness: /actuator/health
HPA: CPU 70% threshold
```

**Frontend Deployment:**
```yaml
Replicas: 2 (min) → 10 (max)
Image: product-management-frontend
Resources:
  Requests: CPU 100m, Memory 256Mi
  Limits: CPU 500m, Memory 512Mi
Health Checks:
  Liveness: /
  Readiness: /
HPA: CPU 70% threshold
```

### Services

- `backend-svc`: ClusterIP (8080)
- `frontend-svc`: ClusterIP (80)

### Storage

- **PersistentVolume**: EFS-backed
- **PersistentVolumeClaim**: 100Gi
- **StorageClass**: efs-sc
- **Access Mode**: ReadWriteMany

## CI/CD Pipeline

### 1. PR CI Workflow
**Trigger:** Pull Request to main

**Jobs:**
- Backend Quality Check
  - Maven build & test
  - Optional: SonarQube scan
- Frontend Quality Check
  - NPM lint
  - NPM build

### 2. Main CI Workflow
**Trigger:** Push to main

**Jobs:**
- Build Backend
  - Maven package
  - Docker build
  - Trivy security scan
  - Push to Docker Hub
  - Tag: sha-{commit}
- Build Frontend
  - NPM build
  - Docker build
  - Trivy security scan
  - Push to Docker Hub
  - Tag: sha-{commit}
- Trigger CD deployment

### 3. CD Workflow
**Trigger:** After Main CI success

**Steps:**
1. Configure AWS credentials
2. Update kubeconfig
3. Update deployment images
4. Rolling restart
5. Wait for rollout
6. Verify deployment

## Security Architecture

### Network Security
- VPC isolation
- Security Groups:
  - EKS nodes: VPC internal only
  - DocumentDB: Port 27017 from VPC only
  - EFS: Port 2049 from VPC only
  - ALB: HTTP/HTTPS from internet
- NAT Gateway cho outbound traffic

### Application Security
- Container scanning: Trivy
- TLS for DocumentDB connections
- Kubernetes Secrets cho credentials
- GitHub Secrets cho CI/CD
- Optional: HTTPS với ACM certificates

### Access Control
- EKS: IAM roles và RBAC
- GitHub Actions: IAM credentials
- DocumentDB: Username/password authentication

## High Availability

### Multi-AZ Deployment
- VPC subnets: 2 AZs
- EKS nodes: Distributed across AZs
- DocumentDB: Multi-AZ với automatic failover
- EFS: Multi-AZ by default
- ALB: Multi-AZ load balancing

### Auto-Scaling
- **Horizontal Pod Autoscaler:**
  - CPU threshold: 70%
  - Min: 2 replicas
  - Max: 10 replicas
- **EKS Node Auto-Scaling:**
  - Min: 2 nodes
  - Max: 4 nodes

### Self-Healing
- Kubernetes automatic pod restart
- Liveness & Readiness probes
- Rolling updates (zero-downtime)
- DocumentDB automatic failover

## Cost Optimization

### Compute
- t3.medium instances (cost-effective)
- Auto-scaling để tránh over-provisioning
- Spot instances (optional cho non-critical workloads)

### Storage
- EFS Lifecycle Policy (IA after 30 days)
- DocumentDB backup retention: 7 days
- EBS volumes: gp3 (cost-effective)

### Network
- Single NAT Gateway (có thể upgrade to HA)
- VPC endpoints cho AWS services (optional)

## Monitoring & Observability

### Available
- Kubernetes metrics (via Metrics Server)
- CloudWatch Container Insights
- EKS control plane logs
- Application logs (kubectl logs)

### Recommended (Future)
- Prometheus + Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- AWS X-Ray cho distributed tracing
- CloudWatch Alarms

## Disaster Recovery

### Backup Strategy
- DocumentDB: Automated daily backups (7 days)
- EFS: AWS Backup (optional)
- Infrastructure: Terraform state

### Recovery Procedures
1. DocumentDB: Point-in-time recovery
2. EFS: Restore from backup
3. Infrastructure: Terraform apply
4. Application: Redeploy from CI/CD

## Scalability

### Horizontal Scaling
- Pods: 2 → 10 replicas (HPA)
- Nodes: 2 → 4 nodes (Cluster Autoscaler)
- DocumentDB: Add read replicas

### Vertical Scaling
- Node instance type: t3.medium → t3.large/xlarge
- DocumentDB instance: db.t3.medium → db.r6g.large
- Pod resources: Adjust requests/limits

## Deployment Workflow

### Initial Setup
```bash
1. ./scripts/setup.sh          # Terraform infrastructure
2. Update k8s manifests        # EFS ID, DocumentDB endpoint
3. ./scripts/deploy-k8s.sh     # Deploy application
```

### Continuous Deployment
```bash
1. Developer push code
2. PR CI validates quality
3. Merge to main
4. Main CI builds images
5. CD deploys to EKS
6. Rolling update (zero-downtime)
```

## Comparison Table

| Feature | Document Mgmt | Product Mgmt | Benefit |
|---------|--------------|--------------|---------|
| Database | EC2 PostgreSQL | DocumentDB | Managed, HA, Auto-backup |
| Storage | EC2 NFS | EFS | Managed, Multi-AZ, Scalable |
| Code Quality | EC2 SonarQube | Optional | Cost savings |
| Maintenance | High (EC2s) | Low (Managed) | Less ops overhead |
| Scalability | Manual | Auto | Better performance |
| Cost | Higher (EC2s) | Optimized | Pay for what you use |

## Next Steps

1. **Setup Infrastructure**: Follow DEPLOYMENT.md
2. **Configure Monitoring**: Add Prometheus/Grafana
3. **Enable HTTPS**: Setup ACM certificate
4. **Add Logging**: Setup ELK or CloudWatch Logs
5. **Implement Backups**: Configure AWS Backup
6. **Security Hardening**: Enable GuardDuty, Security Hub
