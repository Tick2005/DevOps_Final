# =============================================================================
# VARIABLES.TF - Input variables for Helm installation
# =============================================================================

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "lb_controller_role_arn" {
  description = "IAM Role ARN for AWS Load Balancer Controller"
  type        = string
}
