# Hướng Dẫn Setup Monitoring Stack

## Tổng Quan

Monitoring stack bao gồm:
- **Prometheus**: Thu thập metrics từ cluster và applications
- **Grafana**: Visualization và dashboards
- **Alertmanager**: Quản lý và gửi alerts
- **Node Exporter**: Thu thập metrics từ nodes
- **Kube State Metrics**: Thu thập metrics từ Kubernetes objects

---

## Bước 1: Chuẩn Bị GitHub Secrets

### 1.1. Grafana Admin Password
```bash
# Tạo password mạnh cho Grafana
# Ví dụ: GrafanaAdmin@2026
```

### 1.2. Email Alerts (Optional)

Nếu muốn nhận email alerts, cần:

**Gmail App Password:**
1. Vào: https://myaccount.google.com/apppasswords
2. Tạo App Password mới
3. Copy password (16 ký tự)

### 1.3. Thêm vào GitHub Secrets

Vào: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

```
GRAFANA_ADMIN_PASSWORD = GrafanaAdmin@2026
ALERT_EMAIL = your-email@gmail.com
ALERT_EMAIL_PASSWORD = your-app-password-16-chars
```

---

## Bước 2: Deploy Monitoring Stack

### 2.1. Automatic Deployment (Recommended)

Monitoring stack sẽ tự động được deploy khi chạy Infrastructure CD workflow:

```bash
# Push code changes
git add terraform/
git commit -m "feat: add monitoring stack"
git push origin main

# Workflow sẽ tự động:
# 1. Deploy EBS CSI Driver
# 2. Deploy Metrics Server
# 3. Deploy Prometheus + Grafana + Alertmanager
```

### 2.2. Manual Deployment (Alternative)

Nếu infrastructure đã có sẵn:

```bash
cd DevOps_Final/terraform

# Initialize Terraform
terraform init

# Plan with monitoring
terraform plan \
  -var="key_name=YOUR_KEY_NAME" \
  -var="domain_name=tranduchuy.site" \
  -var="enable_https=true" \
  -var="grafana_admin_password=GrafanaAdmin@2026" \
  -var="alert_email=your-email@gmail.com" \
  -var="alert_email_password=your-app-password"

# Apply
terraform apply -auto-approve
```

**Timeline:** 10-15 phút để deploy monitoring stack

---

## Bước 3: Verify Deployment

### 3.1. Check Monitoring Namespace
```bash
# Check namespace
kubectl get namespace monitoring

# Check pods
kubectl get pods -n monitoring

# Expected output:
# NAME                                                   READY   STATUS
# prometheus-kube-prometheus-stack-prometheus-0          2/2     Running
# kube-prometheus-stack-grafana-xxx                      3/3     Running
# kube-prometheus-stack-operator-xxx                     1/1     Running
# alertmanager-kube-prometheus-stack-alertmanager-0      2/2     Running
# kube-prometheus-stack-kube-state-metrics-xxx           1/1     Running
# prometheus-node-exporter-xxx                           1/1     Running
# prometheus-node-exporter-yyy                           1/1     Running
```

### 3.2. Check Persistent Volumes
```bash
# Check PVCs
kubectl get pvc -n monitoring

# Expected:
# NAME                                                STATUS   VOLUME      CAPACITY
# prometheus-kube-prometheus-stack-prometheus-db-0    Bound    pvc-xxx     20Gi
# alertmanager-kube-prometheus-stack-alertmanager-0   Bound    pvc-xxx     5Gi
# kube-prometheus-stack-grafana                       Bound    pvc-xxx     10Gi
```

### 3.3. Check Services
```bash
# Check services
kubectl get svc -n monitoring

# Expected:
# NAME                                      TYPE        CLUSTER-IP      PORT(S)
# kube-prometheus-stack-grafana             ClusterIP   172.20.x.x      80/TCP
# kube-prometheus-stack-prometheus          ClusterIP   172.20.x.x      9090/TCP
# kube-prometheus-stack-alertmanager        ClusterIP   172.20.x.x      9093/TCP
```

---

## Bước 4: Access Grafana

### Option 1: Port Forward (Quick Access)

```bash
# Port forward Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Open browser
# URL: http://localhost:3000
# Username: admin
# Password: <GRAFANA_ADMIN_PASSWORD>
```

### Option 2: Ingress với Subdomain (Production)

#### 4.1. Tạo CNAME Record tại Hostinger

