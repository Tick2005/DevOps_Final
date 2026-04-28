# 🚀 CI/CD Workflows Overview - ProductX DevOps Pipeline

## 📋 Table of Contents
1. [Pipeline Architecture](#pipeline-architecture)
2. [Workflow Sequence](#workflow-sequence)
3. [Detailed Workflow Steps](#detailed-workflow-steps)
4. [Deployment Environments](#deployment-environments)
5. [Monitoring & Observability](#monitoring--observability)

---

## 🏗️ Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CI/CD PIPELINE FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

Phase 1: PLANNING & SETUP
├── 01. Start
├── 02. Select Deployment Architecture
│   ├── Single Server
│   ├── Containerized
│   ├── Multi-Server
│   ├── Swarm
│   └── Kubernetes ✓ (Selected)
└── 03. Provision Infrastructure

Phase 2: INFRASTRUCTURE PROVISIONING
├── 04. Manual Provisioning
├── 05. Terraform
├── 06. Ansible
└── 07. Configure Cloud Provider & Domain/HTTPS

Phase 3: CODE & BUILD
├── 08. Set Up CMS
├── 09. Configure HTTPS Certificate
├── 10. CI Pipeline Setup
├── 11. Setup GitHub Repository
├── 12. Set Up GitHub Actions
├── 13. Lint Code
├── 14. Build Application
├── 15. Run Security Scan
└── 16. Version Artifacts or Images

Phase 4: CONTAINERIZATION & REGISTRY
├── 17. Push to Docker Hub
├── 18. CD Pipeline Setup
├── 19. Prepare CD Pipeline
└── 20. Deploy to Production

Phase 5: DEPLOYMENT STRATEGY
├── 21. Deployment Method (Decision Point)
│   ├── Deploy Single Server
│   ├── Deploy Containerized
│   ├── Deploy Multi Server
│   ├── Deploy Swarm
│   └── Deploy Kubernetes ✓
└── 22. Execute Application via HTTP Domain

Phase 6: STAGING & TESTING
├── 23. Monitoring and Observability
└── 24. Test Up Prometheus

Phase 7: PRODUCTION & MAINTENANCE
├── 25. Set Up Grafana Dashboard
├── 26. Prometheus End-to-End Test
├── 27. Deploy CICD Pipeline
├── 28. Verify Live Update
├── 29. Optimize Metrics
├── 30. Simulate Failure
├── 31. Validate System Recovery
└── 32. End ✓

```

---

## 🔄 Workflow Sequence

### **Phase 1: Infrastructure Setup** 🏗️

#### **Step 1-3: Planning & Architecture Selection**
```
Start → Select Deployment Architecture → Provision Infrastructure
```

**Decision Point**: Choose deployment architecture
- ❌ Single Server
- ❌ Containerized
- ❌ Multi-Server
- ❌ Swarm
- ✅ **Kubernetes** (Selected for ProductX)

---

#### **Step 4-7: Infrastructure Provisioning**
```
Manual Provisioning → Terraform → Ansible → Configure Cloud Provider
```

**Tools Used**:
- **Terraform**: Infrastructure as Code (IaC)
  - VPC, Subnets, Security Groups
  - EKS Cluster
  - EC2 Instances (NFS, Database)
  - Load Balancer Controller
  - EBS CSI Driver

- **Ansible**: Configuration Management
  - Database setup (PostgreSQL)
  - NFS Server configuration
  - System packages installation

- **Cloud Provider**: AWS
  - Region: `ap-southeast-1`
  - Services: EKS, EC2, VPC, ACM, Route53

- **Domain & HTTPS**:
  - Domain: `tranduchuy.site`
  - SSL/TLS: AWS Certificate Manager (ACM)

---

### **Phase 2: CI Pipeline** 🔨

#### **Step 8-12: Repository & CI Setup**
```
Set Up CMS → Configure HTTPS Certificate → CI Pipeline Setup → 
Setup GitHub Repository → Set Up GitHub Actions
```

**GitHub Actions Workflows**:
1. **`.github/workflows/ci.yml`** - Continuous Integration
2. **`.github/workflows/build-release.yml`** - Build & Release Docker Images
3. **`.github/workflows/deploy-staging.yml`** - Deploy to Staging
4. **`.github/workflows/deploy-cd.yml`** - Deploy to Production

---

#### **Step 13-16: Build & Quality Checks**
```
Lint Code → Build Application → Run Security Scan → Version Artifacts
```

**CI Workflow Steps**:

```yaml
# Workflow: ci.yml
Trigger: Push to main/develop, Pull Request

Jobs:
  1. lint-backend:
     - Checkout code
     - Setup Java 17
     - Run Maven checkstyle
     - Cache dependencies
  
  2. lint-frontend:
     - Checkout code
     - Setup Node.js 20
     - Run ESLint
     - Cache node_modules
  
  3. test-backend:
     - Run unit tests
     - Generate test reports
     - Upload coverage
  
  4. test-frontend:
     - Run Jest tests
     - Generate coverage reports
  
  5. build-backend:
     - Build Spring Boot JAR
     - Upload artifacts
  
  6. build-frontend:
     - Build React production bundle
     - Upload artifacts
  
  7. security-scan:
     - Run Trivy vulnerability scan
     - Scan Docker images
     - Scan filesystem
     - Upload SARIF results
```

---

### **Phase 3: Build & Release** 🐳

#### **Step 17-19: Docker Build & Push**
```
Build Application → Push to Docker Hub → CD Pipeline Setup
```

**Build & Release Workflow**:

```yaml
# Workflow: build-release.yml
Trigger: Push to main branch (after CI passes)

Jobs:
  1. build-and-push-backend:
     - Checkout code
     - Setup Docker Buildx
     - Login to Docker Hub
     - Build backend image
     - Tag images:
       * latest
       * sha-{commit-sha}
       * v{version}
     - Push to Docker Hub
     - Scan image with Trivy
  
  2. build-and-push-frontend:
     - Checkout code
     - Setup Docker Buildx
     - Login to Docker Hub
     - Build frontend image
     - Tag images:
       * latest
       * sha-{commit-sha}
       * v{version}
     - Push to Docker Hub
     - Scan image with Trivy
  
  3. create-release:
     - Generate release notes
     - Create GitHub release
     - Upload artifacts
```

**Docker Images**:
- `{username}/productx-backend:latest`
- `{username}/productx-backend:sha-{commit}`
- `{username}/productx-frontend:latest`
- `{username}/productx-frontend:sha-{commit}`

---

### **Phase 4: Staging Deployment** 🧪

#### **Step 20-22: Deploy to Staging**
```
Prepare CD Pipeline → Deploy to Staging → Execute Application
```

**Staging Workflow**:

```yaml
# Workflow: deploy-staging.yml
Trigger: After "Build & Release Docker" succeeds

Environment: staging
Namespace: productx-staging
URL: https://staging.tranduchuy.site

Jobs:
  deploy-staging:
    Steps:
      1. Checkout Repository
      2. Configure AWS Credentials
      3. Configure kubectl for EKS
      
      4. Create Staging Namespace
         - kubectl create namespace productx-staging
      
      5. Apply Staging ConfigMap
         - Get DB_HOST from production (or use placeholder)
         - Get NFS_SERVER from production (or use placeholder)
         - Create staging configmap with:
           * DB_HOST: {from-production}
           * DB_PORT: 5432
           * DB_NAME: productx (shared with production)
           * NFS_SERVER: {from-production}
           * APP_ENV: staging
      
      6. Apply Staging Secrets
         - DB_PASSWORD from GitHub Secrets
      
      7. Verify Staging Configuration
         - Check ConfigMap exists
         - Check Secrets exists
      
      8. Update Deployment Images
         - Copy kubernetes/base to staging-deploy
         - Replace DOCKER_USERNAME
         - Replace PLACEHOLDER_IMAGE_TAG with sha-{commit}
         - Update namespace to productx-staging
         - Reduce replicas to 1 (save resources)
      
      9. Deploy to Staging
         - kubectl apply backend deployment & service
         - kubectl apply frontend deployment & service
      
      10. Monitor Deployment Progress (600s timeout)
          - kubectl rollout status backend
          - kubectl rollout status frontend
          - On failure: show pods, events, logs, description
      
      11. Wait for Pods to be Ready
          - kubectl wait --for=condition=ready (300s)
          - Sleep 30s for application initialization
          - Check backend logs
      
      12. Run Staging Tests
          - Create test pod with curl
          - Test 1: Health Check (/actuator/health)
          - Test 2: List Products (GET /api/products)
          - Test 3: Get Single Product (GET /api/products/{id})
          - Test 4: Create Product (POST /api/products)
          - Test 5: Update Product (PUT /api/products/{id})
          - Test 6: Delete Product (DELETE /api/products/{id})
      
      13. Rollback on Failure
          - kubectl rollout undo backend
          - kubectl rollout undo frontend
      
      14. Print Staging Summary
          - Show pods, services
          - Show access instructions

  promote-to-production:
    Needs: deploy-staging
    Environment: production-approval (Manual approval required)
    
    Steps:
      1. Wait for manual approval
      2. Trigger Production Deployment
         - Call deploy-cd.yml workflow
         - Pass image tag from staging
```

**Staging Tests**:
```bash
# All tests run inside cluster using internal service
API_BASE="http://backend-svc:8080/api"

✅ Test 1: Health Check
✅ Test 2: List Products
✅ Test 3: Get Single Product
✅ Test 4: Create Product
✅ Test 5: Update Product
✅ Test 6: Delete Product
```

---

### **Phase 5: Production Deployment** 🚀

#### **Step 20-22: Deploy to Production**
```
Deploy to Production → Deployment Method → Execute Application
```

**Production Workflow**:

```yaml
# Workflow: deploy-cd.yml
Trigger: 
  - After "Build & Release Docker" succeeds
  - Manual trigger from staging promotion

Environment: production
Namespace: productx
URL: https://www.tranduchuy.site

Jobs:
  deploy:
    Steps:
      1. Checkout Repository
      2. Configure AWS Credentials
      3. Configure kubectl for EKS
      
      4. Update Deployment Images
         - Determine image tag:
           * Manual: use input tag
           * Auto: use sha-{commit}
         - Update backend deployment
         - Update frontend deployment
      
      5. Update Ingress Domain
         - Replace PLACEHOLDER_DOMAIN with www.tranduchuy.site
      
      6. Get ACM Certificate ARN
         - Search for certificate for tranduchuy.site
         - Check certificate status:
           * ISSUED: Use for HTTPS
           * PENDING_VALIDATION: Show DNS records needed
           * Not found: Create new certificate
      
      7. Update Ingress with HTTPS Configuration
         - If certificate valid:
           * Configure HTTPS (port 443)
           * Configure HTTP redirect (port 80 → 443)
         - If no certificate:
           * Configure HTTP only (port 80)
      
      8. Clean Up Old ALB (if exists)
         - Check if ingress exists
         - Check if ALB has wrong configuration
         - Delete and recreate if needed
      
      9. Deploy Application
         - kubectl apply backend (deployment, service, hpa)
         - kubectl apply frontend (deployment, service, hpa)
         - kubectl apply ingress
         - kubectl rollout restart backend & frontend
         - kubectl rollout status (600s timeout)
      
      10. Verify Deployment
          - Show pods, services, ingress
          - Show ALB address
          - Show HPA status
      
      11. Wait for Pods to be Ready
          - kubectl wait --for=condition=ready (300s)
          - Sleep 30s for initialization
          - Check backend logs
      
      12. Health Check - Backend API
          - Test 1: Direct Pod Access
            * kubectl exec pod -- wget localhost:8080/actuator/health
          - Test 2: Service Endpoint
            * Create temp pod with curl
            * curl http://backend-svc:8080/actuator/health
          - Test 3: ALB Access (optional)
            * curl http://{ALB}/api/actuator/health
      
      13. Health Check - Frontend
          - Test Frontend Pod
          - Test Frontend Service
      
      14. Smoke Tests - CRUD Operations
          - Create test pod with curl
          - Test 1: List Products
          - Test 2: Get Single Product
          - Test 3: Create Product
          - Test 4: Update Product
          - Test 5: Delete Product
      
      15. Rollback on Failure
          - kubectl rollout undo backend
          - kubectl rollout undo frontend
      
      16. Print Deployment Summary
          - Show trigger type, image tags
          - Show cluster info

  notify-ci-failed:
    Condition: If CI failed
    Steps:
      - Print failure notification
      - Skip CD pipeline
```

**Production Resources**:
```yaml
Backend:
  Replicas: 2
  Resources:
    Requests: 256Mi RAM, 100m CPU
    Limits: 512Mi RAM, 500m CPU
  HPA:
    Min: 2, Max: 10
    Target CPU: 70%

Frontend:
  Replicas: 2
  Resources:
    Requests: 128Mi RAM, 50m CPU
    Limits: 256Mi RAM, 200m CPU
  HPA:
    Min: 2, Max: 10
    Target CPU: 70%

Ingress:
  Class: alb
  Scheme: internet-facing
  Target Type: ip
  Ports: 80 (HTTP), 443 (HTTPS)
  SSL Policy: ELBSecurityPolicy-TLS13-1-2-2021-06
```

---

### **Phase 6: Monitoring & Observability** 📊

#### **Step 23-24: Setup Monitoring**
```
Monitoring and Observability → Test Up Prometheus
```

**Monitoring Stack**:

```yaml
# Deployed via Terraform in monitoring-stack/

Components:
  1. Prometheus:
     - Metrics collection
     - Service discovery
     - Alert rules
     - Retention: 15 days
  
  2. Grafana:
     - Dashboards
     - Visualization
     - Alerting
     - URL: https://grafana.tranduchuy.site
  
  3. Alertmanager:
     - Alert routing
     - Notification channels
     - Alert grouping
  
  4. Metrics Server:
     - Resource metrics
     - HPA support
     - kubectl top support

Prometheus Targets:
  - Kubernetes API Server
  - Kubelet metrics
  - cAdvisor (container metrics)
  - Node Exporter
  - Backend application (/actuator/prometheus)
  - Frontend nginx metrics
```

**Terraform Monitoring Setup**:
```hcl
# monitoring-stack/prometheus-grafana.tf

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  
  values = [
    templatefile("${path.module}/alertmanager-values.yaml.tpl", {
      # Alert configuration
    })
  ]
}

resource "kubernetes_ingress_v1" "grafana" {
  # Grafana ingress with ALB
}
```

---

#### **Step 25-26: Grafana Dashboards**
```
Set Up Grafana Dashboard → Prometheus End-to-End Test
```

**Grafana Dashboards**:

```yaml
Pre-configured Dashboards:
  1. Kubernetes Cluster Overview:
     - Node CPU/Memory usage
     - Pod count
     - Namespace resources
  
  2. Application Metrics:
     - Request rate
     - Response time
     - Error rate
     - JVM metrics (backend)
  
  3. Infrastructure Metrics:
     - Node health
     - Disk usage
     - Network I/O
  
  4. Database Metrics:
     - Connection pool
     - Query performance
     - Database size
  
  5. Custom ProductX Dashboard:
     - Product CRUD operations
     - API endpoint performance
     - User activity
     - Business metrics

Alert Rules:
  - High CPU usage (>80%)
  - High memory usage (>85%)
  - Pod restart count
  - API error rate (>5%)
  - Database connection failures
```

---

### **Phase 7: Testing & Validation** ✅

#### **Step 27-29: Pipeline Testing**
```
Deploy CICD Pipeline → Verify Live Update → Optimize Metrics
```

**Validation Tests**:

```yaml
Test 1: CI/CD Pipeline End-to-End
  - Push code change
  - Verify CI runs
  - Verify build & release
  - Verify staging deployment
  - Approve production
  - Verify production deployment

Test 2: Live Update Verification
  - Make code change
  - Push to main branch
  - Monitor pipeline execution
  - Verify zero-downtime deployment
  - Check application version

Test 3: Metrics Optimization
  - Review Prometheus metrics
  - Optimize scrape intervals
  - Tune alert thresholds
  - Validate HPA behavior
```

---

#### **Step 30-32: Chaos Engineering**
```
Simulate Failure → Validate System Recovery → End
```

**Failure Scenarios**:

```yaml
Scenario 1: Pod Failure
  Test:
    - kubectl delete pod {backend-pod}
  Expected:
    - Kubernetes recreates pod automatically
    - HPA maintains desired replicas
    - No service disruption
    - Prometheus alerts fire
  Validation:
    - Check pod count returns to normal
    - Check application health
    - Check Grafana for recovery time

Scenario 2: Node Failure
  Test:
    - Simulate node failure
  Expected:
    - Pods rescheduled to healthy nodes
    - Services remain available
    - Data persists (NFS, Database)
  Validation:
    - Check pod distribution
    - Check data integrity
    - Check recovery time

Scenario 3: Database Connection Loss
  Test:
    - Block database connection
  Expected:
    - Application handles gracefully
    - Connection pool retries
    - Alerts fire
  Validation:
    - Check error logs
    - Check connection recovery
    - Check data consistency

Scenario 4: High Load
  Test:
    - Generate high traffic
  Expected:
    - HPA scales up pods
    - Response time acceptable
    - No errors
  Validation:
    - Check HPA scaling
    - Check metrics
    - Check resource usage

Scenario 5: Rollback
  Test:
    - Deploy broken version
  Expected:
    - Health checks fail
    - Automatic rollback
    - Previous version restored
  Validation:
    - Check deployment history
    - Check application version
    - Check zero data loss
```

---

## 📊 Deployment Environments

### **Environment Comparison**

| Aspect | Staging | Production |
|--------|---------|------------|
| **Namespace** | `productx-staging` | `productx` |
| **URL** | staging.tranduchuy.site | www.tranduchuy.site |
| **Replicas** | 1 (backend), 1 (frontend) | 2 (backend), 2 (frontend) |
| **HPA** | Disabled | Enabled (2-10 pods) |
| **Database** | Shared with production | productx |
| **Resources** | Lower limits | Full limits |
| **Approval** | Automatic | Manual approval required |
| **Purpose** | Testing before production | Live user traffic |

---

## 🔐 Security & Best Practices

### **Security Measures**

```yaml
1. Secrets Management:
   - GitHub Secrets for sensitive data
   - Kubernetes Secrets for runtime
   - No secrets in code/logs

2. Image Security:
   - Trivy vulnerability scanning
   - Multi-stage Docker builds
   - Non-root containers
   - Minimal base images

3. Network Security:
   - Private subnets for database/NFS
   - Security groups
   - ALB with SSL/TLS
   - Network policies

4. Access Control:
   - IAM roles for EKS
   - RBAC for Kubernetes
   - GitHub environment protection
   - Manual approval for production

5. Monitoring & Auditing:
   - Prometheus metrics
   - Application logs
   - Kubernetes events
   - Deployment history
```

---

## 📈 Monitoring & Observability

### **Key Metrics**

```yaml
Application Metrics:
  - Request rate (req/s)
  - Response time (ms)
  - Error rate (%)
  - Active connections
  - JVM heap usage
  - Database query time

Infrastructure Metrics:
  - CPU usage (%)
  - Memory usage (%)
  - Disk I/O
  - Network I/O
  - Pod count
  - Node health

Business Metrics:
  - Product CRUD operations
  - API endpoint usage
  - User activity
  - Data volume
```

---

## 🎯 Success Criteria

### **Pipeline Success Indicators**

```yaml
✅ CI Pipeline:
   - All tests pass
   - Code quality checks pass
   - Security scans pass
   - Build artifacts created

✅ Build & Release:
   - Docker images built
   - Images pushed to registry
   - Images scanned (no critical vulnerabilities)
   - GitHub release created

✅ Staging Deployment:
   - Pods running and healthy
   - All tests pass
   - No errors in logs
   - Ready for production

✅ Production Deployment:
   - Zero-downtime deployment
   - Health checks pass
   - Smoke tests pass
   - Monitoring active

✅ System Health:
   - All pods running
   - HPA functioning
   - Metrics collecting
   - Alerts configured
```

---

## 🚨 Troubleshooting Guide

### **Common Issues & Solutions**

```yaml
Issue 1: Deployment Timeout
  Symptoms:
    - "exceeded its progress deadline"
    - Pods not ready
  
  Debug Steps:
    1. kubectl get pods -n {namespace}
    2. kubectl describe pod {pod-name} -n {namespace}
    3. kubectl logs {pod-name} -n {namespace}
    4. kubectl get events -n {namespace}
  
  Common Causes:
    - Image pull failure
    - ConfigMap/Secret missing
    - Resource limits too low
    - Health check failing
    - Database connection failure

Issue 2: Health Check Failure
  Symptoms:
    - Readiness probe failing
    - Pod not receiving traffic
  
  Debug Steps:
    1. Check application logs
    2. Test health endpoint manually
    3. Verify ConfigMap/Secrets
    4. Check database connectivity
  
  Solutions:
    - Increase initialDelaySeconds
    - Fix application startup issues
    - Verify environment variables
    - Check database credentials

Issue 3: Image Pull Error
  Symptoms:
    - "ImagePullBackOff"
    - "ErrImagePull"
  
  Debug Steps:
    1. Verify image exists in Docker Hub
    2. Check image tag is correct
    3. Verify Docker Hub credentials
  
  Solutions:
    - Push image to registry
    - Fix image tag in deployment
    - Update imagePullSecrets

Issue 4: ConfigMap Not Found
  Symptoms:
    - Pod fails to start
    - "configmap not found" error
  
  Debug Steps:
    1. kubectl get configmap -n {namespace}
    2. Check workflow logs
  
  Solutions:
    - Ensure ConfigMap created before deployment
    - Check namespace is correct
    - Verify production ConfigMap exists (for staging)
```

---

## 📚 References

### **Documentation Links**

```yaml
Infrastructure:
  - Terraform: ./terraform/
  - Ansible: ./ansible/
  - Kubernetes: ./kubernetes/

CI/CD:
  - Workflows: ./.github/workflows/
  - CI: ./.github/workflows/ci.yml
  - Build: ./.github/workflows/build-release.yml
  - Staging: ./.github/workflows/deploy-staging.yml
  - Production: ./.github/workflows/deploy-cd.yml

Monitoring:
  - Prometheus: ./monitoring-stack/prometheus-grafana.tf
  - Grafana: ./kubernetes/monitoring/grafana-ingress.yaml
  - Metrics Server: ./monitoring-stack/metrics-server.tf

Application:
  - Backend: ./app/backend/
  - Frontend: ./app/frontend/
  - Docker Compose: ./docker-compose.yml
```

---

## 🎓 Learning Resources

### **Key Concepts**

```yaml
DevOps Practices:
  - Infrastructure as Code (IaC)
  - Configuration Management
  - Continuous Integration (CI)
  - Continuous Deployment (CD)
  - GitOps
  - Monitoring & Observability

Kubernetes Concepts:
  - Pods, Deployments, Services
  - ConfigMaps, Secrets
  - Ingress, Load Balancers
  - Horizontal Pod Autoscaling (HPA)
  - Namespaces
  - RBAC

AWS Services:
  - EKS (Elastic Kubernetes Service)
  - EC2 (Elastic Compute Cloud)
  - VPC (Virtual Private Cloud)
  - ACM (Certificate Manager)
  - Route53 (DNS)
  - EBS (Elastic Block Store)

Tools:
  - Terraform (IaC)
  - Ansible (Configuration)
  - Docker (Containerization)
  - GitHub Actions (CI/CD)
  - Prometheus (Monitoring)
  - Grafana (Visualization)
```

---

## 🏁 Conclusion

This CI/CD pipeline implements a complete DevOps workflow from code commit to production deployment with:

✅ **Automated Testing** - CI pipeline with linting, testing, security scanning
✅ **Containerization** - Docker images with multi-stage builds
✅ **Staging Environment** - Pre-production testing with automated tests
✅ **Production Deployment** - Zero-downtime rolling updates with health checks
✅ **Monitoring** - Prometheus & Grafana for observability
✅ **High Availability** - HPA, multiple replicas, load balancing
✅ **Security** - Secrets management, vulnerability scanning, HTTPS
✅ **Disaster Recovery** - Automated rollback, failure simulation

**Total Pipeline Steps**: 32 steps from start to end
**Deployment Time**: ~15-20 minutes (CI → Build → Staging → Production)
**Uptime**: 99.9% with zero-downtime deployments

---

**Document Version**: 1.0
**Last Updated**: 2026-04-28
**Maintained By**: DevOps Team
