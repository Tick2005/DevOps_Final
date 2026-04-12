# Hướng dẫn cấu hình GitHub Secrets

## 📋 Mục lục
1. [Tổng quan](#tổng-quan)
2. [Danh sách Secrets cần thiết](#danh-sách-secrets-cần-thiết)
3. [Hướng dẫn tìm và tạo từng Secret](#hướng-dẫn-tìm-và-tạo-từng-secret)
4. [Cách thêm Secrets vào GitHub](#cách-thêm-secrets-vào-github)
5. [Kiểm tra và xác nhận](#kiểm-tra-và-xác-nhận)

---

## Tổng quan

GitHub Secrets là nơi lưu trữ các thông tin nhạy cảm (credentials, passwords, tokens) được sử dụng trong CI/CD pipeline. Các secrets này sẽ được mã hóa và chỉ có thể truy cập trong GitHub Actions workflows.

**⚠️ LƯU Ý QUAN TRỌNG:**
- KHÔNG BAO GIỜ commit secrets vào code
- KHÔNG share secrets qua email/chat
- Thay đổi secrets ngay lập tức nếu bị lộ

---

## Danh sách Secrets cần thiết

### 🔐 Secrets bắt buộc (Required)

| Secret Name | Mô tả | Ví dụ |
|------------|-------|-------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_KEY_NAME` | Tên SSH key pair trên AWS | `devops-final-key` |
| `EC2_SSH_PRIVATE_KEY` | Private key (.pem) để SSH vào EC2 | `-----BEGIN RSA PRIVATE KEY-----...` |
| `EKS_CLUSTER_NAME` | Tên EKS cluster | `productx-eks-cluster` |
| `DB_PASSWORD` | Password cho PostgreSQL | `SecurePassword123!` |
| `DOCKER_USERNAME` | Docker Hub username | `yourusername` |
| `DOCKER_PASSWORD` | Docker Hub password/token | `dckr_pat_...` |
| `TF_BACKEND_BUCKET` | S3 bucket cho Terraform state | `productx-tfstate-1234567890` |

### 🌐 Secrets tùy chọn (Optional - cho HTTPS)

| Secret Name | Mô tả | Ví dụ |
|------------|-------|-------|
| `DOMAIN_NAME` | Tên miền của bạn | `example.com` |

---

## Hướng dẫn tìm và tạo từng Secret

### 1. AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY

**Cách tạo:**

#### Bước 1: Đăng nhập AWS Console
- Truy cập: https://console.aws.amazon.com/
- Đăng nhập với tài khoản AWS của bạn

#### Bước 2: Tạo IAM User mới (nếu chưa có)
```
1. Vào IAM Console: https://console.aws.amazon.com/iam/
2. Click "Users" → "Create user"
3. User name: devops-final-ci
4. Click "Next"
5. Chọn "Attach policies directly"
6. Thêm các policies sau:
   - AmazonEC2FullAccess
   - AmazonEKSClusterPolicy
   - AmazonEKSWorkerNodePolicy
   - AmazonVPCFullAccess
   - IAMFullAccess (hoặc IAMReadOnlyAccess nếu không cần tạo roles)
   - AmazonS3FullAccess
   - AmazonDynamoDBFullAccess
7. Click "Create user"
```

#### Bước 3: Tạo Access Key
```
1. Click vào user vừa tạo
2. Tab "Security credentials"
3. Scroll xuống "Access keys"
4. Click "Create access key"
5. Chọn "Command Line Interface (CLI)"
6. Check "I understand..." → Next
7. (Optional) Thêm description: "GitHub Actions CI/CD"
8. Click "Create access key"
```

#### Bước 4: Lưu credentials
```
✅ AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
✅ AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

⚠️ LƯU Ý: Secret Access Key chỉ hiển thị 1 lần duy nhất!
   Nếu mất, phải tạo lại access key mới.
```

**Cách tìm (nếu đã có):**
- Access Key ID: Có thể xem trong IAM Console → Users → Security credentials
- Secret Access Key: KHÔNG THỂ xem lại, phải tạo mới nếu mất

---

### 2. AWS_KEY_NAME

**Cách tạo:**

#### Bước 1: Tạo Key Pair trên AWS
```
1. Vào EC2 Console: https://console.aws.amazon.com/ec2/
2. Chọn Region: ap-southeast-1 (Singapore)
3. Sidebar → "Network & Security" → "Key Pairs"
4. Click "Create key pair"
5. Name: devops-final-key
6. Key pair type: RSA
7. Private key file format: .pem
8. Click "Create key pair"
9. File .pem sẽ tự động download
```

#### Bước 2: Lưu thông tin
```
✅ AWS_KEY_NAME: devops-final-key (KHÔNG có .pem)
✅ File: devops-final-key.pem (lưu an toàn, cần cho bước sau)
```

**Cách tìm (nếu đã có):**
- EC2 Console → Key Pairs → Xem danh sách key pairs
- Tên key pair (không có .pem) chính là giá trị cần điền

---

### 3. EC2_SSH_PRIVATE_KEY

**Cách lấy:**

Đây là nội dung file `.pem` bạn đã download ở bước trên.

#### Bước 1: Mở file .pem
```bash
# Linux/Mac
cat devops-final-key.pem

# Windows (PowerShell)
Get-Content devops-final-key.pem
```

#### Bước 2: Copy toàn bộ nội dung
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAr1234567890abcdefghijklmnopqrstuvwxyz...
(nhiều dòng)
...xyz987654321
-----END RSA PRIVATE KEY-----
```

**⚠️ LƯU Ý:**
- Copy TOÀN BỘ nội dung, bao gồm cả dòng BEGIN và END
- Giữ nguyên format, không thêm/bớt dòng trống
- Đây là private key, TUYỆT ĐỐI không share

---

### 4. EKS_CLUSTER_NAME

**Cách tạo:**

Tên này bạn tự đặt khi chạy Terraform. Khuyến nghị:
```
✅ EKS_CLUSTER_NAME: productx-eks-cluster
```

**Cách tìm (nếu đã tạo cluster):**
```bash
# Dùng AWS CLI
aws eks list-clusters --region ap-southeast-1

# Hoặc vào EKS Console
https://console.aws.amazon.com/eks/
```

---

### 5. DB_PASSWORD

**Cách tạo:**

Tự đặt password mạnh cho PostgreSQL database.

**Yêu cầu:**
- Tối thiểu 12 ký tự
- Có chữ hoa, chữ thường, số, ký tự đặc biệt
- KHÔNG chứa ký tự đặc biệt: `@`, `"`, `'`, `/`, `\`

**Ví dụ:**
```
✅ SecurePassword123!
✅ MyDb#Pass2024$Strong
✅ P@ssw0rd!Complex#2024
```

**Tạo password ngẫu nhiên:**
```bash
# Linux/Mac
openssl rand -base64 16

# PowerShell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | % {[char]$_})
```

---

### 6. DOCKER_USERNAME & DOCKER_PASSWORD

**Cách tạo:**

#### Bước 1: Tạo tài khoản Docker Hub (nếu chưa có)
```
1. Truy cập: https://hub.docker.com/signup
2. Điền thông tin đăng ký
3. Xác nhận email
```

#### Bước 2: Lấy username
```
✅ DOCKER_USERNAME: yourusername (username khi đăng ký)
```

#### Bước 3: Tạo Access Token (KHUYẾN NGHỊ thay vì dùng password)
```
1. Đăng nhập Docker Hub: https://hub.docker.com/
2. Click avatar → "Account Settings"
3. Tab "Security"
4. Click "New Access Token"
5. Description: "GitHub Actions CI/CD"
6. Access permissions: "Read, Write, Delete"
7. Click "Generate"
8. Copy token (chỉ hiển thị 1 lần!)
```

```
✅ DOCKER_PASSWORD: dckr_pat_1234567890abcdefghijklmnop
```

**⚠️ LƯU Ý:**
- Dùng Access Token thay vì password (an toàn hơn)
- Token chỉ hiển thị 1 lần, lưu ngay
- Có thể revoke token bất cứ lúc nào

---

### 7. TF_BACKEND_BUCKET

**Cách tạo:**

Chạy script bootstrap để tự động tạo S3 bucket và DynamoDB table.

#### Bước 1: Cấu hình AWS CLI
```bash
aws configure
# AWS Access Key ID: (nhập AWS_ACCESS_KEY_ID)
# AWS Secret Access Key: (nhập AWS_SECRET_ACCESS_KEY)
# Default region name: ap-southeast-1
# Default output format: json
```

#### Bước 2: Chạy bootstrap script
```bash
cd DevOps_Final
chmod +x bootstrap-backend.sh
./bootstrap-backend.sh
```

#### Bước 3: Lưu bucket name từ output
```
Script sẽ hiển thị:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Copy value này:

productx-tfstate-1234567890
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ TF_BACKEND_BUCKET: productx-tfstate-1234567890
```

**Cách tìm (nếu đã tạo):**
```bash
# List tất cả S3 buckets
aws s3 ls | grep tfstate

# Hoặc vào S3 Console
https://s3.console.aws.amazon.com/s3/buckets
```

---

### 8. DOMAIN_NAME (Optional)

**Cách tạo:**

Nếu bạn muốn sử dụng HTTPS với domain riêng:

#### Option 1: Mua domain từ Hostinger
```
1. Truy cập: https://www.hostinger.com/domain-name-search
2. Tìm và mua domain (VD: myapp.online)
3. Sau khi mua, vào "Domain" → "DNS/Nameservers"
```

#### Option 2: Mua domain từ Namecheap
```
1. Truy cập: https://www.namecheap.com/
2. Tìm và mua domain
3. Vào "Domain List" → Click domain → "Advanced DNS"
```

#### Option 3: Sử dụng domain miễn phí
```
- Freenom: https://www.freenom.com/ (.tk, .ml, .ga, .cf, .gq)
- Dot.tk: http://www.dot.tk/
```

**Giá trị cần điền:**
```
✅ DOMAIN_NAME: myapp.online (KHÔNG có www, KHÔNG có https://)
```

**⚠️ LƯU Ý:**
- Nếu KHÔNG có domain, BỎ QUA secret này
- Hệ thống vẫn chạy được với HTTP và ALB URL
- HTTPS chỉ hoạt động khi có domain

---

## Cách thêm Secrets vào GitHub

### Bước 1: Truy cập Repository Settings
```
1. Mở repository trên GitHub
2. Click tab "Settings"
3. Sidebar → "Secrets and variables" → "Actions"
```

### Bước 2: Thêm từng Secret
```
1. Click "New repository secret"
2. Name: (nhập tên secret, VD: AWS_ACCESS_KEY_ID)
3. Secret: (paste giá trị)
4. Click "Add secret"
5. Lặp lại cho tất cả secrets
```

### Bước 3: Xác nhận danh sách
Sau khi thêm xong, bạn sẽ thấy danh sách:
```
✅ AWS_ACCESS_KEY_ID
✅ AWS_SECRET_ACCESS_KEY
✅ AWS_KEY_NAME
✅ EC2_SSH_PRIVATE_KEY
✅ EKS_CLUSTER_NAME
✅ DB_PASSWORD
✅ DOCKER_USERNAME
✅ DOCKER_PASSWORD
✅ TF_BACKEND_BUCKET
⚪ DOMAIN_NAME (optional)
```

---

## Kiểm tra và xác nhận

### Test AWS Credentials
```bash
# Test locally trước khi thêm vào GitHub
export AWS_ACCESS_KEY_ID="your-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
aws sts get-caller-identity
```

Kết quả mong đợi:
```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/devops-final-ci"
}
```

### Test Docker Credentials
```bash
echo "your-docker-password" | docker login -u your-username --password-stdin
```

Kết quả mong đợi:
```
Login Succeeded
```

### Test SSH Key
```bash
chmod 400 devops-final-key.pem
ssh-keygen -y -f devops-final-key.pem
```

Kết quả mong đợi: Hiển thị public key

---

## Troubleshooting

### ❌ Lỗi: "AWS credentials not configured"
**Nguyên nhân:** AWS_ACCESS_KEY_ID hoặc AWS_SECRET_ACCESS_KEY sai/thiếu

**Giải pháp:**
1. Kiểm tra lại credentials trong IAM Console
2. Tạo lại access key nếu cần
3. Cập nhật secrets trên GitHub

### ❌ Lỗi: "Permission denied (publickey)"
**Nguyên nhân:** EC2_SSH_PRIVATE_KEY sai format hoặc không khớp với AWS_KEY_NAME

**Giải pháp:**
1. Kiểm tra file .pem có đúng key pair không
2. Copy lại toàn bộ nội dung file .pem (bao gồm BEGIN/END)
3. Đảm bảo AWS_KEY_NAME khớp với tên key pair trên AWS

### ❌ Lỗi: "TF_BACKEND_BUCKET not found"
**Nguyên nhân:** Chưa chạy bootstrap-backend.sh hoặc bucket name sai

**Giải pháp:**
1. Chạy lại bootstrap-backend.sh
2. Copy đúng bucket name từ output
3. Cập nhật secret TF_BACKEND_BUCKET

### ❌ Lỗi: "Docker authentication failed"
**Nguyên nhân:** DOCKER_USERNAME hoặc DOCKER_PASSWORD sai

**Giải pháp:**
1. Test login locally: `docker login`
2. Tạo lại Access Token trên Docker Hub
3. Cập nhật DOCKER_PASSWORD với token mới

---

## Checklist cuối cùng

Trước khi chạy CI/CD, đảm bảo:

- [ ] Đã thêm đủ 9 secrets bắt buộc vào GitHub
- [ ] Test AWS credentials locally thành công
- [ ] Test Docker login thành công
- [ ] File .pem đã được copy đúng format
- [ ] Đã chạy bootstrap-backend.sh và lấy bucket name
- [ ] EKS_CLUSTER_NAME đã đặt tên rõ ràng
- [ ] DB_PASSWORD đủ mạnh và không có ký tự đặc biệt cấm
- [ ] (Optional) DOMAIN_NAME đã được cấu hình nếu muốn HTTPS

---

## Liên hệ hỗ trợ

Nếu gặp vấn đề, kiểm tra:
1. GitHub Actions logs: Repository → Actions → Click vào workflow run
2. AWS CloudWatch logs
3. Terraform state: S3 bucket → tfstate file

**Tài liệu tham khảo:**
- AWS IAM: https://docs.aws.amazon.com/IAM/latest/UserGuide/
- Docker Hub: https://docs.docker.com/docker-hub/
- GitHub Secrets: https://docs.github.com/en/actions/security-guides/encrypted-secrets
