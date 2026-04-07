# TIER 5 - EXPERT: KUBERNETES-BASED ARCHITECTURE
## TODO CHECKLIST

---

## 1. INFRASTRUCTURE PROVISIONING & KUBERNETES SETUP

### 1.1 Cloud Infrastructure
- [ ] Chọn cloud provider (AWS EKS / GCP GKE / Azure AKS / hoặc self-hosted K3s)
- [ ] Provisioning infrastructure bằng Terraform (recommended)
  - [ ] Tạo VPC/Network và subnets
  - [ ] Cấu hình Security Groups/Firewall rules
  - [ ] Provisioning Kubernetes cluster (hoặc compute instances cho K3s)
  - [ ] Cấu hình storage resources (persistent volumes)
  - [ ] Đảm bảo idempotency của Terraform scripts
  - [ ] Test và verify idempotency với logs/screenshots

### 1.2 Kubernetes Cluster Setup
- [ ] Deploy Kubernetes cluster (K3s/EKS/GKE/AKS)
- [ ] Cấu hình kubectl access và credentials
- [ ] Verify cluster health và node status
- [ ] Setup namespaces cho application
- [ ] Cấu hình RBAC (Role-Based Access Control) nếu cần

### 1.3 Domain & HTTPS
- [ ] Đăng ký domain name
- [ ] Cấu hình DNS records trỏ về cluster
- [ ] Cài đặt cert-manager cho Let's Encrypt
- [ ] Cấu hình automatic certificate renewal
- [ ] Verify HTTPS hoạt động đúng

---

## 2. KUBERNETES DEPLOYMENT CONFIGURATION

### 2.1 Core Kubernetes Resources
- [ ] Tạo Namespace cho application
- [ ] Tạo ConfigMaps cho application configuration
- [ ] Tạo Secrets cho sensitive data (database passwords, API keys)
- [ ] Tạo PersistentVolumeClaims cho stateful services (MongoDB)

### 2.2 Application Deployments
- [ ] Tạo Deployment manifest cho Backend service
  - [ ] Định nghĩa container image và version tag
  - [ ] Cấu hình resource requests và limits (CPU, memory)
  - [ ] Cấu hình liveness và readiness probes
  - [ ] Cấu hình environment variables từ ConfigMaps/Secrets
  - [ ] Set replica count phù hợp

- [ ] Tạo Deployment manifest cho Frontend service
  - [ ] Định nghĩa container image và version tag
  - [ ] Cấu hình resource requests và limits
  - [ ] Cấu hình probes
  - [ ] Cấu hình environment variables
  - [ ] Set replica count phù hợp

- [ ] Tạo StatefulSet/Deployment cho MongoDB
  - [ ] Cấu hình persistent storage
  - [ ] Cấu hình authentication từ Secrets
  - [ ] Cấu hình backup strategy (optional)

### 2.3 Service Resources
- [ ] Tạo Service cho Backend (ClusterIP)
- [ ] Tạo Service cho Frontend (ClusterIP)
- [ ] Tạo Service cho MongoDB (ClusterIP/Headless)
- [ ] Verify service discovery hoạt động

### 2.4 Ingress Configuration
- [ ] Cài đặt Ingress Controller (Nginx/Traefik)
- [ ] Tạo Ingress resource cho external access
- [ ] Cấu hình routing rules (frontend, backend API)
- [ ] Cấu hình TLS/HTTPS với cert-manager
- [ ] Test external access qua domain

---

## 3. AUTOSCALING & SELF-HEALING

### 3.1 Horizontal Pod Autoscaler (HPA)
- [ ] Cài đặt Metrics Server trong cluster
- [ ] Tạo HPA cho Backend deployment
  - [ ] Định nghĩa min/max replicas
  - [ ] Cấu hình CPU/memory thresholds
  - [ ] Test scaling behavior

- [ ] Tạo HPA cho Frontend deployment
  - [ ] Định nghĩa min/max replicas
  - [ ] Cấu hình thresholds
  - [ ] Test scaling behavior

### 3.2 Self-Healing Verification
- [ ] Verify pod restart khi container fails
- [ ] Verify pod rescheduling khi node fails
- [ ] Test liveness probe triggering restart
- [ ] Document self-healing behavior

