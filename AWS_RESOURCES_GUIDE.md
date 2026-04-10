# HƯỚNG DẪN TẠO VÀ CẤU HÌNH AWS RESOURCES

## 📋 MỤC LỤC

1. [VPC - Virtual Private Cloud](#1-vpc---virtual-private-cloud)
2. [Subnets](#2-subnets)
3. [Internet Gateway](#3-internet-gateway)
4. [NAT Gateway](#4-nat-gateway)
5. [Route Tables](#5-route-tables)
6. [Security Groups](#6-security-groups)
7. [IAM Roles và Policies](#7-iam-roles-và-policies)
8. [EKS Cluster](#8-eks-cluster)
9. [EC2 Instances](#9-ec2-instances)
10. [Load Balancer](#10-load-balancer)

---

## 1. VPC - Virtual Private Cloud

### 1.1. VPC là gì?

VPC (Virtual Private Cloud) là mạng ảo riêng biệt trong AWS, cô lập hoàn toàn với các VPC khác. Nó giống như một data center ảo của bạn trên AWS.

### 1.2. Tạo VPC với Terraform

Terraform sẽ tự động tạo VPC với cấu hình sau:

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"  # 65,536 IP addresses
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

**Giải thích:**
- `cidr_block`: Dải IP cho VPC (10.0.0.0 - 10.0.255.255)
- `enable_dns_hostnames`: Cho phép EC2 instances có DNS hostname
- `enable_dns_support`: Bật DNS resolution trong VPC

### 1.3. Tạo VPC thủ công (AWS Console)

1. Vào **VPC** → **Your VPCs** → **Create VPC**
2. Cấu hình:
   - Name: `productx-vpc`
   - IPv4 CIDR: `10.0.0.0/16`
   - IPv6 CIDR: No IPv6 CIDR block
   - Tenancy: Default
3. **Create VPC**

---

## 2. Subnets

### 2.1. Subnet là gì?

Subnet là phân đoạn nhỏ hơn của VPC, nằm trong một Availability Zone cụ thể. Có 2 loại:
- **Public Subnet**: Có route đến Internet Gateway, instances có thể truy cập internet
- **Private Subnet**: Không có route trực tiếp đến Internet, chỉ có thể ra ngoài qua NAT Gateway

### 2.2. Availability Zones (AZ)

AWS region được chia thành nhiều AZ (data centers vật lý riêng biệt). Việc deploy trên nhiều AZ giúp:
- High Availability: Nếu 1 AZ down, ứng dụng vẫn chạy
- Fault Tolerance: Tự động chuyển traffic sang AZ khác

**Ví dụ ap-southeast-1 (Singapore):**
- ap-southeast-1a
- ap-southeast-1b
- ap-southeast-1c

### 2.3. Cấu hình Subnets

Terraform tạo 4 subnets trên 2 AZ:

```hcl
# Public Subnets (2)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

# Private Subnets (2)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

**Kết quả:**
- Public Subnet 1: 10.0.0.0/20 (AZ-1) - 4,096 IPs
- Public Subnet 2: 10.0.16.0/20 (AZ-2) - 4,096 IPs
- Private Subnet 1: 10.0.32.0/20 (AZ-1) - 4,096 IPs
- Private Subnet 2: 10.0.48.0/20 (AZ-2) - 4,096 IPs

### 2.4. Tạo Subnets thủ công

1. Vào **VPC** → **Subnets** → **Create subnet**
2. Chọn VPC: `productx-vpc`
3. Tạo Public Subnet 1:
   - Name: `productx-public-1`
   - AZ: `ap-southeast-1a`
   - IPv4 CIDR: `10.0.0.0/20`
4. Lặp lại cho các subnets còn lại

---

## 3. Internet Gateway

### 3.1. Internet Gateway là gì?

Internet Gateway (IGW) cho phép resources trong VPC kết nối với internet. Nó là cổng ra vào giữa VPC và internet.

### 3.2. Tạo với Terraform

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

### 3.3. Tạo thủ công

1. Vào **VPC** → **Internet Gateways** → **Create internet gateway**
2. Name: `productx-igw`
3. **Create**
4. **Actions** → **Attach to VPC** → Chọn `productx-vpc`

---

## 4. NAT Gateway

### 4.1. NAT Gateway là gì?

NAT Gateway cho phép instances trong Private Subnet truy cập internet (outbound) nhưng không cho phép internet truy cập vào (inbound). Dùng để:
- Download packages
- Update OS
- Gọi external APIs

### 4.2. Elastic IP

NAT Gateway cần một Elastic IP (static public IP):

```hcl
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # Phải đặt trong Public Subnet
}
```

### 4.3. Tạo thủ công

1. **Tạo Elastic IP:**
   - Vào **VPC** → **Elastic IPs** → **Allocate Elastic IP address**
   - **Allocate**

2. **Tạo NAT Gateway:**
   - Vào **VPC** → **NAT Gateways** → **Create NAT gateway**
   - Name: `productx-nat`
   - Subnet: Chọn Public Subnet 1
   - Elastic IP: Chọn EIP vừa tạo
   - **Create**

---

## 5. Route Tables

### 5.1. Route Table là gì?

Route Table định nghĩa cách traffic được route trong VPC. Mỗi subnet phải associate với một route table.

### 5.2. Public Route Table

Route table cho Public Subnets, có route đến Internet Gateway:

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # All traffic
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

**Giải thích:**
- `0.0.0.0/0`: Tất cả traffic không thuộc VPC
- `gateway_id`: Route qua Internet Gateway

### 5.3. Private Route Table

Route table cho Private Subnets, có route đến NAT Gateway:

```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

### 5.4. Tạo thủ công

1. **Public Route Table:**
   - Vào **VPC** → **Route Tables** → **Create route table**
   - Name: `productx-public-rt`
   - VPC: `productx-vpc`
   - **Create**
   - **Routes** → **Edit routes** → **Add route**
     - Destination: `0.0.0.0/0`
     - Target: Internet Gateway (`productx-igw`)
   - **Subnet associations** → **Edit** → Chọn 2 Public Subnets

2. **Private Route Table:**
   - Tương tự, nhưng Target là NAT Gateway

---

## 6. Security Groups

### 6.1. Security Group là gì?

Security Group là firewall ảo cho EC2 instances, kiểm soát inbound và outbound traffic.

### 6.2. Security Group cho EKS Cluster

```hcl
resource "aws_security_group" "eks_cluster" {
  name        = "productx-eks-cluster-sg"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Giải thích:**
- `egress`: Outbound rules (cho phép tất cả)
- `ingress`: Inbound rules (EKS tự động quản lý)

### 6.3. Security Group cho Database

```hcl
resource "aws_security_group" "database" {
  name   = "productx-database-sg"
  vpc_id = aws_vpc.main.id

  # PostgreSQL từ VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR
  }

  # SSH từ anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NFS từ VPC
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 6.4. Tạo thủ công

1. Vào **EC2** → **Security Groups** → **Create security group**
2. Name: `productx-database-sg`
3. VPC: `productx-vpc`
4. **Inbound rules** → **Add rule**:
   - Type: PostgreSQL, Port: 5432, Source: 10.0.0.0/16
   - Type: SSH, Port: 22, Source: 0.0.0.0/0
   - Type: NFS, Port: 2049, Source: 10.0.0.0/16
5. **Outbound rules**: All traffic
6. **Create**

---

## 7. IAM Roles và Policies

### 7.1. IAM là gì?

IAM (Identity and Access Management) quản lý quyền truy cập AWS resources.

### 7.2. IAM Role cho EKS Cluster

```hcl
resource "aws_iam_role" "eks_cluster" {
  name = "productx-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}
```

**Giải thích:**
- `assume_role_policy`: Cho phép EKS service sử dụng role này
- `AmazonEKSClusterPolicy`: Managed policy của AWS cho EKS

### 7.3. IAM Role cho EKS Nodes

```hcl
resource "aws_iam_role" "eks_nodes" {
  name = "productx-eks-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach 3 policies
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}
```

### 7.4. Tạo thủ công

1. **EKS Cluster Role:**
   - Vào **IAM** → **Roles** → **Create role**
   - Trusted entity: AWS service → EKS → EKS - Cluster
   - Permissions: AmazonEKSClusterPolicy
   - Name: `productx-eks-cluster-role`

2. **EKS Nodes Role:**
   - Trusted entity: AWS service → EC2
   - Permissions:
     - AmazonEKSWorkerNodePolicy
     - AmazonEKS_CNI_Policy
     - AmazonEC2ContainerRegistryReadOnly
   - Name: `productx-eks-nodes-role`

---

## 8. EKS Cluster

### 8.1. EKS là gì?

Amazon EKS (Elastic Kubernetes Service) là managed Kubernetes service. AWS quản lý control plane, bạn chỉ cần quản lý worker nodes.

### 8.2. Tạo với Terraform

```hcl
resource "aws_eks_cluster" "main" {
  name     = "productx-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }
}
```

### 8.3. Node Group

```hcl
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "productx-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
}
```

**Giải thích:**
- `subnet_ids`: Nodes chạy trong Private Subnets
- `instance_types`: t3.medium (2 vCPU, 4GB RAM)
- `scaling_config`: Auto-scaling từ 1-4 nodes

### 8.4. Tạo thủ công

1. Vào **EKS** → **Clusters** → **Create cluster**
2. Name: `productx-eks`
3. Kubernetes version: 1.31
4. Cluster service role: `productx-eks-cluster-role`
5. **Next**
6. VPC: `productx-vpc`
7. Subnets: Chọn tất cả 4 subnets
8. Security groups: `productx-eks-cluster-sg`
9. **Next** → **Next** → **Create**
10. Sau khi cluster ready, tạo Node Group:
    - **Compute** → **Add node group**
    - Name: `productx-node-group`
    - Node IAM role: `productx-eks-nodes-role`
    - Instance type: t3.medium
    - Scaling: Min 1, Max 4, Desired 2

---

## 9. EC2 Instances

### 9.1. Tạo Database + NFS Server

```hcl
resource "aws_instance" "database" {
  ami                    = "ami-01811d4912b4ccb26"  # Ubuntu 22.04
  instance_type          = "t3.medium"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.database.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "productx-database-nfs"
  }
}
```

### 9.2. Tạo thủ công

1. Vào **EC2** → **Instances** → **Launch instances**
2. Name: `productx-database-nfs`
3. AMI: Ubuntu Server 22.04 LTS
4. Instance type: t3.medium
5. Key pair: Chọn key đã tạo
6. Network settings:
   - VPC: `productx-vpc`
   - Subnet: Public Subnet 1
   - Auto-assign public IP: Enable
   - Security group: `productx-database-sg`
7. Storage: 30 GB gp3
8. **Launch instance**

---

## 10. Load Balancer

### 10.1. Application Load Balancer (ALB)

ALB được tạo tự động bởi AWS Load Balancer Controller khi deploy Kubernetes Ingress.

### 10.2. Cách hoạt động

1. Deploy Ingress manifest
2. AWS Load Balancer Controller detect Ingress
3. Tự động tạo ALB
4. Tự động tạo Target Groups
5. Tự động register Pods làm targets

### 10.3. Kiểm tra ALB

```bash
kubectl get ingress -n productx
```

Output:
```
NAME          CLASS   HOSTS   ADDRESS                                    PORTS   AGE
app-ingress   alb     *       k8s-productx-appingre-xxx.ap-southeast-1.elb.amazonaws.com   80      5m
```

---

## 📊 Tổng kết Chi phí (Ước tính)

| Resource | Type | Số lượng | Chi phí/tháng (USD) |
|----------|------|----------|---------------------|
| EKS Cluster | Control Plane | 1 | $72 |
| EC2 Nodes | t3.medium | 2 | $60 |
| EC2 Database | t3.medium | 1 | $30 |
| NAT Gateway | - | 1 | $32 |
| ALB | - | 1 | $16 |
| EBS Volumes | gp3 | ~100GB | $8 |
| **TỔNG** | | | **~$218/tháng** |

**Lưu ý:**
- Chi phí có thể thay đổi theo region
- Có thể giảm chi phí bằng cách:
  - Dùng Spot Instances cho nodes
  - Tắt môi trường khi không dùng
  - Dùng t3.small thay vì t3.medium

---

## 🔗 Tài liệu tham khảo

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
