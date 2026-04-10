# HƯỚNG DẪN CẤU HÌNH SONARQUBE

## 📋 Tổng quan

SonarQube là công cụ code quality analysis self-hosted, miễn phí hoàn toàn cho mọi loại dự án. Khác với SonarCloud, bạn cần tự host SonarQube server trên EC2 instance.

## ✅ Ưu điểm của SonarQube

| Tiêu chí | SonarQube | SonarCloud |
|----------|-----------|------------|
| Chi phí | Miễn phí hoàn toàn | Miễn phí chỉ cho public repos |
| Private repos | ✅ Không giới hạn | ❌ Phải trả phí |
| Kiểm soát | ✅ Toàn quyền | ❌ Phụ thuộc service |
| Cài đặt | Cần EC2 instance | Không cần setup |

## 🚀 Bước 1: Chuẩn bị EC2 Instance

### 1.1. Yêu cầu tối thiểu

- Instance type: t3.medium (2 vCPU, 4GB RAM)
- Storage: 20GB gp3
- OS: Ubuntu 22.04 LTS
- Security Group: Mở port 9000

### 1.2. Cập nhật Terraform

Thêm SonarQube instance vào `terraform/main.tf`:

```hcl
# SonarQube Server
resource "aws_instance" "sonarqube" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.sonarqube.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  
  tags = {
    Name = "${var.project_name}-sonarqube"
  }
}

# Security Group cho SonarQube
resource "aws_security_group" "sonarqube" {
  name        = "${var.project_name}-sonarqube-sg"
  description = "Security group for SonarQube server"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-sonarqube-sg"
  }
}
```

Thêm output trong `terraform/outputs.tf`:

```hcl
output "sonarqube_public_ip" {
  description = "Public IP của SonarQube server"
  value       = aws_instance.sonarqube.public_ip
}
```

## 🔧 Bước 2: Cài đặt SonarQube với Ansible

### 2.1. Cập nhật Inventory

Chỉnh sửa `ansible/inventory/hosts.ini`:

```ini
[sonarqube]
sonar-server ansible_host=<SONARQUBE_PUBLIC_IP> ansible_user=ubuntu
```

### 2.2. Chạy Ansible Playbook

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/sonarqube.yml
```

Playbook sẽ:
- Cài đặt Docker
- Cấu hình kernel parameters cho Elasticsearch
- Chạy SonarQube container
- Đợi SonarQube khởi động (có thể mất 2-3 phút)

### 2.3. Truy cập SonarQube

Sau khi cài đặt xong:
- URL: `http://<SONARQUBE_PUBLIC_IP>:9000`
- Username: `admin`
- Password: `admin`

⚠️ Đổi password ngay sau lần đăng nhập đầu tiên!

## 🔑 Bước 3: Tạo Project và Token

### 3.1. Tạo Project

1. Đăng nhập vào SonarQube
2. Click **Create Project** → **Manually**
3. Điền thông tin:
   - Project key: `productx-backend`
   - Display name: `ProductX Backend`
4. Click **Set Up**

### 3.2. Tạo Token

1. Trong project vừa tạo, click **Locally**
2. Generate token:
   - Token name: `github-actions`
   - Type: **Global Analysis Token**
   - Expires in: **No expiration**
3. Click **Generate**
4. Copy token (chỉ hiển thị 1 lần!)

Ví dụ token:
```
squ_abc123def456ghi789jkl012mno345pqr678
```

## 🔐 Bước 4: Cấu hình GitHub Secrets

Vào GitHub repository → Settings → Secrets and variables → Actions → New repository secret:

### 4.1. SONAR_TOKEN
```
squ_abc123def456ghi789jkl012mno345pqr678
```

### 4.2. SONAR_HOST_URL
```
http://<SONARQUBE_PUBLIC_IP>:9000
```

### 4.3. SONAR_PROJECT_KEY
```
productx-backend
```

