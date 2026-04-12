# Kiến trúc hệ thống ProductX

## 📐 Tổng quan kiến trúc

ProductX là hệ thống quản lý sản phẩm được triển khai trên Amazon EKS với kiến trúc microservices, CI/CD tự động, và khả năng mở rộng cao.

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Route53 (DNS)      │ ← Domain: productx.online
              │   + ACM Certificate  │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Application Load    │
              │  Balancer (ALB)      │ ← HTTPS Termination
              └──────────┬───────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────┐            ┌─────────────────┐
│   Frontend      │            │   Backend       │
│   (React+Nginx) │            │   (Spring Boot) │
│   Pods: 2-8     │            │   Pods: 2-10    │
└─────────────────┘            └────────┬────────┘
                                        │
                        ┌───────────────┼───────────────┐
                        │               │               │
                        ▼               ▼               ▼
              ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
              │  PostgreSQL  │  │  NFS Server  │  │  Monitoring  │
              │  (EC2)       │  │  (EC2)       │  │  (Prometheus)│
              │  Port: 5432  │  │  Port: 2049  │  │  + Grafana   │
              └──────────────┘  └──────────────┘  └──────────────┘
```

## 🏗️ Các thành phần chính

### 1. Frontend (React + Vite)
- **Framework:** React 18 với Vite build tool
- **Deployment:** Nginx container serving static files
- **Replicas:** 2-8 pods (HPA enabled)
- **Resources:**
  - Request: 128Mi RAM, 50m CPU
  - Limit: 256Mi RAM, 200m CPU

### 2. Backend (Spring Boot)
- **Framework:** Spring Boot 3.x với Java 21
- **Database:** PostgreSQL 16
- **Replicas:** 2-10 pods (HPA enabled)
- **Resources:**
  - Request: 256Mi RAM, 100m CPU
  - Limit: 512Mi RAM, 500m CPU
- **Health Checks:**
  - Readiness: `/actuator/health` (30s delay)
  - Liveness: `/actuator/health` (60s delay)

### 3. Database (PostgreSQL)
- **Version:** PostgreSQL 16
- **Deployment:** EC2 t3.medium (standalone)
- **Database:** productx_db
- **User:** productx_user
- **Network:** Private subnet, accessible từ VPC
- **Backup:** Automated snapshots (nếu dùng RDS)

### 4. Storage (NFS)
- **Server:** NFS kernel server trên EC2
- **Export Path:** /srv/nfs/uploads
- **Access Mode:** ReadWriteMany
- **Capacity:** 10Gi (có thể mở rộng)
- **Mount Options:** nfsvers=4.1, hard, timeo=600

### 5. Load Balancer (ALB)
- **Type:** Application Load Balancer
- **Scheme:** Internet-facing
- **Target Type:** IP (cho EKS pods)
- **Health Check:** HTTP GET / (15s interval)
- **SSL/TLS:** ACM Certificate (nếu có domain)

### 6. Kubernetes Cluster (EKS)
- **Version:** 1.28+
- **Node Group:** Managed node group
- **Instance Type:** t3.medium (2 vCPU, 4GB RAM)
- **Nodes:** 2-4 nodes (auto-scaling)
- **Networking:** VPC CNI plugin
- **Add-ons:**
  - AWS Load Balancer Controller
  - EBS CSI Driver
  - CoreDNS
  - kube-proxy

## 🌐 Networking

### VPC Configuration
```
VPC CIDR: 10.0.0.0/16

Public Subnets (2 AZs):
  - 10.0.1.0/24 (ap-southeast-1a)
  - 10.0.2.0/24 (ap-southeast-1b)

Private Subnets (2 AZs):
  - 10.0.11.0/24 (ap-southeast-1a)
  - 10.0.12.0/24 (ap-southeast-1b)

Database Subnet:
  - 10.0.21.0/24 (ap-southeast-1a)
