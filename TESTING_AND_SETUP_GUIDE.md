# 🧪 Testing & Setup Guide - Sau Khi Push Code

## 📋 Tổng Quan

Guide này hướng dẫn chi tiết các bước testing và cấu hình sau khi push code lên GitHub và GitHub Actions bắt đầu chạy.

---

## 🚀 PHASE 1: PUSH CODE LÊN GITHUB

### Bước 1.1: Commit và Push Code

```bash
cd DevOps_Final

# Stage all changes
git add .

# Commit với message rõ ràng
git commit -m "feat: add complete CI/CD pipeline with staging, health checks, and chaos testing"

# Push to main branch
git push origin main
```

**Expected Output:**
```
Enumerating objects: 25, done.
Counting objects: 100% (25/25), done.
Delta compression using up to 8 threads
Compressing objects: 100% (20/20), done.
Writing objects: 100% (20/20), 15.23 KiB | 1.52 MiB/s, done.
Total 20 (delta 12), reused 0 (delta 0), pack-reused 0
To github.com:YOUR_USERNAME/DevOps_Final.git
   abc1234..def5678  main -> main
```

### Bước 1.2: Verify Push Thành Công

```bash
# Check git log
git log --oneline -1

# Expected: Your commit message appears
```

---

## 🔄 PHASE 2: GITHUB ACTIONS BẮT ĐẦU CHẠY

### Bước 2.1: Truy Cập GitHub Actions

1. Mở browser và truy cập:
   ```
   https://github.com/YOUR_USERNAME/DevOps_Final/actions
   ```

2. Bạn sẽ thấy workflows đang chạy:
   - ⏳ **Build & Release Docker** (main-ci.yml) - Running
   - ⏸️ **Infrastructure Provisioning** (infrastructure-cd.yml) - Waiting (nếu có thay đổi terraform/ansible)

### Bước 2.2: Monitor Workflow Progress

Click vào workflow **"Build & Release Docker"** để xem chi tiết:

```
Jobs:
├── wait-for-infrastructure ⏳ (1-2 minutes)
├── build-backend ⏳ (5-7 minutes)
└── build-frontend ⏳ (3-5 minutes)
```

---

## ⚙️ PHASE 3: TRONG KHI GITHUB ACTIONS ĐANG CHẠY

### 🔧 Cấu Hình Cần Thiết (Nếu Chưa Có)

#### 3.1: Kiểm Tra GitHub Secrets

**Truy cập:**
```
Settings → Secrets and variables → Actions → Repository secrets
```

**Required Secrets:**

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | AWS IAM Console |
| `AWS_KEY_NAME` | EC2 Key Pair Name | AWS EC2 Console |
| `EKS_CLUSTER_NAME` | EKS Cluster Name | `productx-eks-cluster` |
| `DOCKER_USERNAME` | Docker Hub Username | Docker Hub |
| `DOCKER_PASSWORD` | Docker Hub Password | Docker Hub |
| `DB_PASSWORD` | Database Password | Your choice (strong password) |
| `DOMAIN_NAME` | Your Domain | `tranduchuy.site` |
| `TF_BACKEND_BUCKET` | S3 Bucket for Terraform State | Run `bootstrap-backend.sh` |
| `EC2_SSH_PRIVATE_KEY` | SSH Private Key for EC2 | Your EC2 key pair |
| `GRAFANA_ADMIN_PASSWORD` | Grafana Admin Password | Your choice (strong password) |
| `ALERT_EMAIL` | Email for Alerts | Your email |
| `ALERT_EMAIL_PASSWORD` | Email App Password | Gmail App Password |

**⚠️ Nếu thiếu secrets, workflow sẽ fail!**

#### 3.2: Kiểm Tra AWS Credentials

```bash
# Test AWS credentials locally
aws sts get-caller-identity

# Expected output:
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

#### 3.3: Kiểm Tra Docker Hub Login

```bash
# Test Docker Hub login
docker login

