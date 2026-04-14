# =============================================================================
# ALERTMANAGER VALUES TEMPLATE
# =============================================================================
# Template file cho Alertmanager configuration
# Variables: alert_email, alert_email_password
# =============================================================================

alertmanager:
  config:
    global:
      resolve_timeout: 5m
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: '${alert_email}'
      smtp_auth_username: '${alert_email}'
      smtp_auth_password: '${alert_email_password}'
      smtp_require_tls: true

    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'email-notifications'
      routes:
        - match:
            severity: critical
          receiver: 'email-notifications'
          continue: true

    receivers:
      - name: 'email-notifications'
        email_configs:
          - to: '${alert_email}'
            send_resolved: true
            headers:
              Subject: '[ProductX Alert] {{ .GroupLabels.alertname }}'

    inhibit_rules:
      - source_match:
          severity: 'critical'
        target_match:
          severity: 'warning'
        equal: ['alertname', 'cluster', 'service']

# Alert Rules
additionalPrometheusRulesMap:
  productx-alerts:
    groups:
      - name: productx.rules
        interval: 30s
        rules:
          # Pod Down Alert
          - alert: PodDown
            expr: kube_pod_status_phase{namespace="productx", phase!="Running"} > 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Pod {{ $labels.pod }} is down"
              description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has been down for more than 5 minutes."

          # High CPU Usage
          - alert: HighCPUUsage
            expr: sum(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) by (pod) > 0.8
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High CPU usage on {{ $labels.pod }}"
              description: "Pod {{ $labels.pod }} is using more than 80% CPU for 10 minutes."

          # High Memory Usage
          - alert: HighMemoryUsage
            expr: sum(container_memory_working_set_bytes{namespace="productx"}) by (pod) / sum(container_spec_memory_limit_bytes{namespace="productx"}) by (pod) > 0.8
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High memory usage on {{ $labels.pod }}"
              description: "Pod {{ $labels.pod }} is using more than 80% memory for 10 minutes."

          # Deployment Replica Mismatch
          - alert: DeploymentReplicaMismatch
            expr: kube_deployment_spec_replicas{namespace="productx"} != kube_deployment_status_replicas_available{namespace="productx"}
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Deployment {{ $labels.deployment }} has mismatched replicas"
              description: "Deployment {{ $labels.deployment }} desired replicas ({{ $value }}) does not match available replicas."

          # Container Restart
          - alert: ContainerRestarting
            expr: rate(kube_pod_container_status_restarts_total{namespace="productx"}[15m]) > 0
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Container {{ $labels.container }} is restarting"
              description: "Container {{ $labels.container }} in pod {{ $labels.pod }} has restarted {{ $value }} times in the last 15 minutes."

          # Node Not Ready
          - alert: NodeNotReady
            expr: kube_node_status_condition{condition="Ready",status="true"} == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Node {{ $labels.node }} is not ready"
              description: "Node {{ $labels.node }} has been in NotReady state for more than 5 minutes."

          # Persistent Volume Usage
          - alert: PersistentVolumeUsageHigh
            expr: (kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) > 0.8
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "PV {{ $labels.persistentvolumeclaim }} usage is high"
              description: "Persistent Volume {{ $labels.persistentvolumeclaim }} is more than 80% full."
