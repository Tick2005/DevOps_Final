# Monitoring & Observability Guide

## Overview

This guide covers monitoring, logging, and observability for the ProductX application using Prometheus, Grafana, and Kubernetes native tools.

---

## Table of Contents

1. [Monitoring Stack Overview](#monitoring-stack-overview)
2. [Accessing Monitoring Tools](#accessing-monitoring-tools)
3. [Prometheus Queries](#prometheus-queries)
4. [Grafana Dashboards](#grafana-dashboards)
5. [Application Logs](#application-logs)
6. [Alerts Configuration](#alerts-configuration)
7. [Performance Metrics](#performance-metrics)
8. [Troubleshooting](#troubleshooting)

---

## Monitoring Stack Overview

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Stack                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │  Prometheus  │───▶│   Grafana    │◀───│ Alertmanager │ │
│  │  (Metrics)   │    │ (Dashboards) │    │  (Alerts)    │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│         ▲                                                   │
│         │                                                   │
│  ┌──────┴───────────────────────────────────────────────┐ │
│  │              Metrics Sources                          │ │
│  ├───────────────────────────────────────────────────────┤ │
│  │ • Kubernetes Metrics (nodes, pods, containers)        │ │
│  │ • Application Metrics (Spring Boot Actuator)          │ │
│  │ • System Metrics (CPU, memory, disk, network)         │ │
│  │ • Custom Business Metrics                             │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Installed Components

| Component | Purpose | Namespace | Port |
|-----------|---------|-----------|------|
| Prometheus | Metrics collection & storage | monitoring | 9090 |
| Grafana | Visualization & dashboards | monitoring | 3000 |
| Alertmanager | Alert routing & notification | monitoring | 9093 |
| Metrics Server | Kubernetes resource metrics | kube-system | - |
| Node Exporter | Node-level metrics | monitoring | 9100 |

---

## Accessing Monitoring Tools

### 1. Grafana Dashboard

#### Via Ingress (Production)
```bash
# Get Grafana URL
kubectl get ingress -n monitoring

# Access in browser
https://grafana.tranduchuy.site
```

**Default Credentials:**
- Username: `admin`
- Password: Check secret or use default `prom-operator`

```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
echo
```

#### Via Port Forward (Development)
```bash
# Forward Grafana port
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access in browser
http://localhost:3000
```

### 2. Prometheus UI

```bash
# Forward Prometheus port
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access in browser
http://localhost:9090
```

### 3. Alertmanager UI

```bash
# Forward Alertmanager port
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Access in browser
http://localhost:9093
```

---

## Prometheus Queries

### Kubernetes Metrics

#### Pod Metrics
```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) by (pod)

# Memory usage by pod
sum(container_memory_working_set_bytes{namespace="productx"}) by (pod)

# Pod restart count
kube_pod_container_status_restarts_total{namespace="productx"}

# Pod status
kube_pod_status_phase{namespace="productx"}
```

#### Node Metrics
```promql
# Node CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Node disk usage
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# Node network traffic
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

### Application Metrics

#### Backend (Spring Boot)
```promql
# HTTP request rate
rate(http_server_requests_seconds_count{namespace="productx"}[5m])

# HTTP request duration (95th percentile)
histogram_quantile(0.95, 
  rate(http_server_requests_seconds_bucket{namespace="productx"}[5m])
)

# HTTP error rate
rate(http_server_requests_seconds_count{namespace="productx",status=~"5.."}[5m])

# JVM memory usage
jvm_memory_used_bytes{namespace="productx"}

# JVM garbage collection time
rate(jvm_gc_pause_seconds_sum{namespace="productx"}[5m])

# Database connection pool
hikaricp_connections_active{namespace="productx"}
hikaricp_connections_idle{namespace="productx"}
```

#### Frontend (Nginx)
```promql
# Nginx requests per second
rate(nginx_http_requests_total{namespace="productx"}[5m])

# Nginx response time
nginx_http_request_duration_seconds{namespace="productx"}

# Nginx active connections
nginx_connections_active{namespace="productx"}
```

### Business Metrics

```promql
# Total products in database
product_count_total

# Products created per minute
rate(product_created_total[1m])

# Products deleted per minute
rate(product_deleted_total[1m])

# Average product price
avg(product_price)
```

---

## Grafana Dashboards

### Pre-installed Dashboards

1. **Kubernetes Cluster Monitoring**
   - Dashboard ID: 7249
   - Shows: Cluster overview, node status, resource usage

2. **Kubernetes Pod Monitoring**
   - Dashboard ID: 6417
   - Shows: Pod metrics, container stats, resource limits

3. **Spring Boot Statistics**
   - Dashboard ID: 12900
   - Shows: JVM metrics, HTTP requests, database connections

4. **Node Exporter Full**
   - Dashboard ID: 1860
   - Shows: System metrics, CPU, memory, disk, network

### Creating Custom Dashboard

#### 1. Access Grafana
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

#### 2. Create New Dashboard
1. Click **+ → Dashboard**
2. Click **Add new panel**
3. Enter PromQL query
4. Configure visualization
5. Save dashboard

#### 3. Example Panel: Backend Request Rate

**Query:**
```promql
sum(rate(http_server_requests_seconds_count{
  namespace="productx",
  app="backend"
}[5m])) by (uri)
```

**Visualization:** Time series graph

**Panel Title:** Backend API Request Rate

### Recommended Dashboards

#### Application Overview Dashboard

**Panels:**

1. **Total Requests (Last 5m)**
   ```promql
   sum(increase(http_server_requests_seconds_count{namespace="productx"}[5m]))
   ```

2. **Error Rate**
   ```promql
   sum(rate(http_server_requests_seconds_count{
     namespace="productx",
     status=~"5.."
   }[5m])) / sum(rate(http_server_requests_seconds_count{
     namespace="productx"
   }[5m])) * 100
   ```

3. **Average Response Time**
   ```promql
   histogram_quantile(0.95,
     sum(rate(http_server_requests_seconds_bucket{
       namespace="productx"
     }[5m])) by (le)
   )
   ```

4. **Active Pods**
   ```promql
   count(kube_pod_status_phase{
     namespace="productx",
     phase="Running"
   })
   ```

5. **CPU Usage**
   ```promql
   sum(rate(container_cpu_usage_seconds_total{
     namespace="productx"
   }[5m])) by (pod)
   ```

6. **Memory Usage**
   ```promql
   sum(container_memory_working_set_bytes{
     namespace="productx"
   }) by (pod)
   ```

#### Database Dashboard

**Panels:**

1. **Active Connections**
   ```promql
   hikaricp_connections_active{namespace="productx"}
   ```

2. **Connection Pool Usage**
   ```promql
   hikaricp_connections_active{namespace="productx"} / 
   hikaricp_connections_max{namespace="productx"} * 100
   ```

3. **Query Execution Time**
   ```promql
   rate(hikaricp_connections_acquire_seconds_sum{namespace="productx"}[5m]) /
   rate(hikaricp_connections_acquire_seconds_count{namespace="productx"}[5m])
   ```

---

## Application Logs

### Viewing Logs

#### 1. Kubernetes Logs

```bash
# View backend logs
kubectl logs -l app=backend -n productx --tail=100

# View frontend logs
kubectl logs -l app=frontend -n productx --tail=100

# Follow logs in real-time
kubectl logs -l app=backend -n productx -f

# View logs from all pods
kubectl logs -l app=backend -n productx --all-containers=true

# View logs from previous pod (if crashed)
kubectl logs <pod-name> -n productx --previous

# View logs with timestamps
kubectl logs -l app=backend -n productx --timestamps=true

# View logs from last hour
kubectl logs -l app=backend -n productx --since=1h
```

#### 2. Filter Logs

```bash
# Filter ERROR logs
kubectl logs -l app=backend -n productx | grep ERROR

# Filter specific endpoint
kubectl logs -l app=backend -n productx | grep "/api/products"

# Filter by timestamp
kubectl logs -l app=backend -n productx --since-time='2024-01-01T10:00:00Z'

# Count errors
kubectl logs -l app=backend -n productx | grep -c ERROR
```

#### 3. Export Logs

```bash
# Export to file
kubectl logs -l app=backend -n productx > backend-logs.txt

# Export with timestamp
kubectl logs -l app=backend -n productx --timestamps=true > backend-logs-$(date +%Y%m%d).txt

# Export from all pods
for pod in $(kubectl get pods -n productx -l app=backend -o name); do
  kubectl logs $pod -n productx > ${pod##*/}-logs.txt
done
```

### Log Aggregation (Optional)

#### Using Stern (Multi-pod log tailing)

```bash
# Install stern
brew install stern  # macOS
# or
wget https://github.com/stern/stern/releases/download/v1.25.0/stern_1.25.0_linux_amd64.tar.gz
tar -xzf stern_1.25.0_linux_amd64.tar.gz
sudo mv stern /usr/local/bin/

# Tail logs from all backend pods
stern backend -n productx

# Tail with color coding
stern backend -n productx --color always

# Filter by regex
stern backend -n productx -e "ERROR|WARN"

# Tail multiple apps
stern "backend|frontend" -n productx
```

### Log Levels

#### Backend (Spring Boot)

Configure in `application.yml`:
```yaml
logging:
  level:
    root: INFO
    com.startupx: DEBUG
    org.springframework.web: DEBUG
    org.hibernate.SQL: DEBUG
```

Update via ConfigMap:
```bash
kubectl edit configmap app-config -n productx
```

#### Frontend (Nginx)

Configure in `nginx.conf`:
```nginx
error_log /var/log/nginx/error.log warn;
access_log /var/log/nginx/access.log combined;
```

---

## Alerts Configuration

### Prometheus Alert Rules

#### Create Alert Rules

```yaml
# alert-rules.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alert-rules
  namespace: monitoring
data:
  alert-rules.yml: |
    groups:
      - name: productx-alerts
        interval: 30s
        rules:
          # High error rate
          - alert: HighErrorRate
            expr: |
              sum(rate(http_server_requests_seconds_count{
                namespace="productx",
                status=~"5.."
              }[5m])) / sum(rate(http_server_requests_seconds_count{
                namespace="productx"
              }[5m])) > 0.05
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "High error rate detected"
              description: "Error rate is {{ $value | humanizePercentage }}"
          
          # Pod not ready
          - alert: PodNotReady
            expr: |
              kube_pod_status_phase{
                namespace="productx",
                phase!="Running"
              } > 0
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Pod {{ $labels.pod }} is not ready"
              description: "Pod has been in {{ $labels.phase }} state for 5 minutes"
          
          # High CPU usage
          - alert: HighCPUUsage
            expr: |
              sum(rate(container_cpu_usage_seconds_total{
                namespace="productx"
              }[5m])) by (pod) > 0.8
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High CPU usage on {{ $labels.pod }}"
              description: "CPU usage is {{ $value | humanize }}"
          
          # High memory usage
          - alert: HighMemoryUsage
            expr: |
              sum(container_memory_working_set_bytes{
                namespace="productx"
              }) by (pod) / sum(container_spec_memory_limit_bytes{
                namespace="productx"
              }) by (pod) > 0.9
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High memory usage on {{ $labels.pod }}"
              description: "Memory usage is {{ $value | humanizePercentage }}"
          
          # Database connection pool exhausted
          - alert: DatabaseConnectionPoolExhausted
            expr: |
              hikaricp_connections_active{namespace="productx"} / 
              hikaricp_connections_max{namespace="productx"} > 0.9
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Database connection pool nearly exhausted"
              description: "Connection pool usage is {{ $value | humanizePercentage }}"
          
          # Pod restart loop
          - alert: PodRestartLoop
            expr: |
              rate(kube_pod_container_status_restarts_total{
                namespace="productx"
              }[15m]) > 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Pod {{ $labels.pod }} is restarting frequently"
              description: "Pod has restarted {{ $value }} times in the last 15 minutes"
```

Apply:
```bash
kubectl apply -f alert-rules.yaml
```

### Alertmanager Configuration

#### Configure Notifications

```yaml
# alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-kube-prometheus-alertmanager
  namespace: monitoring
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'default'
      routes:
        - match:
            severity: critical
          receiver: 'critical'
        - match:
            severity: warning
          receiver: 'warning'
    
    receivers:
      - name: 'default'
        webhook_configs:
          - url: 'http://webhook-receiver:8080/alerts'
      
      - name: 'critical'
        email_configs:
          - to: 'ops-team@example.com'
            from: 'alertmanager@example.com'
            smarthost: 'smtp.gmail.com:587'
            auth_username: 'alertmanager@example.com'
            auth_password: 'your-app-password'
            headers:
              Subject: '[CRITICAL] {{ .GroupLabels.alertname }}'
        slack_configs:
          - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
            channel: '#alerts-critical'
            title: '{{ .GroupLabels.alertname }}'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
      
      - name: 'warning'
        slack_configs:
          - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
            channel: '#alerts-warning'
            title: '{{ .GroupLabels.alertname }}'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

Apply:
```bash
kubectl apply -f alertmanager-config.yaml
```

### Testing Alerts

```bash
# Trigger high CPU alert (stress test)
kubectl run stress-test -n productx --image=polinux/stress --rm -it -- stress --cpu 4 --timeout 600s

# Trigger pod not ready alert (scale to 0)
kubectl scale deployment backend -n productx --replicas=0

# Check active alerts
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Visit: http://localhost:9093/#/alerts

# Check Prometheus alerts
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/alerts
```

---

## Performance Metrics

### Key Performance Indicators (KPIs)

#### 1. Application Performance

| Metric | Target | Query |
|--------|--------|-------|
| Response Time (p95) | < 500ms | `histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))` |
| Error Rate | < 1% | `sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count[5m]))` |
| Throughput | > 100 req/s | `sum(rate(http_server_requests_seconds_count[5m]))` |
| Availability | > 99.9% | `avg_over_time(up{namespace="productx"}[24h])` |

#### 2. Infrastructure Performance

| Metric | Target | Query |
|--------|--------|-------|
| CPU Usage | < 70% | `sum(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m]))` |
| Memory Usage | < 80% | `sum(container_memory_working_set_bytes{namespace="productx"}) / sum(container_spec_memory_limit_bytes{namespace="productx"})` |
| Disk Usage | < 80% | `(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100` |
| Network Latency | < 50ms | `rate(node_network_receive_bytes_total[5m])` |

#### 3. Database Performance

| Metric | Target | Query |
|--------|--------|-------|
| Connection Pool Usage | < 80% | `hikaricp_connections_active / hikaricp_connections_max` |
| Query Time (p95) | < 100ms | `histogram_quantile(0.95, rate(hikaricp_connections_acquire_seconds_bucket[5m]))` |
| Active Connections | < 20 | `hikaricp_connections_active` |

### Generating Performance Reports

```bash
# Export metrics to CSV
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Query Prometheus API
curl 'http://localhost:9090/api/v1/query?query=sum(rate(http_server_requests_seconds_count[5m]))' | jq

# Export to CSV
curl 'http://localhost:9090/api/v1/query_range?query=sum(rate(http_server_requests_seconds_count[5m]))&start=2024-01-01T00:00:00Z&end=2024-01-02T00:00:00Z&step=1m' \
  | jq -r '.data.result[0].values[] | @csv' > metrics.csv
```

---

## Troubleshooting

### Common Issues

#### 1. Metrics Not Showing

**Problem:** No data in Grafana dashboards

**Solution:**
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/targets

# Check if metrics server is running
kubectl get deployment metrics-server -n kube-system

# Check if pods have metrics annotations
kubectl get pods -n productx -o yaml | grep -A 5 "annotations"
```

#### 2. High Memory Usage

**Problem:** Prometheus using too much memory

**Solution:**
```bash
# Reduce retention period
kubectl edit prometheus -n monitoring

# Add/modify:
spec:
  retention: 7d  # Reduce from 15d to 7d
  
# Reduce scrape interval
kubectl edit configmap prometheus-kube-prometheus-prometheus -n monitoring

# Modify:
scrape_interval: 30s  # Increase from 15s to 30s
```

#### 3. Alerts Not Firing

**Problem:** Alerts configured but not triggering

**Solution:**
```bash
# Check alert rules
kubectl get prometheusrules -n monitoring

# Check Alertmanager logs
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager

# Test alert rule
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/alerts
# Check if alert is in "Pending" or "Firing" state
```

#### 4. Grafana Dashboard Not Loading

**Problem:** Dashboard shows "No data"

**Solution:**
```bash
# Check Grafana data source
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Visit: http://localhost:3000/datasources
# Test connection to Prometheus

# Check Prometheus is accessible
kubectl get svc -n monitoring | grep prometheus

# Verify query syntax in dashboard panel
```

---

## Best Practices

### 1. Monitoring Strategy

- **Monitor the Four Golden Signals:**
  - Latency: How long requests take
  - Traffic: How many requests
  - Errors: Rate of failed requests
  - Saturation: How full your service is

- **Set Meaningful Alerts:**
  - Alert on symptoms, not causes
  - Make alerts actionable
  - Avoid alert fatigue

- **Use Dashboards Effectively:**
  - Create role-specific dashboards
  - Use consistent naming conventions
  - Document dashboard purpose

### 2. Log Management

- **Structured Logging:**
  - Use JSON format for logs
  - Include correlation IDs
  - Add contextual information

- **Log Levels:**
  - ERROR: Requires immediate attention
  - WARN: Potential issues
  - INFO: Important events
  - DEBUG: Detailed information (dev only)

- **Log Retention:**
  - Keep logs for 30 days minimum
  - Archive important logs
  - Implement log rotation

### 3. Performance Optimization

- **Optimize Queries:**
  - Use recording rules for complex queries
  - Limit time ranges
  - Use appropriate aggregations

- **Resource Management:**
  - Set appropriate retention periods
  - Configure scrape intervals wisely
  - Use remote storage for long-term data

---

## Additional Resources

### Useful Commands

```bash
# Check monitoring stack status
kubectl get all -n monitoring

# Restart Prometheus
kubectl rollout restart statefulset prometheus-kube-prometheus-prometheus -n monitoring

# Restart Grafana
kubectl rollout restart deployment prometheus-grafana -n monitoring

# Check Prometheus configuration
kubectl get secret prometheus-kube-prometheus-prometheus -n monitoring -o yaml

# Export Grafana dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Use Grafana UI: Dashboard → Manage → Export
```

### Documentation Links

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