# Enter username and password
# Expected: Login Succeeded
```

---

## ✅ PHASE 4: SAU KHI CI WORKFLOW THÀNH CÔNG

### Bước 4.1: Verify Docker Images

**Truy cập Docker Hub:**
```
https://hub.docker.com/u/YOUR_DOCKER_USERNAME
```

**Kiểm tra images:**
- ✅ `YOUR_DOCKER_USERNAME/productx-backend:sha-XXXXXXX`
- ✅ `YOUR_DOCKER_USERNAME/productx-frontend:sha-XXXXXXX`

**Hoặc dùng CLI:**
```bash
# List images on Docker Hub
docker search YOUR_DOCKER_USERNAME/productx-backend
docker search YOUR_DOCKER_USERNAME/productx-frontend
```

### Bước 4.2: Staging Deployment Tự Động Chạy

**Monitor Staging Workflow:**

1. Quay lại GitHub Actions
2. Workflow **"Deploy to Staging"** sẽ tự động chạy
3. Monitor progress:

```
Jobs:
├── deploy-staging ⏳ (3-5 minutes)
│   ├── Create staging namespace
│   ├── Deploy backend & frontend
│   ├── Run health checks
│   └── Run smoke tests
│
└── promote-to-production ⏸️ (Waiting for approval)
```

### Bước 4.3: Review Staging Test Results

**Trong staging job, kiểm tra:**

✅ **Health Check Results:**
```
🏥 Checking Backend API health...
✅ Backend API is healthy (HTTP 200)
```

✅ **Smoke Test Results:**
```
🧪 Running Staging Tests...
Test 1: GET /api/products ✅ PASSED
Test 2: List Products ✅ PASSED
Test 3: Create Product ✅ PASSED
✅ Cleanup completed
🎉 All staging tests PASSED!
```

**⚠️ Nếu tests fail:**
- Workflow sẽ tự động rollback staging
- Check logs để debug
- Fix issues và push lại

---

## 🎯 PHASE 5: APPROVE PRODUCTION DEPLOYMENT

### Bước 5.1: Manual Approval

1. Trong GitHub Actions, click vào workflow **"Deploy to Staging"**
2. Tìm job **"promote-to-production"**
3. Click **"Review deployments"**
4. Select **"production-approval"**
5. Click **"Approve and deploy"**

**Screenshot location:**
```
GitHub Actions → Deploy to Staging → promote-to-production → Review deployments
```

### Bước 5.2: Production Deployment Starts

Sau khi approve, workflow **"Continuous Deployment (CD)"** sẽ tự động chạy:

```
Jobs:
└── deploy ⏳ (5-10 minutes)
    ├── Deploy to production
    ├── Wait for pods ready
    ├── Health check - Backend
    ├── Health check - Frontend
    ├── Smoke tests - CRUD
    └── Success or Rollback
```

### Bước 5.3: Monitor Production Deployment

**Watch for:**

✅ **Deployment Progress:**
```
🚀 Deploying Application to EKS...
📦 Deploying Backend...
📦 Deploying Frontend...
🔄 Rolling out new images...
⏳ Waiting for rollout to complete...
✅ Application deployed successfully!
```

✅ **Health Checks:**
```
🏥 Checking Backend API health...
Attempt 1/10: Checking https://www.tranduchuy.site/api/actuator/health
✅ Backend API is healthy (HTTP 200)

🏥 Checking Frontend health...
✅ Frontend is healthy (HTTP 200)
```

✅ **Smoke Tests:**
```
🧪 Running Smoke Tests...
Test 1: GET /api/products ✅ PASSED
Test 2: GET /api/products/1 ✅ PASSED
Test 3: POST /api/products ✅ PASSED
Test 4: PUT /api/products/X ✅ PASSED
Test 5: DELETE /api/products/X ✅ PASSED
🎉 All smoke tests PASSED!
```

**⚠️ Nếu bất kỳ check nào fail:**
```
🔄 DEPLOYMENT FAILED - INITIATING ROLLBACK
Rolling back backend deployment...
Rolling back frontend deployment...
✅ Rollback completed!
```

---

## 🎉 PHASE 6: SAU KHI DEPLOYMENT THÀNH CÔNG

### Bước 6.1: Verify Application is Live

**Test Production URL:**
```bash
# Test backend health
curl https://www.tranduchuy.site/api/actuator/health