```

### Security Groups

**EKS Cluster SG:**
- Inbound: 443 from anywhere (API server)
- Outbound: All traffic

**EKS Node SG:**
- Inbound: All from cluster SG
- Inbound: 1025-65535 from ALB SG
- Outbound: All traffic

**Database SG:**
- Inbound: 5432 from EKS node SG
- Outbound: All traffic

**NFS SG:**
- Inbound: 2049 from EKS node SG
- Outbound: All traffic

**ALB SG:**
- Inbound: 80, 443 from anywhere
- Outbound: All to EKS node SG

## 🔄 CI/CD Pipeline

### Workflow 1: Infrastructure Provisioning
```
Trigger: Push to main (terraform/** or ansible/**)

Steps:
1. Security Scan (Trivy + TruffleHog)
2. Terraform Plan
3. Manual Approval
4. Terraform Apply
   ├─ Create VPC, Subnets, IGW, NAT
   ├─ Create EKS Cluster
   ├─ Create EC2 for DB + NFS
   └─ Create ACM Certificate (if domain)
5. Ansible Configuration
   ├─ Install PostgreSQL
   ├─ Setup NFS Server
   └─ Configure Security
6. Kubernetes Base Setup
   ├─ Create Namespace
   ├─ Apply ConfigMap
   ├─ Apply Secrets
   ├─ Create PV/PVC
   └─ Deploy Ingress
```

### Workflow 2: Build & Release
```
Trigger: Push to main (app/**)

Steps:
1. Wait for Infrastructure (if running)
2. Build Backend
   ├─ Compile Java (Maven)
   ├─ Build Docker Image
   ├─ Scan with Trivy
   └─ Push to Docker Hub
3. Build Frontend
   ├─ Build React (npm)
   ├─ Build Docker Image
   ├─ Scan with Trivy
   └─ Push to Docker Hub
```

### Workflow 3: Continuous Deployment
```
Trigger: After "Build & Release" success

Steps:
1. Configure kubectl
2. Update Deployment manifests
3. Apply to Kubernetes
4. Rolling Update
5. Wait for rollout complete
6. Verify deployment
```

## 📊 Monitoring & Observability

### Metrics Collection
- **Prometheus:** Scrape metrics từ pods
- **Grafana:** Visualization dashboards
- **CloudWatch:** AWS infrastructure metrics

### Logging
- **Container Logs:** kubectl logs
- **Application Logs:** Structured JSON logs
- **CloudWatch Logs:** EKS control plane logs

### Alerting
- **Prometheus AlertManager:** Alert rules
- **CloudWatch Alarms:** Infrastructure alerts
- **Email Notifications:** Critical alerts

## 🔒 Security

### Authentication & Authorization
- **AWS IAM:** Role-based access control
- **Kubernetes RBAC:** Namespace isolation
- **Secrets Management:** Kubernetes Secrets + AWS Secrets Manager

### Network Security
- **Security Groups:** Firewall rules
- **Network Policies:** Pod-to-pod communication
- **Private Subnets:** Database isolation

### Container Security
- **Image Scanning:** Trivy vulnerability scan
- **Non-root User:** Containers run as non-root
- **Read-only Filesystem:** Where possible

### Data Security
- **Encryption at Rest:** EBS volumes encrypted
- **Encryption in Transit:** TLS/HTTPS
- **Database Encryption:** PostgreSQL SSL

## 🚀 Scalability

### Horizontal Pod Autoscaler (HPA)
**Backend:**
- Min: 2 pods
- Max: 10 pods
- CPU Target: 70%
- Memory Target: 80%

**Frontend:**
- Min: 2 pods
- Max: 8 pods
- CPU Target: 70%
- Memory Target: 80%

### Cluster Autoscaler
- Min Nodes: 2
- Max Nodes: 4
- Scale up: When pods pending
- Scale down: After 10 minutes idle

### Database Scaling
- Vertical: Upgrade instance type
- Read Replicas: For read-heavy workloads
- Connection Pooling: HikariCP

## 💰 Cost Optimization

### Estimated Monthly Cost (ap-southeast-1)

| Service | Configuration | Cost (USD) |
|---------|--------------|------------|
| EKS Cluster | 1 cluster | $73 |
| EC2 Nodes | 2x t3.medium | $60 |
| EC2 Database | 1x t3.medium | $30 |
| ALB | 1 load balancer | $20 |
| NAT Gateway | 1 NAT | $35 |
| EBS Volumes | 100GB gp3 | $10 |
| Data Transfer | 100GB | $10 |
| **Total** | | **~$238/month** |

### Cost Saving Tips
1. Use Spot Instances cho worker nodes (-70%)
2. Stop non-prod environments ngoài giờ làm việc
3. Use S3 thay vì EBS cho static files
4. Enable EKS Fargate cho batch jobs
5. Use Reserved Instances cho production (1 year: -40%)

## 🔧 Maintenance

### Regular Tasks
- **Daily:** Check pod health, review logs
- **Weekly:** Review metrics, check for updates
- **Monthly:** Security patches, cost review
- **Quarterly:** Disaster recovery test

### Backup Strategy
- **Database:** Daily automated backups (7 days retention)
- **NFS Data:** Weekly snapshots
- **Terraform State:** Versioned in S3
- **Kubernetes Configs:** Git repository

### Disaster Recovery
- **RTO:** 4 hours (Recovery Time Objective)
- **RPO:** 24 hours (Recovery Point Objective)
- **Backup Location:** Different region
- **DR Plan:** Documented and tested quarterly

## 📚 Technology Stack

### Infrastructure
- **IaC:** Terraform 1.7
- **Configuration:** Ansible 2.9
- **Container Orchestration:** Kubernetes 1.28
- **Cloud Provider:** AWS

### Application
- **Backend:** Spring Boot 3.x, Java 21
- **Frontend:** React 18, Vite 5
- **Database:** PostgreSQL 16
- **Cache:** (Future: Redis)

### CI/CD
- **Pipeline:** GitHub Actions
- **Container Registry:** Docker Hub
- **Security Scan:** Trivy, TruffleHog
- **Deployment:** kubectl, Helm (future)

### Monitoring
- **Metrics:** Prometheus
- **Visualization:** Grafana
- **Logging:** CloudWatch Logs
- **Tracing:** (Future: Jaeger)

## 🎯 Future Enhancements

### Phase 2 (Q2 2024)
- [ ] Implement Redis caching
- [ ] Add Elasticsearch for logging
- [ ] Setup Jaeger for distributed tracing
- [ ] Implement rate limiting

### Phase 3 (Q3 2024)
- [ ] Multi-region deployment
- [ ] Blue-green deployment strategy
- [ ] Canary releases
- [ ] Service mesh (Istio)

### Phase 4 (Q4 2024)
- [ ] Machine learning integration
- [ ] Advanced analytics
- [ ] Mobile app support
- [ ] GraphQL API

## 📞 Support & Documentation

### Internal Documentation
- Architecture diagrams: `/docs/architecture/`
- API documentation: `/docs/api/`
- Runbooks: `/docs/runbooks/`
- Troubleshooting: `/docs/troubleshooting/`

### External Resources
- AWS EKS: https://docs.aws.amazon.com/eks/
- Kubernetes: https://kubernetes.io/docs/
- Spring Boot: https://spring.io/projects/spring-boot
- React: https://react.dev/

### Contact
- DevOps Team: devops@productx.com
- On-call: +84-xxx-xxx-xxx
- Slack: #productx-devops
- Jira: PRODUCTX project
