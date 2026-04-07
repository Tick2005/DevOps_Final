# Monitoring & Observability Guide

## Overview

The monitoring stack consists of:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Metrics Server**: Kubernetes metrics for HPA

## Architecture

```
┌─────────────┐
│ Kubernetes  │
│   Cluster   │
│             │
│  ┌───────┐  │      ┌────────────┐      ┌──────────┐
│  │ Pods  │──┼─────▶│ Prometheus │─────▶│ Grafana  │
│  └───────┘  │      │  (scrape)  │      │(visualize)│
│             │      └────────────┘      └──────────┘
│  ┌───────┐  │
│  │ Nodes │──┼──┐
│  └───────┘  │  │
└─────────────┘  │
                 │
         ┌───────▼────────┐
         │ Metrics Server │
         │   (for HPA)    │
         └────────────────┘
```

## Accessing Monitoring Tools

### Grafana

**Local Access (Port Forward)**:
```bash
kubectl port-forward -n startupx svc/grafana-service 3000:3000
```

Then open: http://localhost:3000

**Default Credentials**:
- Username: `admin`
- Password: `admin123`

**Change Password** (Recommended):
1. Login with default credentials
2. Go to Profile → Change Password
3. Update password in deployment if needed

### Prometheus

**Local Access**:
```bash
kubectl port-forward -n startupx svc/prometheus-service 9090:9090
```

Then open: http://localhost:9090

## Creating Grafana Dashboards

### Import Pre-built Dashboards

1. Login to Grafana
2. Click "+" → Import
3. Enter dashboard ID or upload JSON

**Recommended Dashboards**:
- **315**: Kubernetes cluster monitoring
- **6417**: Kubernetes Deployment metrics
- **8588**: Kubernetes Pod metrics
- **1860**: Node Exporter Full

### Create Custom Dashboard

1. Click "+" → Dashboard
2. Add Panel
3. Select Prometheus data source
4. Enter PromQL query

## Useful Prometheus Queries

### CPU Usage

**Node CPU Usage**:
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Pod CPU Usage**:
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="startupx"}[5m])) by (pod)
```

**Container CPU Usage**:
```promql
rate(container_cpu_usage_seconds_total{namespace="startupx"}[5m])
```

### Memory Usage

**Node Memory Usage**:
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Pod Memory Usage**:
```promql
sum(container_memory_usage_bytes{namespace="startupx"}) by (pod)
```

**Memory Usage Percentage**:
```promql
(container_memory_usage_bytes{namespace="startupx"} / container_spec_memory_limit_bytes{namespace="startupx"}) * 100
```

### Pod Status

**Running Pods**:
```promql
count(kube_pod_status_phase{namespace="startupx", phase="Running"})
```

**Pod Restarts**:
```promql
sum(kube_pod_container_status_restarts_total{namespace="startupx"}) by (pod)
```

**Pod Ready Status**:
```promql
kube_pod_status_ready{namespace="startupx", condition="true"}
```

### Network

**Network Receive**:
```promql
rate(container_network_receive_bytes_total{namespace="startupx"}[5m])
```

**Network Transmit**:
```promql
rate(container_network_transmit_bytes_total{namespace="startupx"}[5m])
```

### Application Metrics

**HTTP Request Rate** (if instrumented):
```promql
rate(http_requests_total{namespace="startupx"}[5m])
```

**HTTP Request Duration**:
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace="startupx"}[5m]))
```

## Sample Dashboard Configuration

### Panel 1: CPU Usage by Pod

```json
{
  "title": "CPU Usage by Pod",
  "targets": [
    {
      "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"startupx\"}[5m])) by (pod)",
      "legendFormat": "{{pod}}"
    }
  ],
  "type": "graph"
}
```

### Panel 2: Memory Usage by Pod

```json
{
  "title": "Memory Usage by Pod",
  "targets": [
    {
      "expr": "sum(container_memory_usage_bytes{namespace=\"startupx\"}) by (pod)",
      "legendFormat": "{{pod}}"
    }
  ],
  "type": "graph"
}
```

