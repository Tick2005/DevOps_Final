# =============================================================================
# PROMETHEUS-GRAFANA.TF - Monitoring Stack for ProductX
# =============================================================================
# Deploy kube-prometheus-stack bao gồm:
# - Prometheus (metrics collection)
# - Grafana (visualization)
# - Alertmanager (alerting)
# - Node Exporter (node metrics)
# - Kube State Metrics (K8s metrics)
# =============================================================================

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  version    = "56.0.0"

  create_namespace = true
  
  # Tăng timeout vì Prometheus stack khá nặng
  timeout = 900  # 15 phút
  
  # Chờ resources ready
  wait          = true
  wait_for_jobs = true

  # Load Alertmanager configuration từ template
  values = [
    templatefile("${path.module}/alertmanager-values.yaml.tpl", {
      alert_email          = var.alert_email
      alert_email_password = var.alert_email_password
    })
  ]

  # =============================================================================
  # PROMETHEUS CONFIGURATION
  # =============================================================================
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "15d"
  }

  set {
    name  = "prometheus.prometheusSpec.scrapeInterval"
    value = "30s"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp3"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "20Gi"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = "2Gi"
  }

  # =============================================================================
  # GRAFANA CONFIGURATION
  # =============================================================================
  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = "gp3"
  }

  set {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "grafana.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "grafana.resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "grafana.resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "grafana.resources.limits.memory"
    value = "512Mi"
  }

  # Grafana Ingress - disabled, sẽ tạo riêng
  set {
    name  = "grafana.ingress.enabled"
    value = "false"
  }

  # =============================================================================
  # ALERTMANAGER CONFIGURATION
  # =============================================================================
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = "gp3"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = "5Gi"
  }

  # =============================================================================
  # NODE EXPORTER (thu thập node metrics)
  # =============================================================================
  set {
    name  = "nodeExporter.enabled"
    value = "true"
  }

  # =============================================================================
  # KUBE STATE METRICS (thu thập K8s object metrics)
  # =============================================================================
  set {
    name  = "kubeStateMetrics.enabled"
    value = "true"
  }

  # =============================================================================
  # PROMETHEUS OPERATOR
  # =============================================================================
  set {
    name  = "prometheusOperator.enabled"
    value = "true"
  }

  depends_on = [
    helm_release.metrics_server,
    kubernetes_storage_class_v1.gp3
  ]
}
