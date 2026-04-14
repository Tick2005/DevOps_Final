# =============================================================================
# EC2.TF - Standalone EC2 Instance for Database + NFS
# =============================================================================
# Creates 1 EC2 instance in Public Subnet:
# - Database + NFS Server - PostgreSQL and NFS storage (combined to save cost)
# =============================================================================

# ==========================================
# SECURITY GROUP - DATABASE + NFS SERVER
# ==========================================
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for Database + NFS Server"
  vpc_id      = module.vpc.vpc_id

  # SSH from Internet (for Ansible)
  ingress {
    description = "SSH from anywhere for Ansible"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL - ONLY from VPC internal
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # PostgreSQL - from EKS Node Security Group
  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  # NFS - ONLY from VPC internal
  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NFS - from EKS Node Security Group
  ingress {
    description     = "NFS from EKS nodes"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-db-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==========================================
# EC2 INSTANCE - DATABASE + NFS SERVER
# ==========================================
resource "aws_instance" "db_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.db_instance_type
  key_name                    = var.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.db_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-db-server"
    Environment = var.environment
    Project     = var.project_name
    Role        = "database-nfs-server"
  }
}

# ==========================================
# ELASTIC IP - Fixed IP for DB server
# ==========================================
resource "aws_eip" "db_eip" {
  instance = aws_instance.db_server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-db-eip"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [aws_instance.db_server]
}
