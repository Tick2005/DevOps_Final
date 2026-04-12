# =============================================================================
# VARIABLES.TF - Input Variables for ProductX Infrastructure
# =============================================================================

# ==========================================
# REQUIRED VARIABLES
# ==========================================
variable "key_name" {
  description = "Tên SSH key pair trên AWS để truy cập EC2"
  type        = string
}

# ==========================================
# DEFAULT VARIABLES
# ==========================================
variable "aws_region" {
  description = "AWS Region để triển khai"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Tên dự án (dùng cho tags và naming)"
  type        = string
  default     = "productx"
}

variable "environment" {
  description = "Môi trường triển khai"
  type        = string
  default     = "production"
}

# ==========================================
# VPC CONFIGURATION
# ==========================================
variable "vpc_cidr" {
  description = "CIDR block cho VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks cho Public Subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks cho Private Subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ==========================================
# EKS CONFIGURATION
# ==========================================
variable "cluster_name" {
  description = "Tên EKS Cluster"
  type        = string
  default     = "productx-eks-cluster"
}

variable "cluster_version" {
  description = "Phiên bản Kubernetes cho EKS"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "Instance type cho EKS Worker Nodes"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "Số lượng nodes mong muốn"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Số lượng nodes tối thiểu"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Số lượng nodes tối đa"
  type        = number
  default     = 4
}

# ==========================================
# EC2 DATABASE + NFS SERVER
# ==========================================
variable "db_instance_type" {
  description = "Instance type cho Database + NFS Server"
  type        = string
  default     = "t3.micro"
}

variable "db_volume_size" {
  description = "Dung lượng ổ cứng cho DB + NFS Server (GB)"
  type        = number
  default     = 30
}

# ==========================================
# HTTPS CONFIGURATION (OPTIONAL)
# ==========================================
variable "domain_name" {
  description = "Domain name cho HTTPS (để trống nếu không dùng)"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Bật HTTPS với ACM certificate"
  type        = bool
  default     = false
}
