# 📊 Monitoring & Code Quality Access Guide

## 🌐 Public Access URLs

After infrastructure deployment completes, you can access all monitoring and code quality tools via these URLs:

### **Production Application**
```
🌍 Main Application: https://www.tranduchuy.site
```

### **Monitoring & Observability**
```
📊 Grafana (Monitoring): https://monitoring.tranduchuy.site
   Username: admin
   Password: (from GitHub secret: GRAFANA_ADMIN_PASSWORD)
   
   Features:
   - Pre-configured dashboards
   - Real-time metrics visualization
   - Custom dashboard creation
   - Alert management
```

### **Code Quality**
```
🔍 SonarQube (Code Analysis): http://sonarqube.tranduchuy.site
   Default Login: admin / admin (change on first login)
   
   Projects:
   - productx-backend: Java/Spring Boot analysis
   - productx-frontend: JavaScript/React analysis
```

---

## ⏱️ Availability Timeline

```
┌─────────────────────────────────────────────────────────────┐
│  WHEN SERVICES BECOME AVAILABLE                             │
└─────────────────────────────────────────────────────────────┘

infrastructure-cd.yml workflow starts
  ↓
[0-45 min] Infrastructure provisioning
  ├─ Terraform creates AWS resources
  ├─ Ansible configures servers
  └─ Kubernetes base setup
  ↓
[45 min] 📊 Monitoring Stack Deployed
  ├─ Prometheus
  ├─ Grafana → https://monitoring.tranduchuy.site ✅
  ├─ Alertmanager
  └─ SonarQube → http://sonarqube.tranduchuy.site ✅
  ↓
[50-60 min] Pods starting and becoming ready
  ↓
[60 min] ✅ ALL MONITORING SERVICES READY!
  ↓
[70+ min] Application deployment
  ├─ main-ci.yml (with SonarQube scan)
  ├─ deploy-staging.yml
  └─ deploy-cd.yml
  ↓
[90 min] ✅ Application Live → https://www.tranduchuy.site
```

---

## 🚀 First-Time Setup

### **1. Access Grafana**

```bash
# URL: https://monitoring.tranduchuy.site

# Login:
Username: admin
Password: <from GitHub secret GRAFANA_ADMIN_PASSWORD>

# First Steps:
1. Explore pre-configured dashboards
2. Check Prometheus data source (should be auto-configured)
3. Create custom dashboard for ProductX
4. Set up alerts
```

**Pre-configured Dashboards**:
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Pod
- Node Exporter / Nodes
- Prometheus / Overview

### **2. Access SonarQube**

```bash
# URL: http://sonarqube.tranduchuy.site

# First Login:
Username: admin
Password: admin

# IMPORTANT: Change password immediately!

# Then:
1. Go to: User → My Account → Security
2. Generate Token: "GitHub Actions CI/CD"
3. Copy token
4. Add to GitHub Secrets:
   Name: SONAR_TOKEN
   Value: <your-token>

5. Add SonarQube URL to GitHub Secrets:
   Name: SONAR_HOST_URL
   Value: http://sonarqube.tranduchuy.site
```

---

## 📊 Grafana Dashboard Setup

### **Create Custom ProductX Dashboard**

1. **Navigate to**: Dashboards → New → New Dashboard

2. **Add Panels**:

   **Panel 1: API Request Rate**
   ```promql
   rate(http_server_requests_seconds_count{namespace="productx"}[5m])
   ```

   **Panel 2: API Response Time (p95)**
   ```promql
   histogram_quantile(0.95, 
     rate(http_server_requests_seconds_bucket{namespace="productx"}[5m])
   )
   ```

   **Panel 3: Pod CPU Usage**
   ```promql
   sum(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) by (pod)
   ```

   **Panel 4: Pod Memory Usage**
   ```promql
   sum(container_memory_usage_bytes{namespace="productx"}) by (pod)
   ```

   **Panel 5: Database Connections**
   ```promql
   hikaricp_connections_active{namespace="productx"}
   ```

   **Panel 6: HTTP Status Codes**
   ```promql
   sum(rate(http_server_requests_seconds_count{namespace="productx"}[5m])) by (status)
   ```

3. **Save Dashboard**: Name it "ProductX Application Metrics"

### **Set Up Alerts**

1. **Navigate to**: Alerting → Alert rules → New alert rule

2. **Create Alerts**:

   **Alert 1: High CPU Usage**
   ```
   Name: High CPU Usage
   Query: avg(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) > 0.8
   Condition: Above 80% for 5 minutes
   ```

   **Alert 2: High Memory Usage**
   ```
   Name: High Memory Usage
   Query: sum(container_memory_usage_bytes{namespace="productx"}) / 
          sum(container_spec_memory_limit_bytes{namespace="productx"}) > 0.85
   Condition: Above 85% for 5 minutes
   ```

   **Alert 3: Pod Restarts**
   ```
   Name: Pod Restarting
   Query: increase(kube_pod_container_status_restarts_total{namespace="productx"}[15m]) > 0
   Condition: Any restart in last 15 minutes
   ```

   **Alert 4: API Error Rate**
   ```
   Name: High API Error Rate
   Query: rate(http_server_requests_seconds_count{namespace="productx",status=~"5.."}[5m]) > 0.05
   Condition: More than 5% errors for 5 minutes
   ```

---

## 🔍 SonarQube Project Setup

### **Projects Auto-Created by CI**

The CI pipeline automatically creates and analyzes:
- `productx-backend` - Java/Spring Boot
- `productx-frontend` - JavaScript/React

### **View Analysis Results**

1. **Go to**: http://sonarqube.tranduchuy.site

