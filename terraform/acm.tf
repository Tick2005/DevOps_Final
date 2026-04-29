# =============================================================================
# ACM.TF - HTTPS Certificate Configuration for ProductX (OPTIONAL)
# =============================================================================
# Purpose:
#   - Automatically request SSL/TLS certificates from AWS Certificate Manager
#   - Creates separate certificates for production, staging, and monitoring
#   - Only creates when enable_https = true and domain_name is provided
# =============================================================================

locals {
  # Only create HTTPS resources when both conditions are true
  create_https = var.enable_https && var.domain_name != ""

  # Subdomain configurations
  staging_domain    = "staging.${var.domain_name}"
  monitoring_domain = "monitoring.${var.domain_name}"
}

# =============================================================================
# ACM CERTIFICATE: Production (Main Domain + Wildcard)
# =============================================================================
resource "aws_acm_certificate" "production_cert" {
  count = local.create_https ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-production-cert"
    Environment = "production"
    Domain      = var.domain_name
    Purpose     = "Production-ALB"
  }
}

# =============================================================================
# ACM CERTIFICATE: Staging Environment
# =============================================================================
resource "aws_acm_certificate" "staging_cert" {
  count = local.create_https ? 1 : 0

  domain_name       = local.staging_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-staging-cert"
    Environment = "staging"
    Domain      = local.staging_domain
    Purpose     = "Staging-ALB"
  }
}

# =============================================================================
# ACM CERTIFICATE: Monitoring (Grafana)
# =============================================================================
resource "aws_acm_certificate" "monitoring_cert" {
  count = local.create_https ? 1 : 0

  domain_name       = local.monitoring_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-monitoring-cert"
    Environment = "production"
    Domain      = local.monitoring_domain
    Purpose     = "Monitoring-ALB-Grafana"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "production_certificate_arn" {
  description = "ARN of Production HTTPS certificate"
  value       = local.create_https ? aws_acm_certificate.production_cert[0].arn : "N/A - HTTPS not enabled"
}

output "staging_certificate_arn" {
  description = "ARN of Staging HTTPS certificate"
  value       = local.create_https ? aws_acm_certificate.staging_cert[0].arn : "N/A - HTTPS not enabled"
}

output "monitoring_certificate_arn" {
  description = "ARN of Monitoring HTTPS certificate"
  value       = local.create_https ? aws_acm_certificate.monitoring_cert[0].arn : "N/A - HTTPS not enabled"
}

output "https_status" {
  description = "HTTPS configuration status for all environments"
  value = local.create_https ? {
    enabled = true
    production = {
      domain   = var.domain_name
      wildcard = "*.${var.domain_name}"
      cert_arn = aws_acm_certificate.production_cert[0].arn
    }
    staging = {
      domain   = local.staging_domain
      cert_arn = aws_acm_certificate.staging_cert[0].arn
    }
    monitoring = {
      domain   = local.monitoring_domain
      cert_arn = aws_acm_certificate.monitoring_cert[0].arn
    }
    message = "✅ HTTPS enabled - All certificates ready for Ingress"
    } : {
    enabled = false
    production = {
      domain   = "N/A"
      wildcard = "N/A"
      cert_arn = "N/A"
    }
    staging = {
      domain   = "N/A"
      cert_arn = "N/A"
    }
    monitoring = {
      domain   = "N/A"
      cert_arn = "N/A"
    }
    message = "⚠️  HTTPS disabled - Set enable_https=true and provide domain_name to enable"
  }
}

output "certificate_validation_records" {
  description = "DNS validation records for all certificates (use these in Hostinger)"
  value = local.create_https ? {
    production = {
      domain = var.domain_name
      records = [
        for dvo in aws_acm_certificate.production_cert[0].domain_validation_options : {
          name   = dvo.resource_record_name
          type   = dvo.resource_record_type
          value  = dvo.resource_record_value
          domain = dvo.domain_name
        }
      ]
    }
    staging = {
      domain = local.staging_domain
      records = [
        for dvo in aws_acm_certificate.staging_cert[0].domain_validation_options : {
          name   = dvo.resource_record_name
          type   = dvo.resource_record_type
          value  = dvo.resource_record_value
          domain = dvo.domain_name
        }
      ]
    }
    monitoring = {
      domain = local.monitoring_domain
      records = [
        for dvo in aws_acm_certificate.monitoring_cert[0].domain_validation_options : {
          name   = dvo.resource_record_name
          type   = dvo.resource_record_type
          value  = dvo.resource_record_value
          domain = dvo.domain_name
        }
      ]
    }
  } : null
}
