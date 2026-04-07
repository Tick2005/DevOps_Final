# Terraform Configuration for K3s Cluster on Cloud Provider
# This configuration provisions infrastructure for Tier 5 Kubernetes deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "startupx-k3s"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "master_instance_type" {
  description = "EC2 instance type for K3s master"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "EC2 instance type for K3s workers"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
