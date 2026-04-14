# =============================================================================
# VARIABLES.TF - Terraform Monitoring Module Variables
# =============================================================================

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