## 📝 Bước 5: Cập nhật .env

Thêm vào file `.env`:

```bash
# SonarQube Configuration
SONAR_HOST_URL=http://<SONARQUBE_PUBLIC_IP>:9000
SONAR_TOKEN=squ_abc123def456ghi789jkl012mno345pqr678
SONAR_PROJECT_KEY=productx-backend
```

## ✅ Bước 6: Test CI Pipeline

1. Commit và push code:
   ```bash
   git add .
   git commit -m "Configure SonarQube"
   git push origin main
   ```

2. Vào **Actions** tab trên GitHub, xem workflow chạy

3. Sau khi workflow hoàn thành, vào SonarQube project để xem kết quả

## 📊 Bước 7: Xem Kết quả Analysis

### 7.1. Dashboard

Trên SonarQube project dashboard, bạn sẽ thấy:

- **Bugs**: Số lỗi trong code
- **Vulnerabilities**: Lỗ hổng bảo mật
- **Code Smells**: Code không tối ưu
- **Coverage**: Test coverage %
- **Duplications**: Code trùng lặp %

### 7.2. Quality Gate

SonarQube sẽ đánh giá code dựa trên Quality Gate:
- ✅ **Passed**: Code đạt tiêu chuẩn
- ❌ **Failed**: Code không đạt, cần sửa

## 🔧 Bước 8: Cấu hình nâng cao (Optional)

### 8.1. Exclude Files

File `sonar-project.properties` đã được cấu hình:

```properties
sonar.exclusions=**/node_modules/**,**/target/**,**/dist/**,**/*.test.js
sonar.coverage.exclusions=**/*.test.js,**/*.test.jsx,**/test/**
```

### 8.2. Quality Gate tùy chỉnh

1. Vào **Quality Gates** → **Create**
2. Đặt tên: `ProductX Gate`
3. Thêm conditions:
   - Coverage > 80%
   - Duplications < 3%
   - Maintainability Rating = A
4. Set as default

### 8.3. Webhooks (Optional)

Để SonarQube gửi kết quả về GitHub:

1. Vào **Administration** → **Configuration** → **Webhooks**
2. Click **Create**
3. Điền:
   - Name: `GitHub`
   - URL: `https://api.github.com/repos/<username>/<repo>/statuses/{analysis.revision}`
   - Secret: GitHub token

## 🔒 Bước 9: Bảo mật (Production)

### 9.1. Sử dụng HTTPS

Cài đặt Nginx + Let's Encrypt:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/sonarqube.yml \
  -e "enable_https=true" \
  -e "domain_name=yourdomain.com"
```

Sau đó truy cập: `https://sonar.yourdomain.com`

### 9.2. Giới hạn IP

Chỉnh Security Group để chỉ cho phép IP của GitHub Actions:

```hcl
ingress {
  from_port   = 9000
  to_port     = 9000
  protocol    = "tcp"
  cidr_blocks = ["<GITHUB_ACTIONS_IP>/32"]
}
```

## 🐛 Troubleshooting

### Lỗi: SonarQube không khởi động

```bash
# Kiểm tra logs
docker logs sonarqube

# Kiểm tra kernel parameters
sysctl vm.max_map_count
# Phải >= 524288
```

### Lỗi: Connection refused trong CI

- Kiểm tra Security Group mở port 9000
- Kiểm tra SONAR_HOST_URL đúng format: `http://IP:9000`
- Ping từ GitHub Actions: `curl http://<IP>:9000/api/system/status`

### Lỗi: Unauthorized (401)

- Token đã hết hạn hoặc sai
- Tạo token mới trong SonarQube
- Cập nhật GitHub Secret `SONAR_TOKEN`

## 📚 Tài liệu tham khảo

- [SonarQube Documentation](https://docs.sonarqube.org/latest/)
- [SonarQube Docker Image](https://hub.docker.com/_/sonarqube)
- [Maven SonarQube Plugin](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-maven/)
