# TROUBLESHOOTING - XỬ LÝ SỰ CỐ

## 📋 MỤC LỤC

1. [Lỗi khi chạy setup.sh](#1-lỗi-khi-chạy-setupsh)
2. [Lỗi Python pip install](#2-lỗi-python-pip-install)
3. [Lỗi AWS credentials](#3-lỗi-aws-credentials)
4. [Lỗi Terraform](#4-lỗi-terraform)
5. [Lỗi Ansible](#5-lỗi-ansible)
6. [Lỗi Kubernetes](#6-lỗi-kubernetes)

---

## 1. Lỗi khi chạy setup.sh

### Issue: Permission denied

**Lỗi:**
```bash
bash: ./setup.sh: Permission denied
```

**Giải pháp:**
```bash
chmod +x setup.sh
./setup.sh
```

### Issue: Script không chạy trên Windows

**Lỗi:**
```
'\r': command not found
```

**Nguyên nhân:** File có line endings kiểu Windows (CRLF)

**Giải pháp:**
```bash
# Trên WSL/Linux
sudo apt-get install dos2unix
dos2unix setup.sh
./setup.sh

# Hoặc dùng sed
sed -i 's/\r$//' setup.sh
./setup.sh
```

---

## 2. Lỗi Python pip install

### Issue: externally-managed-environment

**Lỗi đầy đủ:**
```
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
```

**Nguyên nhân:** Python 3.11+ trên Debian/Ubuntu không cho phép cài package trực tiếp bằng pip để bảo vệ system Python.

**Giải pháp 1: Dùng apt (Khuyến nghị)**
```bash
sudo apt-get update
sudo apt-get install -y python3-boto3 python3-botocore
```

**Giải pháp 2: Dùng --break-system-packages**
```bash
pip3 install boto3 botocore --break-system-packages
```

⚠️ **Cảnh báo:** Chỉ dùng khi không có package trong apt repo

**Giải pháp 3: Dùng virtual environment**
```bash
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate
pip install boto3 botocore ansible
```

**Giải pháp 4: Dùng pipx**
```bash
sudo apt-get install -y pipx
pipx install ansible
pipx inject ansible boto3 botocore
```

**Verify installation:**
```bash
python3 -c "import boto3; print('boto3 OK')"
python3 -c "import botocore; print('botocore OK')"
```

---

## 3. Lỗi AWS credentials

### Issue: Unable to locate credentials

**Lỗi:**
```
Unable to locate credentials. You can configure credentials by running "aws configure".
```

**Giải pháp:**
```bash
aws configure
# Nhập:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: ap-southeast-1
# - Default output format: json
```

**Verify:**
```bash
aws sts get-caller-identity
```

### Issue: Invalid credentials

**Lỗi:**
```
An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation
```

**Nguyên nhân:** Access Key không đúng hoặc đã bị vô hiệu hóa

**Giải pháp:**
1. Kiểm tra Access Key trên AWS Console
2. Tạo Access Key mới nếu cần
3. Chạy lại `aws configure`

---

## 4. Lỗi Terraform

### Issue: Error acquiring the state lock

**Lỗi:**
```
Error: Error acquiring the state lock
```

**Nguyên nhân:** Terraform state bị lock (có thể do process trước bị gián đoạn)

**Giải pháp:**
```bash
cd terraform
terraform force-unlock <LOCK_ID>
```

### Issue: Resource already exists

**Lỗi:**
```
Error: resource already exists
```

**Giải pháp 1: Import resource**
```bash
terraform import aws_vpc.main vpc-xxxxx
```

**Giải pháp 2: Xóa resource thủ công**
```bash
# Xóa trên AWS Console hoặc
aws ec2 delete-vpc --vpc-id vpc-xxxxx
```

**Giải pháp 3: Xóa state và tạo lại**
```bash
cd terraform
rm -rf .terraform terraform.tfstate*
terraform init
terraform plan
```

### Issue: Insufficient permissions

**Lỗi:**
```
Error: error creating VPC: UnauthorizedOperation
```

**Giải pháp:**
- Kiểm tra IAM user có đủ quyền
- Gán policy `AdministratorAccess` hoặc các policies cần thiết

---

## 5. Lỗi Ansible

### Issue: Failed to connect to the host

**Lỗi:**
```
fatal: [db-nfs]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
```

**Nguyên nhân:**
- SSH key không đúng
- Security Group không cho phép SSH
- Instance chưa sẵn sàng

**Giải pháp:**
```bash
# 1. Kiểm tra SSH key
ls -la *.pem
chmod 400 productx-key.pem

# 2. Test SSH thủ công
ssh -i productx-key.pem ubuntu@<PUBLIC_IP>

# 3. Kiểm tra Security Group
# Đảm bảo port 22 mở cho IP của bạn

# 4. Đợi instance ready
aws ec2 describe-instance-status --instance-ids <INSTANCE_ID>
```

### Issue: Module not found

**Lỗi:**
```
ERROR! couldn't resolve module/action 'postgresql_db'
```

**Nguyên nhân:** Thiếu Python packages

**Giải pháp:**
```bash
# Trên control machine (máy chạy Ansible)
sudo apt-get install -y python3-psycopg2

# Hoặc
pip3 install psycopg2-binary --break-system-packages
```

### Issue: boto3 not found

**Lỗi:**
```
ERROR! couldn't resolve module/action 'ec2_instance'. This often indicates a misspelling, missing collection, or incorrect module path.
```

**Giải pháp:**
```bash
sudo apt-get install -y python3-boto3 python3-botocore
# Hoặc
pip3 install boto3 botocore --break-system-packages
```

---

## 6. Lỗi Kubernetes

### Issue: Unable to connect to the server

**Lỗi:**
```
Unable to connect to the server: dial tcp: lookup xxx on xxx: no such host
```

**Giải pháp:**
```bash
# Cấu hình lại kubectl
aws eks update-kubeconfig --region ap-southeast-1 --name productx-eks

# Verify
kubectl cluster-info
```

### Issue: error: You must be logged in to the server

**Lỗi:**
```
error: You must be logged in to the server (Unauthorized)
```

**Giải pháp:**
```bash
# Xóa kubeconfig cũ
rm ~/.kube/config

# Cấu hình lại
aws eks update-kubeconfig --region ap-southeast-1 --name productx-eks
```

### Issue: ImagePullBackOff

**Lỗi:**
```bash
kubectl get pods -n productx
# STATUS: ImagePullBackOff
```

**Nguyên nhân:** Docker image không tồn tại hoặc không có quyền pull

**Giải pháp:**
```bash
# 1. Kiểm tra image name
kubectl describe pod <pod-name> -n productx

# 2. Kiểm tra Docker Hub
# Đảm bảo image đã được push

# 3. Kiểm tra image tag
# Đảm bảo tag đúng trong deployment
```

### Issue: CrashLoopBackOff

**Lỗi:**
```bash
kubectl get pods -n productx
# STATUS: CrashLoopBackOff
```

**Giải pháp:**
```bash
# 1. Xem logs
kubectl logs <pod-name> -n productx

# 2. Xem previous logs
kubectl logs <pod-name> -n productx --previous

# 3. Xem events
kubectl describe pod <pod-name> -n productx

# 4. Kiểm tra ConfigMap và Secrets
kubectl get cm,secret -n productx
```

### Issue: PVC not bound

**Lỗi:**
```bash
kubectl get pvc -n productx
# STATUS: Pending
```

**Giải pháp:**
```bash
# 1. Kiểm tra PV
kubectl get pv

# 2. Kiểm tra NFS server
ssh -i productx-key.pem ubuntu@<DB_PUBLIC_IP>
sudo systemctl status nfs-kernel-server
sudo exportfs -v

# 3. Kiểm tra Security Group
# Đảm bảo port 2049 mở cho VPC CIDR

# 4. Xem events
kubectl describe pvc nfs-uploads-pvc -n productx
```

### Issue: ALB not created

**Lỗi:**
```bash
kubectl get ingress -n productx
# ADDRESS: <empty>
```

**Giải pháp:**
```bash
# 1. Kiểm tra AWS Load Balancer Controller
kubectl get deployment -n kube-system | grep aws-load-balancer

# 2. Xem logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# 3. Kiểm tra IAM policy
# Đảm bảo node role có policy cho ALB

# 4. Cài lại CRDs
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
```

---

## 🔧 Debug Commands

### Kiểm tra tổng quan
```bash
# Xem tất cả resources
kubectl get all -n productx

# Xem events
kubectl get events -n productx --sort-by='.lastTimestamp'

# Xem logs của tất cả pods
kubectl logs -l app=backend -n productx --tail=50
kubectl logs -l app=frontend -n productx --tail=50
```

### Kiểm tra network
```bash
# Từ pod, test kết nối database
kubectl exec -it <backend-pod> -n productx -- /bin/sh
nc -zv <DB_PRIVATE_IP> 5432

# Test DNS
nslookup backend-svc.productx.svc.cluster.local
```

### Kiểm tra resources
```bash
# Xem resource usage
kubectl top nodes
kubectl top pods -n productx

# Xem HPA
kubectl get hpa -n productx
kubectl describe hpa backend-hpa -n productx
```

---

## 📞 Liên hệ hỗ trợ

Nếu vẫn gặp vấn đề:
1. Kiểm tra logs chi tiết
2. Tham khảo [HUONG_DAN_CHI_TIET.md](./HUONG_DAN_CHI_TIET.md)
3. Tạo issue trên GitHub repository

---

**Cập nhật lần cuối:** 2024-01-10
