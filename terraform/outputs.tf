# =============================================================================
# OUTPUTS.TF - Xuất thông tin sau khi Terraform apply
# =============================================================================

output "vpc_id" {
  description = "ID của VPC"
  value       = aws_vpc.main.id
}

output "eks_cluster_name" {
  description = "Tên EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint của EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "database_public_ip" {
  description = "Public IP của Database server"
  value       = aws_instance.database.public_ip
}

output "database_private_ip" {
  description = "Private IP của Database server (dùng trong K8s)"
  value       = aws_instance.database.private_ip
}

output "configure_kubectl" {
  description = "Lệnh để cấu hình kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "ssh_database" {
  description = "Lệnh SSH vào Database server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.database.public_ip}"
}

output "next_steps" {
  description = "Các bước tiếp theo"
  value       = <<-EOT
    ============================================
    ✅ INFRASTRUCTURE CREATED SUCCESSFULLY!
    ============================================
    
    📋 THÔNG TIN QUAN TRỌNG:
    
    1. EKS Cluster: ${aws_eks_cluster.main.name}
    2. Database Private IP: ${aws_instance.database.private_ip}
    3. Database Public IP: ${aws_instance.database.public_ip}
    
    🔧 CÁC BƯỚC TIẾP THEO:
    
    1. Cấu hình kubectl:
       aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}
    
    2. Chạy Ansible để cài đặt Database và NFS:
       cd ../ansible
       ansible-playbook -i inventory/hosts.ini playbooks/site.yml -e "db_password=YOUR_PASSWORD"
    
    3. Cập nhật GitHub Secrets với các giá trị sau:
       - EKS_CLUSTER_NAME: ${aws_eks_cluster.main.name}
       - DATA_SERVER_IP: ${aws_instance.database.private_ip}
       - DB_PASSWORD: (password bạn đã đặt)
    
    4. Deploy ứng dụng:
       git push origin main
    
    ============================================
  EOT
}
