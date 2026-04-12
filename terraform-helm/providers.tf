# =============================================================================
# PROVIDERS.TF - Helm Provider Configuration
# =============================================================================
# This is a separate Terraform configuration for Helm charts
# Run AFTER EKS cluster is ready
# =============================================================================

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

# =============================================================================
# AWS PROVIDER
# =============================================================================
provider "aws" {
  region = var.aws_region
}

# =============================================================================
# DATA SOURCES - Get EKS cluster info
# =============================================================================
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# =============================================================================
# KUBERNETES PROVIDER
# =============================================================================
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# =============================================================================
# HELM PROVIDER
# =============================================================================
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
