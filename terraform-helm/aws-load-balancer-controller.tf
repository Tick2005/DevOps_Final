# =============================================================================
# AWS-LOAD-BALANCER-CONTROLLER.TF - Install AWS Load Balancer Controller
# =============================================================================
# This Terraform configuration installs AWS Load Balancer Controller via Helm
# Run AFTER EKS cluster is ready
# =============================================================================

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  set {
    name  = "clusterName"
    value = var.cluster_name
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
    value = var.lb_controller_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  # Wait for deployment to be ready
  wait    = true
  timeout = 300
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "helm_release_status" {
  description = "Status of AWS Load Balancer Controller Helm release"
  value       = helm_release.aws_load_balancer_controller.status
}

output "helm_release_version" {
  description = "Version of AWS Load Balancer Controller installed"
  value       = helm_release.aws_load_balancer_controller.version
}
