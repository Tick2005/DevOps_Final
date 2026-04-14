# =============================================================================
# LOAD-BALANCER-CONTROLLER.TF - AWS Load Balancer Controller for ProductX
# =============================================================================
# IAM Role for Load Balancer Controller
# Installation will be done via kubectl in GitHub Actions workflow
# =============================================================================

# =============================================================================
# DATA SOURCE - Get AWS account info
# =============================================================================
data "aws_caller_identity" "current" {}

# =============================================================================
# IAM ROLE - Service Account for Load Balancer Controller
# =============================================================================
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name        = "${var.cluster_name}-lb-controller-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# =============================================================================
# OUTPUT - IAM Role ARN for Load Balancer Controller
# =============================================================================
output "aws_load_balancer_controller_role_arn" {
  description = "IAM Role ARN for AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller_irsa.iam_role_arn
}

# =============================================================================
# NOTE: AWS Load Balancer Controller installation
# =============================================================================
# The controller will be installed via Terraform Helm Provider in a separate
# terraform-helm module, which runs AFTER EKS cluster is ready in GitHub Actions.
#
# This avoids Helm provider initialization issues.
# =============================================================================