# Expected:
{"status":"UP"}

# Test frontend
curl -I https://www.tranduchuy.site/

# Expected:
HTTP/2 200
```

**Hoặc mở browser:**
```
https://www.tranduchuy.site
```

### Bước 6.2: Test CRUD Operations

**Test trong browser hoặc Postman:**

1. **List Products:**
   ```
   GET https://www.tranduchuy.site/api/products
   ```

2. **Get Single Product:**
   ```
   GET https://www.tranduchuy.site/api/products/1
   ```

3. **Create Product:**
   ```
   POST https://www.tranduchuy.site/api/products
   Content-Type: application/json
   
   {
     "name": "Test Product",
     "price": 99.99,
     "color": "Blue",
     "category": "Test",
     "stock": 10,
     "description": "Test product",
     "image": "https://via.placeholder.com/150"
   }
   ```

4. **Update Product:**
   ```
   PUT https://www.tranduchuy.site/api/products/1
   Content-Type: application/json
   
   {
     "name": "Updated Product",
     "price": 149.99,
     ...
   }
   ```

5. **Delete Product:**
   ```
   DELETE https://www.tranduchuy.site/api/products/1
   ```

---

## 📊 PHASE 7: CẤU HÌNH MONITORING

### 7.1: Truy Cập Prometheus

**Setup Port Forward:**
```bash
# Configure kubectl
aws eks update-kubeconfig --name productx-eks-cluster --region ap-southeast-1

# Port forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

**Truy cập Prometheus:**
```
http://localhost:9090
```

**Kiểm tra:**

1. **Status → Targets:**
   - Verify all targets are UP
   - Should see: node-exporter, kube-state-metrics, kubelet, etc.

2. **Graph:**
   - Query: `up`
   - Should see all services with value 1

3. **Alerts:**
   - Check if any alerts are firing

**Useful Queries:**
```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# Memory usage by pod
sum(container_memory_usage_bytes) by (pod)

# HTTP request rate
rate(http_requests_total[5m])

# Pod restart count
kube_pod_container_status_restarts_total
```

### 7.2: Truy Cập Grafana

**Setup Port Forward:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

**Truy cập Grafana:**
```
http://localhost:3000
```

**Login Credentials:**
- Username: `admin`
- Password: (từ secret `GRAFANA_ADMIN_PASSWORD`)

**Hoặc get password từ Kubernetes:**
```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

**Cấu hình Grafana:**

#### 7.2.1: Verify Data Source

1. Click **Configuration** (⚙️) → **Data Sources**
2. Verify **Prometheus** data source exists
3. Click **Test** → Should see "Data source is working"

#### 7.2.2: Import Dashboards

**Pre-installed Dashboards:**
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Node (Pods)
- Node Exporter / Nodes

**Import Additional Dashboards:**

1. Click **+** → **Import**
2. Enter Dashboard ID:
   - **1860** - Node Exporter Full
   - **6417** - Kubernetes Cluster Monitoring
   - **8588** - Kubernetes Deployment Statefulset Daemonset metrics
   - **13770** - Kubernetes / Views / Pods

3. Select **Prometheus** as data source
4. Click **Import**

#### 7.2.3: Create Custom Dashboard for ProductX

1. Click **+** → **Dashboard** → **Add new panel**

2. **Panel 1: Backend Pod CPU Usage**
   ```promql
   sum(rate(container_cpu_usage_seconds_total{namespace="productx",pod=~"backend.*"}[5m])) by (pod)
   ```

3. **Panel 2: Backend Pod Memory Usage**
   ```promql
   sum(container_memory_usage_bytes{namespace="productx",pod=~"backend.*"}) by (pod)
   ```

4. **Panel 3: Frontend Pod CPU Usage**
   ```promql
   sum(rate(container_cpu_usage_seconds_total{namespace="productx",pod=~"frontend.*"}[5m])) by (pod)
   ```

5. **Panel 4: Pod Restart Count**
   ```promql
   kube_pod_container_status_restarts_total{namespace="productx"}
   ```

6. **Panel 5: HTTP Request Rate** (if metrics available)
   ```promql
   rate(http_requests_total{namespace="productx"}[5m])
   ```

7. Save Dashboard:
   - Name: **ProductX Application Monitoring**
   - Folder: **General**

### 7.3: Truy Cập Alertmanager

**Setup Port Forward:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```

