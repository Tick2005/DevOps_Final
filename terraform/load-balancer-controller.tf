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
# The controller will be installed via kubectl/helm in GitHub Actions workflow
# after EKS cluster is ready. This avoids Terraform provider initialization issues.
#
# Installation command (in GitHub Actions):
#   helm repo add eks https://aws.github.io/eks-charts
#   helm repo update
#   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#     -n kube-system \
#     --set clusterName=${CLUSTER_NAME} \
#     --set serviceAccount.create=true \
#     --set serviceAccount.name=aws-load-balancer-controller \
#     --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${ROLE_ARN}
# =============================================================================

# =============================================================================
# HELM RELEASE - AWS Load Balancer Controller
# =============================================================================
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.cluster.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa.iam_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.eks,
    module.aws_load_balancer_controller_irsa,
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]
}
