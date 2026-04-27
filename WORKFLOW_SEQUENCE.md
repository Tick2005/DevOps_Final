# GitHub Actions Workflow Sequence Guide

## Overview

This document explains the complete CI/CD pipeline workflow sequence for the ProductX application.

---

## Workflow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     INFRASTRUCTURE SETUP                         │
│                    (Manual/One-time)                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  1. infrastructure-cd.yml                                        │
│     - Terraform: VPC, EKS, EC2, ACM                             │
│     - Ansible: Database, NFS Server                             │
│     - Helm: Monitoring Stack (Prometheus, Grafana)              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     APPLICATION DEPLOYMENT                       │
│                    (Automatic on push)                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. build-ci.yml (CI Pipeline)                                   │
│     - Security Scan (Trivy)                                      │
│     - Build Docker Images                                        │
│     - Push to Docker Hub                                         │
│     - Tag: sha-{commit} and latest                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    (Triggers on success)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. deploy-cd.yml (CD Pipeline)                                  │
│     - Deploy to EKS                                              │
│     - Health Checks                                              │
│     - Smoke Tests (CRUD)                                         │
│     - Auto Rollback on Failure                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Detailed Workflow Sequence

### Phase 1: Infrastructure Setup (One-time)

**Workflow:** `infrastructure-cd.yml`

**Trigger:** Manual (`workflow_dispatch`)

**Steps:**

1. **Terraform Apply**
   ```
   ├── Create VPC (10.0.0.0/16)
   ├── Create Public/Private Subnets
   ├── Create Internet Gateway & NAT Gateway
   ├── Create EKS Cluster
   ├── Create Node Groups (2-4 nodes)
   ├── Create EC2 Instances (Database, NFS)
   ├── Create ACM Certificate
   ├── Configure Route53 DNS
   └── Install EBS CSI Driver & ALB Controller
   ```

2. **Ansible Configuration**
   ```
   ├── Configure Database Server
   │   ├── Install PostgreSQL
   │   ├── Create Database & User
   │   └── Configure Security
   ├── Configure NFS Server
   │   ├── Install NFS Server
   │   ├── Create Shared Directory
   │   └── Configure Exports
   ```

3. **Monitoring Stack**
   ```
   ├── Install Prometheus
   ├── Install Grafana
   ├── Install Alertmanager
   ├── Install Metrics Server
   └── Configure Dashboards
   ```

**Duration:** ~20-30 minutes

**Output:**
- EKS Cluster URL
- Database Endpoint
- NFS Server IP
- Load Balancer DNS
- Grafana URL

---

### Phase 2: Continuous Integration (Automatic)

**Workflow:** `build-ci.yml`

**Trigger:** 
- Push to `main` branch
- Pull request to `main`
- Manual dispatch

**Steps:**

1. **Security Scanning (Trivy)**
   ```
   ├── Scan Backend Code
   │   ├── Check for vulnerabilities
   │   ├── Check for secrets
   │   └── Check for misconfigurations
   ├── Scan Frontend Code
   │   ├── Check dependencies
   │   └── Check for known CVEs
   ```

2. **Build Docker Images**
   ```
   Backend:
   ├── Build Java application (Maven)
   ├── Create Docker image
   ├── Tag: sha-{commit}, latest
   └── Push to Docker Hub
   
   Frontend:
   ├── Build React application (Vite)
   ├── Create Docker image with Nginx
   ├── Tag: sha-{commit}, latest
   └── Push to Docker Hub
   ```

**Duration:** ~5-10 minutes

**Artifacts:**
- `{username}/productx-backend:sha-{commit}`
- `{username}/productx-backend:latest`
- `{username}/productx-frontend:sha-{commit}`
- `{username}/productx-frontend:latest`

---

### Phase 3: Continuous Deployment (Automatic)

**Workflow:** `deploy-cd.yml`

**Trigger:** 
- Successful completion of `build-ci.yml`
- Manual dispatch (with custom image tag)

**Steps:**

1. **Pre-Deployment**
   ```
   ├── Configure AWS credentials
   ├── Update kubeconfig for EKS
   ├── Determine image tag (sha-{commit} or custom)
   └── Update deployment manifests
   ```

2. **Deploy Application**
   ```
   ├── Deploy Backend
   │   ├── Update deployment.yaml
   │   ├── Apply service.yaml
   │   ├── Apply hpa.yaml
   │   └── Rollout restart
   ├── Deploy Frontend
   │   ├── Update deployment.yaml
   │   ├── Apply service.yaml
   │   ├── Apply hpa.yaml
   │   └── Rollout restart
   └── Update Ingress
   ```

3. **Wait for Rollout**
   ```
   ├── Wait for backend pods (timeout: 180s)
   ├── Wait for frontend pods (timeout: 180s)
   └── Additional 30s for app initialization
   ```

4. **Health Checks**
   ```
   ├── Backend API Health
   │   ├── Check /api/actuator/health
   │   ├── Retry up to 15 times
   │   └── Wait 20s between retries
   └── Frontend Health
       ├── Check / (root path)
       └── Verify HTTP 200
   ```

5. **Smoke Tests**
   ```
   ├── Test 1: List Products (GET /api/products)
   ├── Test 2: Get Single Product (GET /api/products/1)
   ├── Test 3: Create Product (POST /api/products)
   ├── Test 4: Update Product (PUT /api/products/{id})
   └── Test 5: Delete Product (DELETE /api/products/{id})
   ```

