# =============================================================================
# OUTPUTS.TF - Export information after deployment for ProductX
# =============================================================================

# ==========================================
# VPC INFORMATION
# ==========================================
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private Subnet IDs"
  value       = module.vpc.private_subnets
}

# ==========================================
# EKS CLUSTER INFORMATION
# ==========================================
output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_cluster_security_group_id" {
  description = "EKS Cluster Security Group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS Worker Nodes Security Group ID"
  value       = module.eks.node_security_group_id
}

output "eks_oidc_provider_arn" {
  description = "OIDC Provider ARN (for AWS Load Balancer Controller)"
  value       = module.eks.oidc_provider_arn
}

# ==========================================
# KUBECONFIG COMMAND
# ==========================================
output "kubeconfig_command" {
  description = "Command to configure kubectl to connect to EKS cluster"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

# ==========================================
# DATABASE + NFS SERVER
# ==========================================
output "db_public_ip" {
  description = "Public IP of Database + NFS Server"
  value       = aws_eip.db_eip.public_ip
}

output "db_private_ip" {
  description = "Private IP of Database + NFS Server (use for NFS configuration)"
  value       = aws_instance.db_server.private_ip
}

output "db_instance_id" {
  description = "Instance ID of DB + NFS Server"
  value       = aws_instance.db_server.id
}

# ==========================================
# SSH COMMANDS
# ==========================================
output "ssh_db" {
  description = "SSH command to Database + NFS Server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.db_eip.public_ip}"
}

# ==========================================
# DEPLOYMENT SUMMARY
# ==========================================
output "deployment_summary" {
  description = "Deployment information summary"
  value = <<-EOT
    
    ============================================
    🚀 PRODUCTX - EKS INFRASTRUCTURE DEPLOYED
    ============================================
    
    📦 EKS CLUSTER:
       - Cluster Name: ${module.eks.cluster_name}
       - Kubernetes Version: ${module.eks.cluster_version}
       - Endpoint: ${module.eks.cluster_endpoint}
       - OIDC Provider: ${module.eks.oidc_provider_arn}
       
       🔧 Connect kubectl:
       aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}
    
    💾 DATABASE + NFS SERVER:
       - Public IP:  ${aws_eip.db_eip.public_ip}
       - Private IP: ${aws_instance.db_server.private_ip}
       - SSH: ssh -i ${var.key_name}.pem ubuntu@${aws_eip.db_eip.public_ip}
       
       ⚠️  Run Ansible to install PostgreSQL and NFS!
    
    🌐 VPC INFORMATION:
       - VPC ID: ${module.vpc.vpc_id}
       - CIDR: ${module.vpc.vpc_cidr_block}
       - Public Subnets: ${join(", ", module.vpc.public_subnets)}
       - Private Subnets: ${join(", ", module.vpc.private_subnets)}
    
    ⏳ Notes:
       - EKS cluster needs 10-15 minutes to complete
       - Run kubeconfig command above to connect kubectl
       - Run Ansible playbooks to configure DB and NFS
    
    ============================================
    EOT
}

# ==========================================
# ANSIBLE INVENTORY HELPER
# ==========================================
output "ansible_inventory_snippet" {
  description = "Snippet to add to Ansible inventory"
  value = <<-EOT
    
    # Add to ansible/inventory/hosts.ini:
    
    [database]
    db-server ansible_host=${aws_eip.db_eip.public_ip} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3
    
    [nfs_server]
    db-server ansible_host=${aws_eip.db_eip.public_ip} ansible_user=ubuntu
    
    # Private IP for NFS mount in K8s:
    # NFS_SERVER_IP=${aws_instance.db_server.private_ip}
    
    EOT
}
