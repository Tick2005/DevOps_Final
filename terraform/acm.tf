# =============================================================================
# ACM.TF - HTTPS Certificate Configuration for ProductX (OPTIONAL)
# =============================================================================
# Purpose:
#   - Automatically request SSL/TLS certificate from AWS Certificate Manager
#   - Only creates when enable_https = true and domain_name is provided
# =============================================================================

locals {
  # Only create HTTPS resources when both conditions are true
  create_https = var.enable_https && var.domain_name != ""
}

# =============================================================================
# ACM CERTIFICATE: Request SSL/TLS certificate
# =============================================================================
resource "aws_acm_certificate" "cert" {
  count = local.create_https ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-https-cert"
    Environment = var.environment
    Domain      = var.domain_name
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "https_certificate_arn" {
  description = "ARN of HTTPS certificate (use in Kubernetes Ingress annotation)"
  value       = local.create_https ? aws_acm_certificate.cert[0].arn : "N/A - HTTPS not enabled"
}

output "https_status" {
  description = "HTTPS configuration status"
  value = local.create_https ? {
    enabled  = true
    domain   = var.domain_name
    wildcard = "*.${var.domain_name}"
    cert_arn = aws_acm_certificate.cert[0].arn
    message  = "✅ HTTPS enabled - Certificate ARN ready for Ingress"
    } : {
    enabled = false
    message = "⚠️  HTTPS disabled - Set enable_https=true and provide domain_name to enable"
  }
}
