# Quick Deploy Monitoring Stack

## Option 1: Via GitHub Actions (Recommended)

### Step 1: Add GitHub Secrets

Vào: `Settings` → `Secrets and variables` → `Actions`

Add 3 secrets mới:
```
GRAFANA_ADMIN_PASSWORD = GrafanaAdmin@2026
ALERT_EMAIL = your-email@gmail.com (optional)
ALERT_EMAIL_PASSWORD = your-gmail-app-password (optional)
```

### Step 2: Update Workflow

Workflow đã được update để support monitoring variables. Chỉ cần push code:

```bash
cd DevOps_Final

# Add monitoring files
git add terraform/metrics-server.tf
git add terraform/ebs-csi-driver.tf
git add terraform/prometheus-grafana.tf
git add terraform/alertmanager-values.yaml.tpl
git add terraform/variables.tf
git add kubernetes/monitoring/
git add MONITORING_SETUP.md

# Commit
git commit -m "feat: add monitoring stack (Prometheus + Grafana + Alertmanager)"

# Push
git push origin main
```

### Step 3: Trigger Workflow

1. Vào GitHub Actions
2. Chọn "Infrastructure Provisioning & Configuration"
3. Click "Run workflow"
4. Select action: `apply`
5. Run

**Timeline:** 15-20 phút

---

## Option 2: Manual Terraform Apply

Nếu muốn deploy manually:

```bash
cd DevOps_Final/terraform

# Initialize
terraform init

# Plan với monitoring variables
terraform plan \
  -var="key_name=$AWS_KEY_NAME" \
  -var="domain_name=tranduchuy.site" \
  -var="enable_https=true" \
  -var="grafana_admin_password=GrafanaAdmin@2026" \
  -var="alert_email=your-email@gmail.com" \
  -var="alert_email_password=your-app-password"

# Apply
terraform apply -auto-approve \
  -var="key_name=$AWS_KEY_NAME" \
  -var="domain_name=tranduchuy.site" \
  -var="enable_https=true" \
  -var="grafana_admin_password=GrafanaAdmin@2026" \
  -var="alert_email=your-email@gmail.com" \
  -var="alert_email_password=your-app-password"
```

---

## Option 3: Helm Install Only (Fastest)

Nếu infrastructure đã có và chỉ muốn install monitoring:

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=15d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=gp3 \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=20Gi \
  --set grafana.enabled=true \
  --set grafana.adminPassword=GrafanaAdmin@2026 \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=gp3 \
  --set grafana.persistence.size=10Gi \
  --set alertmanager.enabled=true \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName=gp3 \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=5Gi

# Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

# Port forward Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: GrafanaAdmin@2026
```

**Timeline:** 5-10 phút

---

## Verify Deployment

```bash
# Check pods
kubectl get pods -n monitoring

# Expected: All pods Running
# - prometheus-kube-prometheus-stack-prometheus-0
# - kube-prometheus-stack-grafana-xxx
# - alertmanager-kube-prometheus-stack-alertmanager-0
# - kube-prometheus-stack-operator-xxx
# - kube-prometheus-stack-kube-state-metrics-xxx
# - prometheus-node-exporter-xxx (per node)

# Check PVCs
kubectl get pvc -n monitoring

# Expected: All Bound
# - prometheus-kube-prometheus-stack-prometheus-db-0 (20Gi)
# - kube-prometheus-stack-grafana (10Gi)
# - alertmanager-kube-prometheus-stack-alertmanager-0 (5Gi)

# Access Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Open: http://localhost:3000
# Login: admin / GrafanaAdmin@2026
```

---

## Quick Access

### Grafana
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000
```

### Prometheus
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# http://localhost:9090
```

### Alertmanager
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# http://localhost:9093
```

---

## Import Dashboards

1. Login to Grafana
2. Click `+` → `Import`
3. Enter Dashboard ID:
   - **315**: Kubernetes cluster monitoring
   - **6417**: Kubernetes Cluster (Prometheus)
   - **13770**: Kubernetes / Views / Global
4. Select `Prometheus` data source
5. Click `Import`

---

## Next Steps

1. ✅ Deploy monitoring stack
2. ✅ Access Grafana
3. ✅ Import dashboards
4. ✅ Create ProductX dashboard
5. ✅ Configure alerts
6. ✅ Setup Grafana ingress (optional)

See `MONITORING_SETUP.md` for detailed guide.

---

## Troubleshooting

### Pods not starting
```bash
# Check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod -n monitoring <POD_NAME>

# Common issues:
# - PVC not bound: Install EBS CSI driver first
# - Resource limits: Check node capacity
```

### No metrics
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open: http://localhost:9090/targets

# Should see targets: kubelet, kube-state-metrics, node-exporter
```

### Can't login to Grafana
```bash
# Reset password
kubectl exec -n monitoring deployment/kube-prometheus-stack-grafana -- \
  grafana-cli admin reset-admin-password GrafanaAdmin@2026
```

---

## Uninstall (if needed)

```bash
# Helm uninstall
helm uninstall kube-prometheus-stack -n monitoring

# Delete PVCs
kubectl delete pvc -n monitoring --all

# Delete namespace
kubectl delete namespace monitoring
```
