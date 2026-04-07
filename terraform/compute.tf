# K3s Master Node
resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_instance_type
  key_name               = aws_key_pair.k3s.key_name
  vpc_security_group_ids = [aws_security_group.k3s_master.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/scripts/install-k3s-master.sh", {
    k3s_version = "v1.28.5+k3s1"
  })

  tags = {
    Name        = "${var.project_name}-master"
    Environment = var.environment
    Role        = "master"
  }
}

# K3s Worker Nodes
resource "aws_instance" "k3s_worker" {
  count = var.worker_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  key_name               = aws_key_pair.k3s.key_name
  vpc_security_group_ids = [aws_security_group.k3s_worker.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/scripts/install-k3s-worker.sh", {
    k3s_version    = "v1.28.5+k3s1"
    master_ip      = aws_instance.k3s_master.private_ip
    k3s_token_file = "/var/lib/rancher/k3s/server/node-token"
  })

  depends_on = [aws_instance.k3s_master]

  tags = {
    Name        = "${var.project_name}-worker-${count.index + 1}"
    Environment = var.environment
    Role        = "worker"
  }
}

# Elastic IP for Master Node
resource "aws_eip" "k3s_master" {
  instance = aws_instance.k3s_master.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-master-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}
