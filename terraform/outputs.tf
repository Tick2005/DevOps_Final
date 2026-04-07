# Output values for easy access to cluster information

output "master_public_ip" {
  description = "Public IP address of K3s master node"
  value       = aws_instance.k3s_master.public_ip
}

output "master_private_ip" {
  description = "Private IP address of K3s master node"
  value       = aws_instance.k3s_master.private_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of K3s worker nodes"
  value       = aws_instance.k3s_worker[*].public_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of K3s worker nodes"
  value       = aws_instance.k3s_worker[*].private_ip
}

output "ssh_command_master" {
  description = "SSH command to connect to master node"
  value       = "ssh -i ~/.ssh/k3s-key ubuntu@${aws_eip.k3s_master.public_ip}"
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig from master"
  value       = "scp -i ~/.ssh/k3s-key ubuntu@${aws_eip.k3s_master.public_ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}
