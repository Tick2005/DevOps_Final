# 🔍 SonarQube & Monitoring Configuration Guide

## 📋 Table of Contents
1. [Workflow Execution Order](#workflow-execution-order)
2. [When to Configure SonarQube](#when-to-configure-sonarqube)
3. [When to Access Monitoring](#when-to-access-monitoring)
4. [Step-by-Step Configuration](#step-by-step-configuration)

---

## 🔄 Workflow Execution Order

### **Complete Pipeline Flow:**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WORKFLOW EXECUTION ORDER                          │
└─────────────────────────────────────────────────────────────────────┘

1️⃣ INFRASTRUCTURE PROVISIONING (infrastructure-cd.yml)
   ├─ Trigger: Push to main (terraform/**, ansible/**, kubernetes/**)
   ├─ Duration: ~45-60 minutes
   └─ Jobs:
      ├─ Security Scan (Trivy IaC, TruffleHog)
      ├─ Terraform Plan
      ├─ Terraform Apply (EKS, VPC, EC2, etc.)
      ├─ Ansible Configuration (Database, NFS)
      ├─ Kubernetes Base Setup
      │  ├─ Install AWS Load Balancer Controller
      │  ├─ Install Monitoring Stack ⭐ (Prometheus, Grafana, Alertmanager)
      │  ├─ Apply Namespace, ConfigMap, Secrets
      │  └─ Apply Services, HPA, Ingress
      └─ ✅ Infrastructure Ready

   📊 MONITORING BECOMES AVAILABLE HERE! ⭐

2️⃣ BUILD & RELEASE (main-ci.yml)
   ├─ Trigger: Push to main (app/**)
   ├─ Duration: ~10-15 minutes
   ├─ Waits for: infrastructure-cd.yml to complete
   └─ Jobs:
      ├─ Build Backend (Maven, Docker)
      │  ├─ Build JAR
      │  ├─ Build Docker image
      │  └─ Trivy security scan
      ├─ Build Frontend (npm, Docker)
      │  ├─ Build React app
      │  ├─ Build Docker image
      │  └─ Trivy security scan
      └─ ✅ Images pushed to Docker Hub

   🔍 SONARQUBE SHOULD BE CONFIGURED BEFORE THIS! ⭐

3️⃣ STAGING DEPLOYMENT (deploy-staging.yml)
   ├─ Trigger: After main-ci.yml succeeds
   ├─ Duration: ~5-10 minutes
   └─ Jobs:
      ├─ Deploy to Staging (productx-staging namespace)
      ├─ Run Staging Tests (CRUD operations)
      └─ ✅ Staging Ready

4️⃣ PRODUCTION DEPLOYMENT (deploy-cd.yml)
   ├─ Trigger: Manual approval after staging
   ├─ Duration: ~10-15 minutes
   └─ Jobs:
      ├─ Deploy to Production (productx namespace)
      ├─ Health Checks
      ├─ Smoke Tests
      └─ ✅ Production Live

5️⃣ CHAOS TESTING (chaos-testing.yml)
   ├─ Trigger: Manual only
   ├─ Duration: ~10-20 minutes
   └─ Jobs:
      ├─ Pod Failure Test
      ├─ Node Stress Test
      ├─ Network Latency Test
      └─ ✅ System Resilience Verified
```

---

## 🔍 When to Configure SonarQube

### ⚠️ **IMPORTANT: SonarQube is NOT included in current workflows!**

Currently, the project uses **Trivy** for security scanning, not SonarQube. However, if you want to add SonarQube for code quality analysis:

### **Option 1: Add SonarQube to CI Pipeline (Recommended)**

**When**: BEFORE running `main-ci.yml` for the first time

**Why**: SonarQube analyzes code quality, bugs, vulnerabilities, and code smells

**Steps**:

1. **Set up SonarQube Server** (Choose one):
   
   **Option A: SonarCloud (Easiest)**
   ```bash
   # Go to https://sonarcloud.io
   # Sign in with GitHub
   # Create new organization
   # Add your repository
   # Get token from: Account → Security → Generate Token
   ```

   **Option B: Self-hosted SonarQube**
   ```bash
   # Deploy SonarQube on EC2 or EKS
   docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
   
   # Access: http://<your-ip>:9000
   # Default credentials: admin/admin
   # Create project and get token
   ```

2. **Add GitHub Secrets**:
   ```
   SONAR_TOKEN: <your-sonarqube-token>
   SONAR_HOST_URL: https://sonarcloud.io (or your server URL)
   SONAR_ORGANIZATION: <your-org> (for SonarCloud only)
   ```

3. **Modify `main-ci.yml`** - Add SonarQube scan job:

   ```yaml
   # Add this job BEFORE build-backend
   sonarqube-scan:
     name: SonarQube Code Analysis
     runs-on: ubuntu-latest
     needs: wait-for-infrastructure
     
     steps:
       - name: Checkout Repository
         uses: actions/checkout@v4
         with:
           fetch-depth: 0  # Full history for better analysis
       
       # Backend Analysis
       - name: Setup Java 21
         uses: actions/setup-java@v4
         with:
           distribution: 'temurin'
           java-version: '21'
       
       - name: Cache SonarQube packages
         uses: actions/cache@v4
         with:
           path: ~/.sonar/cache
           key: ${{ runner.os }}-sonar
       
       - name: SonarQube Scan - Backend
         working-directory: app/backend/common
         env:
           SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
           SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
         run: |
           mvn clean verify sonar:sonar \
             -Dsonar.projectKey=productx-backend \
             -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }} \
             -Dsonar.host.url=${{ secrets.SONAR_HOST_URL }} \
             -Dsonar.token=${{ secrets.SONAR_TOKEN }}
       
       # Frontend Analysis
       - name: Setup Node.js 20
         uses: actions/setup-node@v4
         with:
           node-version: '20'
       
       - name: Install Frontend Dependencies
         working-directory: app/frontend
         run: npm ci
       
       - name: SonarQube Scan - Frontend
         uses: SonarSource/sonarcloud-github-action@master
         env:
           SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
         with:
           projectBaseDir: app/frontend
           args: >
             -Dsonar.projectKey=productx-frontend
             -Dsonar.organization=${{ secrets.SONAR_ORGANIZATION }}
             -Dsonar.sources=src
             -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
   
   # Update build-backend to depend on sonarqube-scan
   build-backend:
     needs: [wait-for-infrastructure, sonarqube-scan]
     # ... rest of the job
   ```

4. **Access SonarQube Dashboard**:
   - **SonarCloud**: https://sonarcloud.io/projects
   - **Self-hosted**: http://your-server:9000

### **Timeline for SonarQube Configuration**:

```
┌─────────────────────────────────────────────────────────────────┐
│  WHEN TO CONFIGURE SONARQUBE                                    │
└─────────────────────────────────────────────────────────────────┘

BEFORE First Deployment:
  ├─ Day 0: Set up SonarQube account/server
  ├─ Day 0: Add GitHub secrets
  ├─ Day 0: Modify main-ci.yml
  └─ Day 0: Push changes to trigger workflow

AFTER Infrastructure is Ready:
  ├─ Infrastructure workflow completes ✅
  ├─ SonarQube scan runs (in main-ci.yml)
  ├─ Review code quality report
  ├─ Fix critical issues if needed
  └─ Continue with build & deployment
```

---

## 📊 When to Access Monitoring

### ✅ **Monitoring is AUTOMATICALLY installed during infrastructure workflow!**

**When**: AFTER `infrastructure-cd.yml` completes (Step: "Install Monitoring Stack via Terraform")

**What's Installed**:
- ✅ Prometheus (metrics collection)
- ✅ Grafana (visualization & dashboards)
- ✅ Alertmanager (alert routing)
- ✅ Metrics Server (HPA support)

### **Timeline**:

```
┌─────────────────────────────────────────────────────────────────┐
│  MONITORING AVAILABILITY TIMELINE                               │
└─────────────────────────────────────────────────────────────────┘

infrastructure-cd.yml starts
  ├─ [0-30 min] Terraform provisions infrastructure
  ├─ [30-40 min] Ansible configures servers
  ├─ [40-50 min] Kubernetes base setup
  │
  ├─ [45 min] ⭐ Install Monitoring Stack
  │   ├─ Deploy Prometheus Operator
  │   ├─ Deploy Prometheus
  │   ├─ Deploy Grafana
  │   ├─ Deploy Alertmanager
  │   └─ Deploy Metrics Server
  │
  ├─ [50-55 min] Wait for monitoring pods to be ready
  ├─ [55-60 min] Test Prometheus, Grafana, Alertmanager health
  │
  └─ [60 min] ✅ Monitoring is READY!

📊 YOU CAN ACCESS MONITORING NOW! ⭐
```

---

## 🚀 Step-by-Step Configuration

### **STEP 1: Wait for Infrastructure Workflow to Complete**

1. **Trigger infrastructure workflow**:
   ```bash
   # Push changes to terraform, ansible, or kubernetes folders
   git add terraform/ ansible/ kubernetes/
   git commit -m "Initial infrastructure setup"
   git push origin main
   ```

2. **Monitor workflow progress**:
   - Go to: **GitHub → Actions → Infrastructure Provisioning & Configuration**
   - Wait for: **"Install Monitoring Stack via Terraform"** step to complete
   - Duration: ~45-60 minutes

3. **Verify monitoring installation**:
   ```bash
   # Configure kubectl
   aws eks update-kubeconfig --name <cluster-name> --region ap-southeast-1
   
   # Check monitoring namespace
   kubectl get namespace monitoring
   
   # Check monitoring pods
   kubectl get pods -n monitoring
   
   # Expected output:
   # NAME                                                   READY   STATUS
   # alertmanager-kube-prometheus-stack-alertmanager-0      2/2     Running
   # kube-prometheus-stack-grafana-xxx                      3/3     Running
   # kube-prometheus-stack-operator-xxx                     1/1     Running
   # prometheus-kube-prometheus-stack-prometheus-0          2/2     Running
   ```

---

### **STEP 2: Access Prometheus**

**Purpose**: View raw metrics, query data, check targets

1. **Port forward Prometheus**:
   ```bash
   kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
   ```

2. **Access Prometheus UI**:
   - URL: http://localhost:9090
   - No authentication required

3. **Verify Prometheus is collecting metrics**:
   - Go to: **Status → Targets**
   - Check: All targets should be "UP"
   - Expected targets:
     - `kubernetes-apiservers`
     - `kubernetes-nodes`
     - `kubernetes-pods`
     - `kubernetes-service-endpoints`
     - `node-exporter`
     - `kube-state-metrics`

4. **Test queries**:
   ```promql
   # Check node CPU usage
   node_cpu_seconds_total
   
   # Check pod count
   kube_pod_info
   
   # Check container memory usage
   container_memory_usage_bytes
   
   # Check API request rate
   apiserver_request_total
   ```

---

### **STEP 3: Access Grafana** ⭐ (MOST IMPORTANT)

**Purpose**: Visualize metrics with beautiful dashboards

1. **Get Grafana admin password**:
   ```bash
   # Password is stored in GitHub secret: GRAFANA_ADMIN_PASSWORD
   # Or retrieve from Kubernetes secret:
   kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
   ```

2. **Port forward Grafana**:
   ```bash
   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
   ```

3. **Access Grafana UI**:
   - URL: http://localhost:3000
   - Username: `admin`
   - Password: (from step 1)

4. **Explore pre-installed dashboards**:
   
   Navigate to: **Dashboards → Browse**
   
   **Available Dashboards**:
   
   a) **Kubernetes / Compute Resources / Cluster**
      - Overall cluster CPU, Memory, Network usage
      - Pod count, Node count
      - Resource requests vs limits
   
   b) **Kubernetes / Compute Resources / Namespace (Pods)**
      - Per-namespace resource usage
      - Select namespace: `productx` or `productx-staging`
   
   c) **Kubernetes / Compute Resources / Pod**
      - Individual pod metrics
      - CPU, Memory, Network per container
   
   d) **Node Exporter / Nodes**
      - Node-level metrics
      - CPU, Memory, Disk, Network per node
   
   e) **Prometheus / Overview**
      - Prometheus server health
      - Scrape duration, targets, samples

5. **Create custom dashboard for ProductX**:
   
   ```
   Dashboard → New → Add visualization
   
   Panel 1: API Request Rate
   Query: rate(http_server_requests_seconds_count{namespace="productx"}[5m])
   
   Panel 2: API Response Time (p95)
   Query: histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{namespace="productx"}[5m]))
   
   Panel 3: Database Connection Pool
   Query: hikaricp_connections_active{namespace="productx"}
   
   Panel 4: Pod CPU Usage
   Query: sum(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) by (pod)
   
   Panel 5: Pod Memory Usage
   Query: sum(container_memory_usage_bytes{namespace="productx"}) by (pod)
   
   Panel 6: Product CRUD Operations
   Query: rate(http_server_requests_seconds_count{namespace="productx",uri=~"/api/products.*"}[5m])
   ```

6. **Set up alerts** (Optional):
   
   ```
   Alerting → Alert rules → New alert rule
   
   Alert 1: High CPU Usage
   Condition: avg(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) > 0.8
   
   Alert 2: High Memory Usage
   Condition: sum(container_memory_usage_bytes{namespace="productx"}) / sum(container_spec_memory_limit_bytes{namespace="productx"}) > 0.85
   
   Alert 3: Pod Restart
   Condition: increase(kube_pod_container_status_restarts_total{namespace="productx"}[15m]) > 0
   
   Alert 4: API Error Rate
   Condition: rate(http_server_requests_seconds_count{namespace="productx",status=~"5.."}[5m]) > 0.05
   ```

---

### **STEP 4: Access Alertmanager**

**Purpose**: Manage alerts, configure notification channels

1. **Port forward Alertmanager**:
   ```bash
   kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
   ```

2. **Access Alertmanager UI**:
   - URL: http://localhost:9093
   - No authentication required

3. **View active alerts**:
   - Go to: **Alerts** tab
   - Check: Current firing alerts
   - Silence alerts if needed

4. **Configure notification channels**:
   
   Edit Alertmanager config:
   ```bash
   kubectl edit secret -n monitoring alertmanager-kube-prometheus-stack-alertmanager
   ```
   
   Or update via Terraform:
   ```hcl
   # monitoring-stack/alertmanager-values.yaml.tpl
   
   alertmanager:
     config:
       global:
         smtp_smarthost: 'smtp.gmail.com:587'
         smtp_from: '${alert_email}'
         smtp_auth_username: '${alert_email}'
         smtp_auth_password: '${alert_email_password}'
       
       route:
         group_by: ['alertname', 'cluster', 'service']
         group_wait: 10s
         group_interval: 10s
         repeat_interval: 12h
         receiver: 'email'
       
       receivers:
         - name: 'email'
           email_configs:
             - to: '${alert_email}'
               send_resolved: true
   ```

---

### **STEP 5: Access Monitoring via Ingress (Optional)**

**Purpose**: Access Grafana without port-forward (public URL)

1. **Check if Grafana Ingress exists**:
   ```bash
   kubectl get ingress -n monitoring
   ```

2. **If not exists, create Grafana Ingress**:
   ```yaml
   # kubernetes/monitoring/grafana-ingress.yaml
   
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: grafana-ingress
     namespace: monitoring
     annotations:
       kubernetes.io/ingress.class: alb
       alb.ingress.kubernetes.io/scheme: internet-facing
       alb.ingress.kubernetes.io/target-type: ip
       alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
   spec:
     rules:
       - host: grafana.tranduchuy.site
         http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: kube-prometheus-stack-grafana
                   port:
                     number: 80
   ```

3. **Apply Ingress**:
   ```bash
   kubectl apply -f kubernetes/monitoring/grafana-ingress.yaml
   ```

4. **Get ALB URL**:
   ```bash
   kubectl get ingress grafana-ingress -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

5. **Configure DNS** (if using custom domain):
   ```
   # Add CNAME record in Route53 or your DNS provider
   grafana.tranduchuy.site → <ALB-URL>
   ```

6. **Access Grafana**:
   - URL: http://grafana.tranduchuy.site
   - Or: http://<ALB-URL>

---

## 📋 Quick Reference

### **When to Configure/Access**:

| Component | When | How Long After Start | Required Action |
|-----------|------|---------------------|-----------------|
| **SonarQube** | BEFORE first CI run | Day 0 (manual setup) | Configure account, add secrets, modify workflow |
| **Prometheus** | AFTER infrastructure workflow | ~45-60 minutes | Port-forward and access |
| **Grafana** | AFTER infrastructure workflow | ~45-60 minutes | Port-forward, login, explore dashboards |
| **Alertmanager** | AFTER infrastructure workflow | ~45-60 minutes | Port-forward, configure alerts |

### **Access Commands**:

```bash
# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# → http://localhost:9090

# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# → http://localhost:3000 (admin / <password>)

# Alertmanager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# → http://localhost:9093
```

### **Monitoring Health Check**:

```bash
# Check all monitoring pods
kubectl get pods -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'

# Check Grafana health
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
curl http://localhost:3000/api/health

# Check metrics collection
kubectl top nodes
kubectl top pods -n productx
```

---

## 🎯 Summary

### **Critical Timeline**:

```
┌─────────────────────────────────────────────────────────────────┐
│  COMPLETE CONFIGURATION TIMELINE                                │
└─────────────────────────────────────────────────────────────────┘

Day 0 (Before any deployment):
  ├─ ⚠️ Configure SonarQube (if needed)
  │   ├─ Set up account
  │   ├─ Add GitHub secrets
  │   └─ Modify main-ci.yml
  │
  └─ Push infrastructure code

[0-60 min] Infrastructure Workflow Running:
  ├─ [0-30 min] Terraform provisions AWS resources
  ├─ [30-40 min] Ansible configures servers
  ├─ [40-45 min] Kubernetes base setup
  │
  ├─ [45 min] ⭐ Monitoring Stack Installed
  │   ├─ Prometheus deployed
  │   ├─ Grafana deployed
  │   ├─ Alertmanager deployed
  │   └─ Metrics Server deployed
  │
  └─ [60 min] ✅ Infrastructure Ready

[60+ min] 📊 ACCESS MONITORING NOW:
  ├─ Port-forward Prometheus (9090)
  ├─ Port-forward Grafana (3000) ⭐ MOST IMPORTANT
  ├─ Port-forward Alertmanager (9093)
  ├─ Explore dashboards
  ├─ Set up custom dashboards
  └─ Configure alerts

[70+ min] Build & Deploy:
  ├─ main-ci.yml (with SonarQube scan if configured)
  ├─ deploy-staging.yml
  └─ deploy-cd.yml

[90+ min] 📊 MONITOR PRODUCTION:
  ├─ View application metrics in Grafana
  ├─ Check Prometheus targets
  ├─ Verify alerts are firing correctly
  └─ Monitor system health
```

### **Key Takeaways**:

✅ **SonarQube**: Configure BEFORE first deployment (optional, not in current setup)
✅ **Monitoring**: Automatically installed at ~45 minutes into infrastructure workflow
✅ **Grafana**: Access AFTER infrastructure workflow completes (~60 minutes)
✅ **Prometheus**: Available same time as Grafana
✅ **Alertmanager**: Available same time as Grafana

---

**Document Version**: 1.0
**Last Updated**: 2026-04-28
**Maintained By**: DevOps Team