**Truy cập Alertmanager:**
```
http://localhost:9093
```

**Cấu hình Alerts:**

#### 7.3.1: Verify Alert Configuration

1. Check **Status** page
2. Verify email configuration is loaded

#### 7.3.2: Test Alert

**Create test alert:**
```bash
# Port forward Alertmanager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093 &

# Send test alert
curl -X POST http://localhost:9093/api/v1/alerts -d '[
  {
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning"
    },
    "annotations": {
      "summary": "This is a test alert"
    }
  }
]'
```

**Check email:**
- Should receive alert email within 1-2 minutes

#### 7.3.3: Configure Alert Rules (Optional)

**Edit Prometheus rules:**
```bash
# Get current rules
kubectl get prometheusrules -n monitoring

# Edit rules
kubectl edit prometheusrule kube-prometheus-stack-kubernetes-apps -n monitoring
```

**Example custom alert:**
```yaml
- alert: HighPodMemory
  expr: |
    sum(container_memory_usage_bytes{namespace="productx"}) by (pod) 
    / sum(container_spec_memory_limit_bytes{namespace="productx"}) by (pod) 
    > 0.9
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Pod {{ $labels.pod }} memory usage is above 90%"
```

---

## 🔍 PHASE 8: KIỂM TRA HỆ THỐNG

### 8.1: Check Kubernetes Resources

```bash
# Configure kubectl
aws eks update-kubeconfig --name productx-eks-cluster --region ap-southeast-1

# Check all resources in productx namespace
kubectl get all -n productx

# Expected output:
NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-xxx                 1/1     Running   0          10m
pod/backend-yyy                 1/1     Running   0          10m
pod/frontend-xxx                1/1     Running   0          10m
pod/frontend-yyy                1/1     Running   0          10m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/backend-svc    ClusterIP   10.100.x.x      <none>        8080/TCP   10m
service/frontend-svc   ClusterIP   10.100.x.x      <none>        80/TCP     10m

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/backend    2/2     2            2           10m
deployment.apps/frontend   2/2     2            2           10m

# Check ingress
kubectl get ingress -n productx

# Expected:
NAME          CLASS   HOSTS                    ADDRESS                          PORTS     AGE
app-ingress   alb     www.tranduchuy.site      xxx.elb.amazonaws.com            80, 443   10m

# Check HPA
kubectl get hpa -n productx

# Expected:
NAME           REFERENCE             TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
backend-hpa    Deployment/backend    <unknown>/80%   2         10        2          10m
frontend-hpa   Deployment/frontend   <unknown>/80%   2         10        2          10m
```

### 8.2: Check Pod Logs

```bash
# Backend logs
kubectl logs -l app=backend -n productx --tail=50

# Frontend logs
kubectl logs -l app=frontend -n productx --tail=50

# Check for errors
kubectl logs -l app=backend -n productx --tail=100 | grep -i error
```

### 8.3: Check Monitoring Pods

```bash
# Check monitoring namespace
kubectl get pods -n monitoring

# Expected:
NAME                                                        READY   STATUS    RESTARTS   AGE
alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running   0          20m
kube-prometheus-stack-grafana-xxx                           3/3     Running   0          20m
kube-prometheus-stack-kube-state-metrics-xxx                1/1     Running   0          20m
kube-prometheus-stack-operator-xxx                          1/1     Running   0          20m
kube-prometheus-stack-prometheus-node-exporter-xxx          1/1     Running   0          20m
prometheus-kube-prometheus-stack-prometheus-0               2/2     Running   0          20m

# Check PVCs
kubectl get pvc -n monitoring

# Expected:
NAME                                                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
prometheus-kube-prometheus-stack-prometheus-db-xxx          Bound    pvc-xxx                                    50Gi       RWO            gp3            20m
storage-kube-prometheus-stack-grafana-0                     Bound    pvc-xxx                                    10Gi       RWO            gp3            20m
```

