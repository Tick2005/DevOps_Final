# =============================================================================
# EKS.TF - Amazon EKS Cluster for ProductX
# =============================================================================
# Creates:
# - EKS Control Plane
# - Managed Node Group in Private Subnets
# - OIDC Provider (required for AWS Load Balancer Controller)
# - IAM Roles automatically
# =============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  # ==========================================
  # CLUSTER CONFIGURATION
  # ==========================================
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # VPC Configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # ==========================================
  # OIDC PROVIDER - REQUIRED for AWS LB Controller
  # ==========================================
  enable_irsa = true

  # ==========================================
  # AWS AUTH - Allow IAM users/roles to access cluster
  # ==========================================
  enable_cluster_creator_admin_permissions = true

  # ==========================================
  # CLUSTER ADDONS
  # ==========================================
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # ==========================================
  # MANAGED NODE GROUP
  # ==========================================
  eks_managed_node_groups = {
    main = {
      name = "productx-main-ng"

      # Instance configuration
      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      # Scaling configuration
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Disk configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      # Network configuration
      subnet_ids = module.vpc.private_subnets

      # Labels
      labels = {
        Environment = var.environment
        NodeGroup   = "main"
        Application = "productx"
      }

      # Tags
      tags = {
        Name        = "${var.project_name}-eks-node"
        Environment = var.environment
        Project     = var.project_name
      }
    }
  }

  # ==========================================
  # CLUSTER SECURITY GROUP RULES
  # ==========================================
  cluster_security_group_additional_rules = {
    ingress_ec2_to_cluster = {
      description = "Allow EC2 instances to communicate with cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  # Node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    ingress_db_to_nodes = {
      description = "Allow DB/NFS server to communicate with nodes"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  # ==========================================
  # TAGS
  # ==========================================
  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = var.project_name
  }
}
