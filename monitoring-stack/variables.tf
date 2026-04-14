# =============================================================================
# VARIABLES.TF - Terraform Monitoring Module Variables
# =============================================================================

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS Cluster CA Certificate"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
  default     = ""
}

variable "alert_email_password" {
  description = "Email password for alerts"
  type        = string
  default     = ""
  sensitive   = true
}