1. Login: https://hpanel.hostinger.com/
2. Domains → Manage `tranduchuy.site` → DNS Zone Editor
3. Add Record:
   ```
   Type: CNAME
   Name: grafana
   Points to: <ALB_DNS>
   TTL: 3600
   ```

#### 4.2. Get ALB DNS
```bash
# Get ALB DNS
kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

#### 4.3. Apply Grafana Ingress
```bash
# Get certificate ARN
CERT_ARN=$(aws acm list-certificates \
  --region ap-southeast-1 \
  --query "CertificateSummaryList[?DomainName=='tranduchuy.site'].CertificateArn" \
  --output text)

# Update ingress
sed -i "s|PLACEHOLDER_CERT_ARN|${CERT_ARN}|g" kubernetes/monitoring/grafana-ingress.yaml
sed -i "s|PLACEHOLDER_DOMAIN|tranduchuy.site|g" kubernetes/monitoring/grafana-ingress.yaml

# Apply
kubectl apply -f kubernetes/monitoring/grafana-ingress.yaml

# Verify
kubectl get ingress -n monitoring
```

#### 4.4. Wait for DNS Propagation
```bash
# Wait 5-10 minutes
nslookup grafana.tranduchuy.site

# Test
curl -I https://grafana.tranduchuy.site/
```

#### 4.5. Access Grafana
```
URL: https://grafana.tranduchuy.site
Username: admin
Password: <GRAFANA_ADMIN_PASSWORD>
```

---

## Bước 5: Configure Dashboards

### 5.1. Import Pre-built Dashboards

Grafana đã có sẵn nhiều dashboards. Import thêm:

1. Login vào Grafana
2. Click `+` → `Import`
3. Nhập Dashboard ID:

**Recommended Dashboards:**
- **315**: Kubernetes cluster monitoring
- **6417**: Kubernetes Cluster (Prometheus)
- **7249**: Kubernetes Cluster
- **13770**: Kubernetes / Views / Global
- **12114**: Kubernetes / Networking / Cluster

4. Select `Prometheus` data source
5. Click `Import`

### 5.2. Create Custom Dashboard cho ProductX

1. Click `+` → `Dashboard` → `Add visualization`
2. Select `Prometheus` data source
3. Add panels:

**Panel 1: Backend Pods Status**
```promql
kube_pod_status_phase{namespace="productx", pod=~"backend.*"}
```

**Panel 2: Frontend Pods Status**
```promql
kube_pod_status_phase{namespace="productx", pod=~"frontend.*"}
```

**Panel 3: CPU Usage**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) by (pod)
```

**Panel 4: Memory Usage**
```promql
sum(container_memory_working_set_bytes{namespace="productx"}) by (pod)
```

**Panel 5: HTTP Requests Rate**
```promql
sum(rate(http_requests_total{namespace="productx"}[5m])) by (pod)
```

**Panel 6: Pod Restarts**
```promql
sum(kube_pod_container_status_restarts_total{namespace="productx"}) by (pod)
```

4. Save dashboard: `ProductX Application Monitoring`

---

## Bước 6: Configure Alerts

### 6.1. Verify Alert Rules

```bash
# Check PrometheusRules
kubectl get prometheusrules -n monitoring

# Describe rules
kubectl describe prometheusrules -n monitoring
```

### 6.2. Test Alerts

**Test 1: Kill a pod**
```bash
# Delete a pod
kubectl delete pod -n productx -l app=backend --force

# Wait 5 minutes
# Check Alertmanager: http://localhost:9093 (port-forward)
# Should receive "PodDown" alert
```

**Test 2: High CPU**
```bash
# Stress test
kubectl run stress --image=polinux/stress -n productx -- stress --cpu 2 --timeout 600s

# Wait 10 minutes
# Should receive "HighCPUUsage" alert
```

### 6.3. Check Email Alerts

Nếu đã cấu hình email:
- Check inbox cho alerts
- Check spam folder
- Verify Gmail App Password correct

---

## Bước 7: Access Prometheus & Alertmanager

### Prometheus
```bash
# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Open browser
# URL: http://localhost:9090
```

**Useful Queries:**
```promql
# All pods in productx namespace
kube_pod_info{namespace="productx"}

# CPU usage
rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])

# Memory usage
container_memory_working_set_bytes{namespace="productx"}

# Pod status
kube_pod_status_phase{namespace="productx"}
```

### Alertmanager
```bash
# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093

# Open browser
# URL: http://localhost:9093
```