### 8.4: Check Node Resources

```bash
# Check nodes
kubectl get nodes

# Check node resources
kubectl top nodes

# Expected:
NAME                                           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
ip-10-0-1-xxx.ap-southeast-1.compute.internal  500m         12%    2000Mi          50%
ip-10-0-2-xxx.ap-southeast-1.compute.internal  450m         11%    1900Mi          47%

# Check pod resources
kubectl top pods -n productx

# Expected:
NAME              CPU(cores)   MEMORY(bytes)
backend-xxx       50m          500Mi
backend-yyy       45m          480Mi
frontend-xxx      10m          100Mi
frontend-yyy      12m          110Mi
```

---

## 🧪 PHASE 9: RUN CHAOS TESTS (OPTIONAL)

### 9.1: Trigger Chaos Testing Workflow

1. Go to GitHub Actions
2. Select **"Chaos Testing & Recovery Validation"**
3. Click **"Run workflow"**
4. Select:
   - **Test type:** `all-tests` (or specific test)
   - **Environment:** `staging` (recommended first time)
5. Click **"Run workflow"**

### 9.2: Monitor Chaos Tests

**Watch test progress:**

```
Jobs:
├── pod-failure-test ⏳ (5-10 minutes)
│   ├── Delete pods
│   ├── Wait for recovery
│   ├── Validate recovery
│   └── Test application health
│
├── node-stress-test ⏳ (5-10 minutes)
│   ├── Check node resources
│   ├── Simulate load
│   └── Verify HPA scaling
│
├── network-latency-test ⏳ (5-10 minutes)
│   ├── Test connectivity
│   ├── Measure response times
│   └── Verify performance
│
└── chaos-test-report ⏳ (1 minute)
    └── Generate report
```

### 9.3: Review Chaos Test Results

**Expected results:**

✅ **Pod Failure Test:**
```
💥 Simulating pod failure...
Deleting backend pod: backend-xxx
Deleting frontend pod: frontend-xxx
⏳ Waiting for Kubernetes to recover pods...
✅ Pods recovered!
✅ All pods are running
✅ Application is healthy after recovery
✅ API is functional after recovery
```

✅ **Node Stress Test:**
```
📊 Checking node resources...
💪 Simulating load on application...
Sending 100 requests to backend...
✅ Load generation completed
✅ HPA is monitoring and ready to scale
```

✅ **Network Latency Test:**
```
🔍 Testing service connectivity...
✅ Services are accessible
✅ Network connectivity verified
⏱️ Measuring API response times...
Average response time: 0.5s
✅ Response time is acceptable
```

---

## 📝 PHASE 10: DOCUMENTATION & CLEANUP

### 10.1: Document Your Setup

**Create a deployment log:**
```bash
# Save deployment info
cat > deployment-log.md << EOF
# Deployment Log

**Date:** $(date)
**Commit:** $(git rev-parse HEAD)
**Deployed By:** $(git config user.name)

## Deployment Details
- Backend Image: YOUR_DOCKER_USERNAME/productx-backend:sha-$(git rev-parse --short HEAD)
- Frontend Image: YOUR_DOCKER_USERNAME/productx-frontend:sha-$(git rev-parse --short HEAD)
- Domain: https://www.tranduchuy.site
- Monitoring: Prometheus + Grafana + Alertmanager

## Test Results
- Health Checks: ✅ PASSED
- Smoke Tests: ✅ PASSED
- Chaos Tests: ✅ PASSED

## Access URLs
- Application: https://www.tranduchuy.site
- Prometheus: kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
- Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
- Alertmanager: kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
EOF
```

### 10.2: Cleanup (Optional)

**Stop port forwards:**
```bash
# Find port forward processes
ps aux | grep "port-forward"

# Kill port forwards
pkill -f "port-forward"
```

**Cleanup staging environment (if needed):**
```bash
# Delete staging namespace
kubectl delete namespace productx-staging
```

---

## ✅ FINAL CHECKLIST

