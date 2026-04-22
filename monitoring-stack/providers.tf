# =============================================================================
# PROVIDERS.TF - Terraform Monitoring Module Providers
# =============================================================================

terraform {
  required_version = ">= 1.0"

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

# Note: Providers are configured via environment variables in the workflow
# This avoids the need to pass cluster info as variables during init
# The workflow sets KUBE_CONFIG_PATH which is used by both providers