---

## Bước 8: Monitoring Best Practices

### 8.1. Dashboard Organization
- Create folder: `ProductX`
- Organize dashboards by:
  - Application (Backend, Frontend)
  - Infrastructure (Cluster, Nodes)
  - Business Metrics

### 8.2. Alert Tuning
- Adjust thresholds based on actual usage
- Reduce false positives
- Set appropriate `for` duration

### 8.3. Data Retention
- Prometheus: 15 days (configurable)
- Grafana: Unlimited (dashboard configs)
- Alertmanager: 5 days (configurable)

### 8.4. Backup
```bash
# Backup Grafana dashboards
kubectl exec -n monitoring deployment/kube-prometheus-stack-grafana -- \
  grafana-cli admin export-dashboard > grafana-backup.json

# Backup Prometheus data (via snapshot)
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -- \
  promtool tsdb snapshot /prometheus
```

---

## Troubleshooting

### Issue 1: Pods not starting

**Check:**
```bash
# Describe pod
kubectl describe pod -n monitoring <POD_NAME>

# Check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Common issues:
# - PVC not bound: Check EBS CSI driver
# - Resource limits: Check node capacity
# - Image pull: Check internet connectivity
```

### Issue 2: No metrics in Grafana

**Check:**
```bash
# Verify Prometheus targets
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open: http://localhost:9090/targets

# Check ServiceMonitors
kubectl get servicemonitors -n monitoring

# Check if metrics-server is running
kubectl get pods -n kube-system | grep metrics-server
```

### Issue 3: Alerts not sending

**Check:**
```bash
# Check Alertmanager config
kubectl get secret -n monitoring alertmanager-kube-prometheus-stack-alertmanager -o yaml

# Check Alertmanager logs
kubectl logs -n monitoring alertmanager-kube-prometheus-stack-alertmanager-0

# Test email config
# Verify Gmail App Password
# Check spam folder
```

### Issue 4: Grafana Ingress not accessible

**Check:**
```bash
# Verify ingress
kubectl describe ingress grafana-ingress -n monitoring

# Check ALB
aws elbv2 describe-load-balancers --region ap-southeast-1

# Check DNS
nslookup grafana.tranduchuy.site

# Check certificate
aws acm describe-certificate --certificate-arn <CERT_ARN>
```

---

## Monitoring Stack Resources

### Resource Usage
```
Prometheus: 500m CPU, 1Gi Memory (requests)
Grafana: 100m CPU, 256Mi Memory (requests)
Alertmanager: 100m CPU, 128Mi Memory (requests)
Node Exporter: 50m CPU, 64Mi Memory (per node)
Kube State Metrics: 100m CPU, 128Mi Memory
```

### Storage Usage
```
Prometheus: 20Gi (15 days retention)
Grafana: 10Gi (dashboards + configs)
Alertmanager: 5Gi (alert history)
Total: ~35Gi
```

### Cost Estimate
```
EBS gp3 volumes: ~$3.5/month (35Gi × $0.10/GB)
Additional node resources: Included in existing nodes
Total: ~$3.5/month
```

---

## Quick Reference

### Access URLs
```bash
# Grafana (port-forward)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000

# Grafana (ingress)
# https://grafana.tranduchuy.site

# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# http://localhost:9090

# Alertmanager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# http://localhost:9093
```

### Useful Commands
```bash
# Check all monitoring resources
kubectl get all -n monitoring

# Check PVCs
kubectl get pvc -n monitoring

# Check logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0
kubectl logs -n monitoring alertmanager-kube-prometheus-stack-alertmanager-0

# Restart Grafana
kubectl rollout restart deployment/kube-prometheus-stack-grafana -n monitoring

# Delete and recreate monitoring stack
helm uninstall kube-prometheus-stack -n monitoring
terraform apply -auto-approve
```

---

## Next Steps

1. ✅ Deploy monitoring stack
2. ✅ Access Grafana
3. ✅ Import dashboards
4. ✅ Create custom ProductX dashboard
5. ✅ Configure alerts
6. ✅ Test alerts
7. ✅ Setup Grafana ingress (optional)
8. ✅ Document dashboards
9. ✅ Train team on monitoring
10. ✅ Setup regular reviews

---

## Support

- Prometheus Docs: https://prometheus.io/docs/
- Grafana Docs: https://grafana.com/docs/
- kube-prometheus-stack: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- Dashboard Library: https://grafana.com/grafana/dashboards/