### Panel 3: Pod Status

```json
{
  "title": "Pod Status",
  "targets": [
    {
      "expr": "count(kube_pod_status_phase{namespace=\"startupx\"}) by (phase)",
      "legendFormat": "{{phase}}"
    }
  ],
  "type": "stat"
}
```

## Exporting Dashboards

### Export from Grafana UI

1. Open dashboard
2. Click Share icon → Export
3. Save JSON
4. Check "Export for sharing externally"

### Save to Repository

```bash
# Save dashboard JSON
cp ~/Downloads/dashboard.json DevOps_Final/k8s/monitoring/dashboards/

# Commit to repository
git add k8s/monitoring/dashboards/
git commit -m "docs: add Grafana dashboard"
```

## Metrics Server Verification

### Check Metrics Server Status

```bash
# Check deployment
kubectl get deployment metrics-server -n kube-system

# Check logs
kubectl logs -n kube-system -l k8s-app=metrics-server

# Test metrics
kubectl top nodes
kubectl top pods -n startupx
```

### Troubleshooting Metrics Server

If metrics not available:

```bash
# Patch for K3s
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Restart metrics server
kubectl rollout restart deployment metrics-server -n kube-system
```

## Monitoring Best Practices

### 1. Set Appropriate Scrape Intervals

Default: 15s (good for most cases)

For high-traffic apps: 10s
For low-traffic apps: 30s

### 2. Use Labels Effectively

```yaml
metadata:
  labels:
    app: backend
    tier: application
    environment: production
```

### 3. Configure Resource Limits

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### 4. Set Up Alerts (Optional)

Create `prometheus-rules.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: startupx
data:
  alert.rules: |
    groups:
    - name: example
      rules:
      - alert: HighPodCPU
        expr: sum(rate(container_cpu_usage_seconds_total{namespace="startupx"}[5m])) by (pod) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.pod }}"
```

## Demonstration Checklist

For your demo and report, ensure you can show:

- [ ] Grafana dashboard with real-time metrics
- [ ] CPU usage graphs for all pods
- [ ] Memory usage graphs for all pods
- [ ] Pod status and health
- [ ] HPA metrics and scaling behavior
- [ ] Network traffic (if available)
- [ ] Metrics during load test
- [ ] Metrics during failure simulation
- [ ] Dashboard export JSON files

## Screenshots for Report

Capture the following:

1. **Grafana Overview Dashboard**
   - All pods visible
   - CPU and memory graphs
   - Pod status indicators

2. **CPU Usage During Normal Operation**
   - Baseline metrics
   - All services running

3. **Memory Usage Trends**
   - Over time graph
   - Per-pod breakdown

4. **HPA Scaling Event**
   - Before scaling
   - During load
   - After scaling

5. **Failure Recovery**
   - Pod deletion
   - Automatic restart
   - Metrics recovery

6. **Prometheus Targets**
   - All targets UP
   - Scrape status

## Advanced: Alerting Setup

### Install Alertmanager

```bash
kubectl apply -f k8s/monitoring/alertmanager-config.yaml
kubectl apply -f k8s/monitoring/alertmanager-deployment.yaml
```

### Configure Slack Notifications

```yaml
receivers:
- name: 'slack'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts'
    title: 'Kubernetes Alert'
    text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

### Test Alert

```bash
# Generate high CPU load
kubectl run stress --image=polinux/stress --restart=Never -- stress --cpu 2 --timeout 60s -n startupx

# Watch alerts fire
kubectl port-forward -n startupx svc/alertmanager 9093:9093
# Open: http://localhost:9093
```

## Cleanup

To remove monitoring stack:

```bash
kubectl delete -f k8s/monitoring/
```

## Next Steps

- Configure custom dashboards for your application
- Set up alerting rules
- Export dashboards for report
- Prepare monitoring demonstration