---

## 4. CI/CD PIPELINE

### 4.1 Continuous Integration (CI)
- [ ] Setup GitHub Actions / GitLab CI / Jenkins
- [ ] Implement CI stages:
  - [ ] Code checkout
  - [ ] Linting và static analysis
  - [ ] Dependency caching
  - [ ] Build application artifacts
  - [ ] Security scanning (Trivy/Snyk/SonarQube)
    - [ ] Cấu hình fail on critical/high vulnerabilities
    - [ ] Document risk acceptance nếu có
  - [ ] Build Docker images cho Backend
  - [ ] Build Docker images cho Frontend
  - [ ] Tag images với semantic version hoặc commit hash
  - [ ] Push images to container registry (Docker Hub/ECR/GCR)

### 4.2 Continuous Delivery (CD)
- [ ] Implement CD stages:
  - [ ] Retrieve versioned container images
  - [ ] Update Kubernetes manifests với image tags mới
  - [ ] Deploy to Kubernetes cluster
    - [ ] Apply ConfigMaps/Secrets
    - [ ] Apply Deployments
    - [ ] Apply Services
    - [ ] Apply Ingress
  - [ ] Verify deployment success
  - [ ] Rollout status check

### 4.3 Multi-Environment (Optional - Bonus)
- [ ] Setup Staging environment
- [ ] Setup Production environment
- [ ] Implement manual approval gate
- [ ] Document deployment strategy

### 4.4 Advanced Deployment Strategy (Optional - Bonus)
- [ ] Implement Rolling Update strategy
- [ ] Implement Blue-Green deployment (optional)
- [ ] Implement Canary release (optional)
- [ ] Document và demonstrate strategy

---

## 5. MONITORING & OBSERVABILITY

### 5.1 Prometheus Setup
- [ ] Deploy Prometheus trong Kubernetes cluster
- [ ] Cấu hình service discovery cho pods
- [ ] Cấu hình scraping cho:
  - [ ] Node metrics
  - [ ] Pod metrics
  - [ ] Container metrics
  - [ ] Application metrics (optional)
- [ ] Verify metrics collection

### 5.2 Grafana Setup
- [ ] Deploy Grafana trong cluster
- [ ] Cấu hình Prometheus data source
- [ ] Tạo dashboards hiển thị:
  - [ ] CPU usage (nodes và pods)
  - [ ] Memory usage (nodes và pods)
  - [ ] Pod status và health
  - [ ] Network traffic (optional)
  - [ ] Application-specific metrics (optional)
- [ ] Export dashboard JSON files

### 5.3 Alerting (Optional - Bonus)
- [ ] Deploy Alertmanager
- [ ] Cấu hình alert rules
- [ ] Setup notification channels (email/Slack)
- [ ] Test alerting behavior

### 5.4 Logging (Optional - Bonus)
- [ ] Deploy centralized logging (Loki/ELK)
- [ ] Cấu hình log aggregation
- [ ] Integrate với Grafana
- [ ] Test log queries

---

## 6. MANDATORY DEMONSTRATION SCENARIO

### 6.1 Source Code Modification
- [ ] Prepare visible change (UI text, feature, config)
- [ ] Document change location

### 6.2 Commit & Push
- [ ] Make code change
- [ ] Commit với clear message
- [ ] Push to trigger pipeline
- [ ] Record commit hash

### 6.3 CI Pipeline Execution
- [ ] Show pipeline trigger
- [ ] Show linting stage
- [ ] Show build stage
- [ ] Show security scanning
- [ ] Show container image build
- [ ] Show registry push
- [ ] Capture pipeline logs

### 6.4 CD Pipeline Execution
- [ ] Show deployment trigger
- [ ] Show Kubernetes apply commands
- [ ] Show rollout status
- [ ] Show pod updates

### 6.5 Application Verification
- [ ] Access via public domain
- [ ] Verify HTTPS certificate
- [ ] Verify visible change is deployed
- [ ] Test application functionality