### Infrastructure
- [ ] EKS cluster is running
- [ ] Database is accessible
- [ ] NFS is mounted
- [ ] Domain is configured
- [ ] HTTPS is working

### Application
- [ ] Backend pods are running (2/2)
- [ ] Frontend pods are running (2/2)
- [ ] Services are accessible
- [ ] Ingress is configured
- [ ] Application is accessible via HTTPS

### Monitoring
- [ ] Prometheus is collecting metrics
- [ ] Grafana dashboards are configured
- [ ] Alertmanager is sending alerts
- [ ] All monitoring pods are running

### Testing
- [ ] Health checks passed
- [ ] Smoke tests passed
- [ ] Chaos tests passed (optional)
- [ ] Manual testing completed

### Documentation
- [ ] Deployment log created
- [ ] Access URLs documented
- [ ] Credentials saved securely
- [ ] Team notified

---

## 🆘 TROUBLESHOOTING

### Issue 1: Workflow Fails at CI Stage

**Symptoms:**
- Build fails
- Security scan fails
- Docker push fails

**Solutions:**
```bash
# Check Docker Hub credentials
docker login

# Check if images build locally
cd app/backend/common
mvn clean package -DskipTests
docker build -t test-backend .

cd ../../frontend
npm install
npm run build
docker build -t test-frontend .

# Check Trivy scan locally
trivy image test-backend
trivy image test-frontend
```

### Issue 2: Staging Tests Fail

**Symptoms:**
- Health checks fail
- Smoke tests fail
- Pods not ready

**Solutions:**
```bash
# Check staging pods
kubectl get pods -n productx-staging

# Check pod logs
kubectl logs -l app=backend -n productx-staging --tail=100

# Check events
kubectl get events -n productx-staging --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod <pod-name> -n productx-staging
```

### Issue 3: Production Deployment Fails

**Symptoms:**
- Rollout timeout
- Health checks fail
- Rollback triggered

**Solutions:**
```bash
# Check deployment status
kubectl rollout status deployment/backend -n productx
kubectl rollout status deployment/frontend -n productx

# Check pod status
kubectl get pods -n productx

# Check logs
kubectl logs -l app=backend -n productx --tail=100

# Manual rollback if needed
kubectl rollout undo deployment/backend -n productx
kubectl rollout undo deployment/frontend -n productx
```

### Issue 4: Monitoring Not Working

**Symptoms:**
- Prometheus not collecting metrics
- Grafana not showing data
- Pods pending

**Solutions:**
```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Check PVCs
kubectl get pvc -n monitoring

# Check node resources
kubectl top nodes

# If Prometheus pending due to resources
# Upgrade node instance type in terraform/variables.tf
# Then run infrastructure workflow again

# Check Prometheus logs
kubectl logs -l app.kubernetes.io/name=prometheus -n monitoring

# Check Grafana logs
kubectl logs -l app.kubernetes.io/name=grafana -n monitoring
```

### Issue 5: Application Not Accessible

**Symptoms:**
- Domain not resolving
- HTTPS not working
- 502/503 errors

**Solutions:**
```bash
# Check ingress
kubectl get ingress -n productx
kubectl describe ingress app-ingress -n productx

# Check ALB
aws elbv2 describe-load-balancers --region ap-southeast-1

# Check DNS
nslookup www.tranduchuy.site

# Check certificate
aws acm list-certificates --region ap-southeast-1

# Test backend directly
kubectl port-forward -n productx svc/backend-svc 8080:8080
curl http://localhost:8080/api/actuator/health
```

---

## 📞 SUPPORT

### Documentation References
- `COMPLETE_CICD_GUIDE.md` - Complete CI/CD guide
- `WORKFLOW_EXECUTION_ORDER.md` - Workflow execution order
- `TROUBLESHOOTING.md` - Detailed troubleshooting guide

### Useful Commands
```bash
# Get all resources
kubectl get all -A

# Check logs
kubectl logs <pod-name> -n <namespace>

# Describe resource
kubectl describe <resource-type> <resource-name> -n <namespace>

# Get events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Port forward
kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<remote-port>
```

---

**Last Updated:** 2026-04-21  
**Version:** 1.0  
**Status:** ✅ Complete
