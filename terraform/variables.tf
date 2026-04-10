# =============================================================================
# VARIABLES.TF - Biến cấu hình cho Terraform
# =============================================================================

variable "aws_region" {
  description = "AWS Region để deploy infrastructure"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Tên project (dùng làm prefix cho resources)"
  type        = string
  default     = "productx"
}

variable "vpc_cidr" {
  description = "CIDR block cho VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "key_name" {
  description = "Tên SSH key pair trên AWS (không có .pem)"
  type        = string
}

variable "ubuntu_ami" {
  description = "AMI ID cho Ubuntu 22.04 LTS"
  type        = string
  default     = "ami-01811d4912b4ccb26" # Ubuntu 22.04 LTS trong ap-southeast-1
}

variable "enable_https" {
  description = "Bật HTTPS với ACM certificate"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name cho HTTPS (để trống nếu không dùng)"
  type        = string
  default     = ""
}