### 6.6 Monitoring Validation
- [ ] Open Grafana dashboard
- [ ] Show real-time metrics
- [ ] Show pod status
- [ ] Explain metric meanings

### 6.7 Failure Simulation
- [ ] Delete a pod manually
- [ ] Show automatic pod recreation
- [ ] Show metrics during failure
- [ ] Show self-healing behavior
- [ ] Demonstrate alerting nếu có

---

## 7. DOCUMENTATION & DELIVERABLES

### 7.1 Technical Report (PDF)
- [ ] Chapter 1: Overview & System Architecture
  - [ ] Architecture diagram
  - [ ] Technology stack
  - [ ] Tier 5 justification
  
- [ ] Chapter 2: Infrastructure Provisioning
  - [ ] Terraform configuration explanation
  - [ ] Kubernetes cluster setup
  - [ ] Network và security configuration
  - [ ] Idempotency evidence
  
- [ ] Chapter 3: CI/CD Pipeline Design
  - [ ] Pipeline architecture
  - [ ] CI stages explanation
  - [ ] CD stages explanation
  - [ ] Security integration
  
- [ ] Chapter 4: Deployment & Orchestration
  - [ ] Kubernetes resources explanation
  - [ ] Deployment strategy
  - [ ] Scaling configuration
  - [ ] Self-healing mechanisms
  
- [ ] Chapter 5: Monitoring, Observability & Lessons Learned
  - [ ] Monitoring setup
  - [ ] Dashboard screenshots
  - [ ] Challenges faced
  - [ ] Lessons learned
  - [ ] Future improvements

### 7.2 Video Demonstration
- [ ] Record full end-to-end demo
- [ ] Follow mandatory scenario exactly
- [ ] Show all required stages
- [ ] Clear audio explanation
- [ ] High quality screen recording

### 7.3 Code Repository
- [ ] Application source code
- [ ] Dockerfiles
- [ ] Kubernetes manifests
- [ ] Terraform files
- [ ] CI/CD pipeline configs
- [ ] Monitoring configs
- [ ] README with setup instructions
- [ ] Remove hard-coded secrets

### 7.4 Submission Package
- [ ] Compress all deliverables to .zip
- [ ] Include production URL
- [ ] Include repository link
- [ ] Include container registry link
- [ ] Include monitoring dashboard link (if accessible)
- [ ] Verify system is accessible during grading period

---

## 8. BONUS FEATURES (OPTIONAL)

### 8.1 Self-Hosted CI/CD (0.25-0.5 points)
- [ ] Deploy Jenkins/GitLab on separate machine
- [ ] Configure custom domain
- [ ] Setup HTTPS
- [ ] Use for project pipeline

### 8.2 Multi-Environment with Approval (0.25-0.5 points)
- [ ] Implement staging environment
- [ ] Implement production environment
- [ ] Add manual approval gate
- [ ] Document workflow

### 8.3 Advanced Deployment Strategy (0.25-0.5 points)
- [ ] Implement rolling update
- [ ] Implement blue-green deployment
- [ ] Implement canary release
- [ ] Demonstrate in video

### 8.4 Automated Rollback (0.25-0.5 points)
- [ ] Implement health check-based rollback
- [ ] Implement failure detection
- [ ] Test rollback mechanism
- [ ] Document behavior

---

## CRITICAL REMINDERS

✅ Kubernetes cluster phải là production-grade (K3s/EKS/GKE/AKS)
✅ Sử dụng Deployments, Services, ConfigMaps, Secrets, Ingress
✅ Implement HPA (Horizontal Pod Autoscaler)
✅ Demonstrate self-healing behavior
✅ Container images phải có explicit version tags (không dùng :latest)
✅ HTTPS bắt buộc với Let's Encrypt
✅ Monitoring với Prometheus + Grafana là bắt buộc
✅ CI/CD pipeline phải fully automated
✅ Security scanning phải fail on critical vulnerabilities
✅ System phải accessible trong suốt grading period
✅ Tất cả features phải được demonstrate trong video và live presentation
✅ Documentation phải match với deployed system

---

**Tier 5 offers highest scoring potential but requires solid understanding of Kubernetes concepts and production practices. Focus on stability and correctness over unnecessary complexity.**
