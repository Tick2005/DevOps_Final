# =============================================================================
# VPC.TF - Virtual Private Cloud for ProductX
# =============================================================================
# Creates:
# - 1 VPC with CIDR 10.0.0.0/16
# - 2 Public Subnets (with Internet Gateway)
# - 2 Private Subnets (with NAT Gateway)
# - Tags for AWS Load Balancer Controller
# =============================================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  # Use first 2 Availability Zones
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Public Subnets - for ALB and EC2 standalone servers
  public_subnets = var.public_subnet_cidrs

  # Private Subnets - for EKS Worker Nodes
  private_subnets = var.private_subnet_cidrs

  # Enable NAT Gateway for Private Subnets
  enable_nat_gateway = true
  single_nat_gateway = true # Use 1 NAT Gateway to save cost

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Common tags
  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }

  # Tags for Public Subnets - for AWS Load Balancer Controller
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  # Tags for Private Subnets - for AWS Load Balancer Controller
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