6. **Rollback on Failure**
   ```
   If any health check or smoke test fails:
   ├── Rollback backend deployment
   ├── Rollback frontend deployment
   ├── Wait for rollback completion
   └── Exit with error
   ```

**Duration:** ~8-15 minutes

**Success Criteria:**
- All pods running
- Health checks pass
- All smoke tests pass

---

## Workflow Triggers Summary

| Workflow | Trigger | Frequency | Purpose |
|----------|---------|-----------|---------|
| `infrastructure-cd.yml` | Manual | Once | Setup infrastructure |
| `build-ci.yml` | Push to main | Every commit | Build & test |
| `deploy-cd.yml` | CI success | After CI | Deploy to production |

---

## Manual Workflow Execution

### 1. Infrastructure Setup
```bash
# Via GitHub CLI
gh workflow run infrastructure-cd.yml

# Via GitHub UI
Actions → Infrastructure CD → Run workflow
```

### 2. Build & Release (Manual)
```bash
# Via GitHub CLI
gh workflow run build-ci.yml

# Via GitHub UI
Actions → Build & Release Docker → Run workflow
```

### 3. Deploy with Custom Tag
```bash
# Via GitHub CLI
gh workflow run deploy-cd.yml \
  -f image_tag="v1.2.3" \
  -f reason="Hotfix deployment"

# Via GitHub UI
Actions → Continuous Deployment → Run workflow
  - Image tag: v1.2.3
  - Reason: Hotfix deployment
```

---

## Workflow Dependencies

```
infrastructure-cd.yml (Manual)
    ↓
    Creates: EKS, Database, NFS
    ↓
build-ci.yml (Automatic on push)
    ↓
    Creates: Docker images
    ↓
deploy-cd.yml (Automatic on CI success)
    ↓
    Deploys: Application to EKS
```

---

## Environment Variables

### Global (All Workflows)
```yaml
AWS_REGION: ap-southeast-1
DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
```

### Infrastructure Workflow
```yaml
TF_VAR_cluster_name: productx-eks-cluster
TF_VAR_region: ap-southeast-1
```

### CI Workflow
```yaml
BACKEND_IMAGE: productx-backend
FRONTEND_IMAGE: productx-frontend
```

### CD Workflow
```yaml
NAMESPACE: productx
DEPLOYMENT_TIMEOUT: 180s
HEALTH_CHECK_RETRIES: 15
```

---

## Rollback Strategies

### 1. Automatic Rollback (Built-in)
- Triggered on health check failure
- Triggered on smoke test failure
- Uses `kubectl rollout undo`

### 2. Manual Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n productx
kubectl rollout undo deployment/frontend -n productx

# Rollback to specific revision
kubectl rollout undo deployment/backend -n productx --to-revision=2

# Check rollout history
kubectl rollout history deployment/backend -n productx
```

### 3. Deploy Specific Version
```bash
# Via GitHub Actions
gh workflow run deploy-cd.yml \
  -f image_tag="sha-abc1234" \
  -f reason="Rollback to stable version"
```

---

## Monitoring Workflow Status

### Via GitHub CLI
```bash
# List recent workflow runs
gh run list --workflow=build-ci.yml --limit 5

# Watch specific run
gh run watch <run-id>

# View run logs
gh run view <run-id> --log
```

### Via GitHub UI
```
Repository → Actions → Select workflow → View runs
```

### Via Slack/Email (Optional)
Configure notifications in workflow:
```yaml
- name: Notify on Failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Best Practices

1. **Always test in staging first**
   - Create separate workflows for staging
   - Use different namespaces

2. **Use semantic versioning for releases**
   - Tag releases: `v1.0.0`, `v1.1.0`
   - Deploy tagged versions to production

3. **Monitor deployment metrics**
   - Check Grafana dashboards
   - Review pod logs
   - Monitor error rates

4. **Keep workflows DRY**
   - Use reusable workflows
   - Extract common steps

5. **Secure secrets**
   - Rotate regularly
   - Use environment-specific secrets
   - Never log secrets

---

## Troubleshooting

### CI Fails on Security Scan
```
Error: HIGH severity vulnerabilities found
```
**Solution:** Update dependencies, review Trivy report

### CD Fails on Health Check
```
Error: Backend API health check failed
```
**Solution:** 
1. Check pod logs: `kubectl logs -l app=backend -n productx`
2. Check service endpoints: `kubectl get endpoints -n productx`
3. Verify database connectivity

### Deployment Timeout
```
Error: Waiting for rollout to finish: 0 of 2 updated replicas are available
```
**Solution:**
1. Check pod status: `kubectl get pods -n productx`
2. Describe pod: `kubectl describe pod <pod-name> -n productx`
3. Check resource limits
4. Verify image pull success

### Smoke Tests Fail
```
Error: Test 3 FAILED: Cannot create product
```
**Solution:**
1. Check API logs
2. Verify database connection
3. Test API manually: `curl https://www.domain.com/api/products`

---

## Next Steps

After successful deployment:
1. ✅ Verify application at `https://www.{domain}`
2. ✅ Check Grafana dashboards
3. ✅ Review application logs
4. ✅ Monitor error rates
5. ✅ Test all features manually