2. **Navigate to**: Projects

3. **Select Project**: productx-backend or productx-frontend

4. **Review**:
   - **Bugs**: Logic errors that will cause incorrect behavior
   - **Vulnerabilities**: Security issues
   - **Code Smells**: Maintainability issues
   - **Coverage**: Test coverage percentage
   - **Duplications**: Duplicated code blocks
   - **Security Hotspots**: Security-sensitive code to review

### **Quality Gate**

Default quality gate checks:
- ✅ No new bugs
- ✅ No new vulnerabilities
- ✅ Coverage on new code ≥ 80%
- ✅ Duplicated lines ≤ 3%
- ✅ Maintainability rating ≥ A
- ✅ Security rating ≥ A

---

## 🔧 Alternative Access (Port Forward)

If you prefer local access or domains are not working:

### **Grafana**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Access: http://localhost:3000
```

### **Prometheus**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Access: http://localhost:9090
```

### **Alertmanager**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Access: http://localhost:9093
```

### **SonarQube**
```bash
kubectl port-forward -n sonarqube svc/sonarqube 9000:9000
# Access: http://localhost:9000
```

---

## 🔐 Required GitHub Secrets

Make sure these secrets are configured in your GitHub repository:

```
# Application
DOCKER_USERNAME:           <your-dockerhub-username>
DOCKER_PASSWORD:           <your-dockerhub-password>
DB_PASSWORD:               <database-password>

# AWS
AWS_ACCESS_KEY_ID:         <aws-access-key>
AWS_SECRET_ACCESS_KEY:     <aws-secret-key>
AWS_KEY_NAME:              <ec2-key-pair-name>
EC2_SSH_PRIVATE_KEY:       <ec2-private-key-content>

# Infrastructure
EKS_CLUSTER_NAME:          <eks-cluster-name>
TF_BACKEND_BUCKET:         <terraform-state-bucket>
DOMAIN_NAME:               tranduchuy.site

# Monitoring
GRAFANA_ADMIN_PASSWORD:    <strong-password>
ALERT_EMAIL:               <your-email>
ALERT_EMAIL_PASSWORD:      <email-app-password>

# SonarQube
SONAR_TOKEN:               <generated-after-first-login>
SONAR_HOST_URL:            http://sonarqube.tranduchuy.site
SONARQUBE_DB_PASSWORD:     <sonarqube-db-password>
```

---

## 📋 Health Check Commands

### **Check All Services**

```bash
# Monitoring namespace
kubectl get pods -n monitoring

# SonarQube namespace
kubectl get pods -n sonarqube

# Application namespace
kubectl get pods -n productx

# Check ingresses
kubectl get ingress -A
```

### **Check Service Health**

```bash
# Grafana
curl -I https://monitoring.tranduchuy.site/api/health

# SonarQube
curl -I http://sonarqube.tranduchuy.site/api/system/status

# Application
curl -I https://www.tranduchuy.site
```

### **Check Metrics Collection**

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods -n productx
kubectl top pods -n monitoring
kubectl top pods -n sonarqube
```

---

## 🎯 Quick Reference

| Service | URL | Default Credentials | Purpose |
|---------|-----|---------------------|---------|
| **Application** | https://www.tranduchuy.site | N/A | ProductX main application |
| **Grafana** | https://monitoring.tranduchuy.site | admin / (secret) | Metrics visualization & dashboards |
| **SonarQube** | http://sonarqube.tranduchuy.site | admin / admin | Code quality & security analysis |
| **Prometheus** | Port-forward 9090 | N/A | Metrics collection & queries |
| **Alertmanager** | Port-forward 9093 | N/A | Alert management |

---

## 🆘 Troubleshooting

### **Cannot Access Grafana**

1. **Check Ingress**:
   ```bash
   kubectl get ingress -n monitoring
   kubectl describe ingress grafana-ingress -n monitoring
   ```

2. **Check ALB**:
   ```bash
   kubectl get ingress grafana-ingress -n monitoring \
     -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

3. **Check DNS**:
   ```bash
   nslookup monitoring.tranduchuy.site
   ```

4. **Check Pod**:
   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
   ```

### **Cannot Access SonarQube**

1. **Check Pod Status**:
   ```bash
   kubectl get pods -n sonarqube
   kubectl logs -n sonarqube -l app=sonarqube --tail=100
   ```

2. **Check Ingress**:
   ```bash
   kubectl get ingress -n sonarqube
   kubectl describe ingress sonarqube-ingress -n sonarqube
   ```

3. **Check Database**:
   ```bash
   kubectl logs -n sonarqube -l app=sonarqube-postgresql
   ```

### **SonarQube Scan Fails in CI**

1. **Verify Token**:
   ```bash
   curl -u "<SONAR_TOKEN>:" \
     http://sonarqube.tranduchuy.site/api/authentication/validate
   ```

2. **Check SonarQube is Running**:
   ```bash
   curl http://sonarqube.tranduchuy.site/api/system/status
   ```

3. **Verify GitHub Secrets**:
   - SONAR_TOKEN is set
   - SONAR_HOST_URL is correct (http://, not https://)

---

## 📚 Additional Documentation

- [SONARQUBE_SETUP.md](./SONARQUBE_SETUP.md) - Detailed SonarQube configuration
- [SONARQUBE_AND_MONITORING_GUIDE.md](./SONARQUBE_AND_MONITORING_GUIDE.md) - Complete guide
- [WORKFLOWS_OVERVIEW.md](./WORKFLOWS_OVERVIEW.md) - CI/CD pipeline documentation

---

**Document Version**: 1.0
**Last Updated**: 2026-04-28
**Maintained By**: DevOps Team
