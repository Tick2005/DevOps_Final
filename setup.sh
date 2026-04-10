#!/bin/bash
# =============================================================================
# SETUP.SH - Automated EKS Infrastructure & Configuration Setup
# =============================================================================
# Chạy: chmod +x setup.sh && ./setup.sh
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() { echo -e "\n${BLUE}=============================================${NC}\n${BLUE}$1${NC}\n${BLUE}=============================================${NC}\n"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }

# =============================================================================
# INSTALL PREREQUISITES
# =============================================================================
print_header "1. Kiểm tra & Cài đặt Prerequisites"

NEED_INSTALL=false

# --- Check Terraform ---
if command -v terraform &> /dev/null; then
    print_success "Terraform: $(terraform version | head -n1)"
else
    print_warning "Terraform chưa được cài đặt. Đang cài đặt..."
    NEED_INSTALL=true
    
    sudo apt-get update -qq
    sudo apt-get install -y unzip wget
    
    cd /tmp
    wget -q https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
    unzip -o -q terraform_1.7.5_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    rm -f terraform_1.7.5_linux_amd64.zip
    cd - > /dev/null
    
    print_success "Terraform đã cài đặt: $(terraform version | head -n1)"
fi

# --- Check AWS CLI ---
if command -v aws &> /dev/null; then
    print_success "AWS CLI: $(aws --version | cut -d' ' -f1)"
else
    print_warning "AWS CLI chưa được cài đặt. Đang cài đặt..."
    NEED_INSTALL=true
    
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    cd /tmp
    unzip -q -o awscliv2.zip
    sudo ./aws/install --update
    cd - > /dev/null
    rm -rf /tmp/awscliv2.zip /tmp/aws
    
    print_success "AWS CLI đã cài đặt: $(aws --version | cut -d' ' -f1)"
fi

# --- Check Ansible ---
if command -v ansible &> /dev/null; then
    print_success "Ansible: $(ansible --version | head -n1)"
else
    print_warning "Ansible chưa được cài đặt. Đang cài đặt..."
    NEED_INSTALL=true
    
    sudo apt-get update -qq
    sudo apt-get install -y ansible python3-pip
    pip3 install boto3 botocore
    
    print_success "Ansible đã cài đặt: $(ansible --version | head -n1)"
fi

# --- Check kubectl ---
if command -v kubectl &> /dev/null; then
    print_success "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    print_warning "kubectl chưa được cài đặt. Đang cài đặt..."
    NEED_INSTALL=true
    
    cd /tmp
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    cd - > /dev/null
    
    print_success "kubectl đã cài đặt: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

if [ "$NEED_INSTALL" = true ]; then
    echo ""
    print_success "Tất cả prerequisites đã được cài đặt!"
fi

# =============================================================================
# CHECK AWS CREDENTIALS
# =============================================================================
print_header "2. Kiểm tra AWS Credentials"

# Check if AWS credentials are already configured
AWS_CONFIGURED=false
if aws sts get-caller-identity &> /dev/null; then
    AWS_CONFIGURED=true
    AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
    AWS_USER=$(aws sts get-caller-identity --query "Arn" --output text | rev | cut -d'/' -f1 | rev)
    AWS_REGION=$(aws configure get region || echo "ap-southeast-1")
    
    echo ""
    print_success "AWS credentials đã được cấu hình:"
    echo "  Account: $AWS_ACCOUNT"
    echo "  User/Role: $AWS_USER"
    echo "  Region: $AWS_REGION"
    echo ""
    
    read -p "Bạn có muốn thay đổi cấu hình AWS? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        AWS_CONFIGURED=false
    fi
fi

# Configure AWS credentials if needed
if [ "$AWS_CONFIGURED" = false ]; then
    echo ""
    print_info "Nhập thông tin AWS credentials:"
    echo ""
    
    # Read AWS Access Key ID
    read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        print_error "AWS Access Key ID không được để trống!"
        exit 1
    fi
    
    # Read AWS Secret Access Key (hidden input)
    read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo ""
    if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        print_error "AWS Secret Access Key không được để trống!"
        exit 1
    fi
    
    # Read AWS Region with default
    read -p "AWS Region [ap-southeast-1]: " AWS_REGION
    AWS_REGION=${AWS_REGION:-ap-southeast-1}
    
    # Configure AWS CLI
    echo ""
    print_info "Đang cấu hình AWS CLI..."
    
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
    aws configure set region "$AWS_REGION"
    aws configure set output json
    
    # Verify credentials
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
        AWS_USER=$(aws sts get-caller-identity --query "Arn" --output text | rev | cut -d'/' -f1 | rev)
        
        echo ""
        print_success "AWS credentials đã được cấu hình thành công!"
        echo "  Account: $AWS_ACCOUNT"
        echo "  User/Role: $AWS_USER"
        echo "  Region: $AWS_REGION"
    else
        print_error "AWS credentials không hợp lệ!"
        echo "Vui lòng kiểm tra lại Access Key ID và Secret Access Key"
        exit 1
    fi
else
    # Use existing AWS region
    AWS_REGION=$(aws configure get region || echo "ap-southeast-1")
fi

# =============================================================================
# LOAD .ENV FILE
# =============================================================================
print_header "3. Đọc cấu hình từ .env"

# Check if .env exists
ENV_EXISTS=false
if [ -f ".env" ]; then
    ENV_EXISTS=true
    
    # Load existing .env
    export $(grep -v '^#' .env | grep -v '^\s*$' | xargs)
    
    echo ""
    print_success "File .env đã tồn tại với cấu hình:"
    echo "  AWS_KEY_NAME: ${AWS_KEY_NAME:-<chưa cấu hình>}"
    echo "  DB_PASSWORD: ${DB_PASSWORD:0:3}***${DB_PASSWORD: -3}"
    echo "  DOMAIN_NAME: ${DOMAIN_NAME:-<không có>}"
    echo "  ENABLE_HTTPS: ${ENABLE_HTTPS:-false}"
    echo ""
    
    read -p "Bạn có muốn thay đổi cấu hình .env? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ENV_EXISTS=false
    fi
fi

# Configure .env if needed
if [ "$ENV_EXISTS" = false ]; then
    echo ""
    print_info "Nhập thông tin cấu hình:"
    echo ""
    
    # Read AWS_KEY_NAME
    read -p "AWS SSH Key Name (không có .pem) [${AWS_KEY_NAME}]: " NEW_AWS_KEY_NAME
    AWS_KEY_NAME=${NEW_AWS_KEY_NAME:-$AWS_KEY_NAME}
    
    if [ -z "$AWS_KEY_NAME" ]; then
        print_error "AWS_KEY_NAME không được để trống!"
        exit 1
    fi
    
    # Read DB_PASSWORD
    read -s -p "Database Password [${DB_PASSWORD:-SecurePassword123!}]: " NEW_DB_PASSWORD
    echo ""
    DB_PASSWORD=${NEW_DB_PASSWORD:-${DB_PASSWORD:-SecurePassword123!}}
    
    # Read DOMAIN_NAME (optional)
    read -p "Domain Name (để trống nếu không dùng HTTPS) [${DOMAIN_NAME}]: " NEW_DOMAIN_NAME
    DOMAIN_NAME=${NEW_DOMAIN_NAME:-$DOMAIN_NAME}
    
    # Read ENABLE_HTTPS
    if [ -n "$DOMAIN_NAME" ]; then
        read -p "Enable HTTPS? (true/false) [${ENABLE_HTTPS:-false}]: " NEW_ENABLE_HTTPS
        ENABLE_HTTPS=${NEW_ENABLE_HTTPS:-${ENABLE_HTTPS:-false}}
    else
        ENABLE_HTTPS="false"
    fi
    
    # Read SONAR_ORGANIZATION (optional)
    read -p "SonarCloud Organization [${SONAR_ORGANIZATION}]: " NEW_SONAR_ORGANIZATION
    SONAR_ORGANIZATION=${NEW_SONAR_ORGANIZATION:-$SONAR_ORGANIZATION}
    
    # Read SONAR_PROJECT_KEY (optional)
    read -p "SonarCloud Project Key [${SONAR_PROJECT_KEY}]: " NEW_SONAR_PROJECT_KEY
    SONAR_PROJECT_KEY=${NEW_SONAR_PROJECT_KEY:-$SONAR_PROJECT_KEY}
    
    # Read SONAR_TOKEN (optional)
    read -s -p "SonarCloud Token [${SONAR_TOKEN:0:10}***]: " NEW_SONAR_TOKEN
    echo ""
    SONAR_TOKEN=${NEW_SONAR_TOKEN:-$SONAR_TOKEN}
    
    # Read DOCKER_USERNAME (optional)
    read -p "Docker Hub Username [${DOCKER_USERNAME}]: " NEW_DOCKER_USERNAME
    DOCKER_USERNAME=${NEW_DOCKER_USERNAME:-$DOCKER_USERNAME}
    
    # Save to .env file
    echo ""
    print_info "Đang lưu cấu hình vào .env..."
    
    cat > .env << EOF
# =============================================================================
# .ENV - Cấu hình môi trường (Auto-generated by setup.sh)
# =============================================================================

# AWS Configuration
AWS_KEY_NAME=${AWS_KEY_NAME}
AWS_REGION=${AWS_REGION}

# Database Configuration
DB_PASSWORD=${DB_PASSWORD}
DB_NAME_PROD=productx_db
DB_NAME_STAGING=productx_db_staging
DB_USER_PROD=productx_user
DB_USER_STAGING=productx_staging_user

# SonarCloud Configuration
SONAR_ORGANIZATION=${SONAR_ORGANIZATION}
SONAR_PROJECT_KEY=${SONAR_PROJECT_KEY}
SONAR_TOKEN=${SONAR_TOKEN}

# Docker Hub
DOCKER_USERNAME=${DOCKER_USERNAME}

# Domain & HTTPS (Optional)
DOMAIN_NAME=${DOMAIN_NAME}
ENABLE_HTTPS=${ENABLE_HTTPS}
EOF
    
    print_success "Cấu hình đã được lưu vào .env"
fi

# Validate required vars
if [ -z "$AWS_KEY_NAME" ] || [ "$AWS_KEY_NAME" = "your-key-name-here" ]; then
    print_error "AWS_KEY_NAME chưa được cấu hình!"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD="SecurePassword123!"
    print_warning "DB_PASSWORD không có, dùng mặc định: $DB_PASSWORD"
fi

# Set defaults for optional vars
DOMAIN_NAME=${DOMAIN_NAME:-""}
ENABLE_HTTPS=${ENABLE_HTTPS:-"false"}

echo ""
print_success "Cấu hình hiện tại:"
echo "  AWS_KEY_NAME: $AWS_KEY_NAME"
echo "  AWS_REGION: $AWS_REGION"
echo "  DB_PASSWORD: ${DB_PASSWORD:0:3}***${DB_PASSWORD: -3}"
if [ -n "$DOMAIN_NAME" ]; then
    echo "  DOMAIN_NAME: $DOMAIN_NAME"
    echo "  ENABLE_HTTPS: $ENABLE_HTTPS"
else
    echo "  HTTPS: Disabled"
fi

# Check SSH key file
SSH_KEY_PATH="${AWS_KEY_NAME}.pem"
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo ""
    print_warning "Không tìm thấy SSH key: $SSH_KEY_PATH"
    echo ""
    print_info "Bạn cần tạo SSH Key Pair trên AWS Console:"
    echo "  1. Vào AWS Console → EC2 → Key Pairs"
    echo "  2. Click 'Create key pair'"
    echo "  3. Name: $AWS_KEY_NAME"
    echo "  4. Key pair type: RSA"
    echo "  5. Private key format: .pem"
    echo "  6. Click 'Create key pair'"
    echo "  7. File .pem sẽ được tải về"
    echo "  8. Di chuyển file vào thư mục project:"
    echo "     mv ~/Downloads/${AWS_KEY_NAME}.pem $(pwd)/"
    echo ""
    
    read -p "Nhấn Enter sau khi đã tạo và di chuyển file .pem vào thư mục project..."
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_error "Vẫn không tìm thấy file $SSH_KEY_PATH"
        exit 1
    fi
fi

# Fix permission cho SSH key
chmod 400 "$SSH_KEY_PATH" 2>/dev/null || true
print_success "SSH Key: $SSH_KEY_PATH"

# =============================================================================
# TERRAFORM - DEPLOY INFRASTRUCTURE
# =============================================================================
print_header "4. Terraform - Deploy EKS Infrastructure"

cd terraform

print_info "Initializing Terraform..."
terraform init -upgrade

print_info "Planning infrastructure..."
terraform plan \
  -var="key_name=$AWS_KEY_NAME" \
  -var="domain_name=$DOMAIN_NAME" \
  -var="enable_https=$ENABLE_HTTPS" \
  -out=tfplan

echo ""
read -p "Tiếp tục apply infrastructure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Hủy deployment"
    exit 0
fi

print_info "Applying infrastructure... (15-20 phút)"
if [ "$ENABLE_HTTPS" = "true" ] && [ -n "$DOMAIN_NAME" ]; then
    print_warning "HTTPS enabled - Certificate validation có thể mất 5-15 phút"
    print_info "Đảm bảo domain nameserver đã trỏ về Route53!"
fi
terraform apply tfplan

# Get outputs
print_info "Lấy thông tin từ Terraform outputs..."

if ! EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null); then
    print_error "Không lấy được Terraform outputs. Kiểm tra lại terraform apply!"
    exit 1
fi

EKS_CLUSTER_ENDPOINT=$(terraform output -raw eks_cluster_endpoint)
DB_NFS_PUBLIC_IP=$(terraform output -raw database_public_ip)
DB_NFS_PRIVATE_IP=$(terraform output -raw database_private_ip)
KUBECONFIG_COMMAND=$(terraform output -raw configure_kubectl)

print_success "EKS Cluster: $EKS_CLUSTER_NAME"
print_success "DB+NFS IP: $DB_NFS_PUBLIC_IP"

cd ..

# =============================================================================
# GENERATE ANSIBLE INVENTORY
# =============================================================================
print_header "5. Tạo Ansible Inventory"

SSH_KEY_ABSOLUTE_PATH="$(pwd)/${SSH_KEY_PATH}"

cat > ansible/inventory/hosts.ini << EOF
# Auto-generated by setup.sh at $(date)

[database]
db-nfs ansible_host=${DB_NFS_PUBLIC_IP} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3

[nfs_server]
db-nfs ansible_host=${DB_NFS_PUBLIC_IP} ansible_user=ubuntu ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_ssh_private_key_file=${SSH_KEY_ABSOLUTE_PATH}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

print_success "Ansible inventory created"

# =============================================================================
# WAIT FOR SSH
# =============================================================================
print_header "6. Đợi EC2 instances sẵn sàng"

print_info "Waiting for SSH to be ready (max 20s per server)..."

# Wait for DB+NFS
for i in {1..4}; do
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -i "$SSH_KEY_PATH" ubuntu@"$DB_NFS_PUBLIC_IP" "echo 'OK'" &>/dev/null; then
        print_success "DB+NFS server SSH ready!"
        break
    fi
    [ $i -lt 4 ] && sleep 5
done

# =============================================================================
# RUN ANSIBLE
# =============================================================================
print_header "7. Ansible - Cấu hình Servers"

cd ansible

print_info "Testing Ansible connectivity..."
ansible all -i inventory/hosts.ini -m ping

echo ""
read -p "Tiếp tục chạy Ansible playbooks? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Bỏ qua Ansible configuration"
    cd ..
else
    print_info "Running Ansible playbooks..."
    
    ansible-playbook -i inventory/hosts.ini playbooks/site.yml \
      -e "db_password=${DB_PASSWORD}"
    cd ..
fi

# =============================================================================
# KUBERNETES BASE SETUP
# =============================================================================
print_header "8. Kubernetes - Setup Base Resources"

# Configure kubectl
print_info "Configuring kubectl..."
eval "$KUBECONFIG_COMMAND"

if kubectl cluster-info &>/dev/null; then
    print_success "kubectl configured successfully!"
else
    print_error "Cannot connect to EKS cluster"
    exit 1
fi

# Wait for nodes to be ready
print_info "Waiting for EKS nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || {
    print_warning "Nodes not ready yet, continuing anyway..."
}

# Install AWS Load Balancer Controller CRDs
print_info "Installing AWS Load Balancer Controller CRDs..."
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master" || {
    print_warning "Failed to install ALB Controller CRDs, may already exist"
}

print_info "Applying Kubernetes base resources..."

# Apply namespace
kubectl apply -f kubernetes/namespace.yaml

# Apply ConfigMap
echo "📝 Applying ConfigMap..."
cat kubernetes/configmap.yaml | \
  sed "s|PLACEHOLDER_DB_HOST|${DB_NFS_PRIVATE_IP}|g" | \
  sed "s|PLACEHOLDER_NFS_SERVER|${DB_NFS_PRIVATE_IP}|g" | \
  kubectl apply -f -

# Apply Secrets
echo "🔐 Applying Secrets..."
cat kubernetes/secrets.yaml | \
  sed "s|PLACEHOLDER_DB_PASSWORD|${DB_PASSWORD}|g" | \
  kubectl apply -f -

# Apply NFS PV
echo "💾 Applying NFS PersistentVolume..."
cat kubernetes/nfs-pv.yaml | \
  sed "s|PLACEHOLDER_NFS_SERVER|${DB_NFS_PRIVATE_IP}|g" | \
  kubectl apply -f -

# Wait for PVC
echo "⏳ Waiting for NFS PVC to be bound..."
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/nfs-uploads-pvc -n productx --timeout=60s || {
    print_warning "PVC not bound yet, check NFS server"
}

# Apply HPA
kubectl apply -f kubernetes/hpa.yaml

# Apply Ingress
echo "🌐 Applying Ingress..."
kubectl apply -f kubernetes/ingress.yaml

print_success "Kubernetes base resources applied!"
echo ""
print_warning "LƯU Ý: Deployments sẽ được apply bởi CD pipeline (cần Docker images)"

# Wait for ALB to be created
echo ""
print_info "Đợi ALB được tạo (có thể mất 2-3 phút)..."
sleep 30

ALB_URL=""
for i in {1..12}; do
    ALB_URL=$(kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$ALB_URL" ]; then
        print_success "ALB đã được tạo: $ALB_URL"
        break
    fi
    echo "  Đang đợi ALB... ($i/12)"
    sleep 10
done

if [ -z "$ALB_URL" ]; then
    print_warning "ALB chưa sẵn sàng. Kiểm tra sau bằng: kubectl get ingress -n productx"
fi

# =============================================================================
# SUMMARY
# =============================================================================
print_header "🎉 SETUP HOÀN TẤT!"

echo -e "${GREEN}"
cat << EOF
=============================================
           THÔNG TIN HỆ THỐNG
=============================================

☸️  EKS CLUSTER:
   - Name: ${EKS_CLUSTER_NAME}
   - Endpoint: ${EKS_CLUSTER_ENDPOINT}
   - Region: ${AWS_REGION}
   
   Connect kubectl:
   ${KUBECONFIG_COMMAND}

💾 DATABASE + NFS SERVER:
   - Public IP: ${DB_NFS_PUBLIC_IP}
   - Private IP: ${DB_NFS_PRIVATE_IP}
   - PostgreSQL: ${DB_NFS_PRIVATE_IP}:5432
   - NFS: ${DB_NFS_PRIVATE_IP}:/srv/nfs/uploads
   - SSH: ssh -i ${SSH_KEY_PATH} ubuntu@${DB_NFS_PUBLIC_IP}

=============================================
EOF
echo -e "${NC}"

echo -e "${YELLOW}"
cat << EOF
=============================================
      📋 GITHUB ACTIONS SECRETS
=============================================

Vào GitHub repo → Settings → Secrets → Actions

✅ SECRETS BẮT BUỘC (11 secrets):

1. AWS_ACCESS_KEY_ID
   Giá trị: <your-aws-access-key-id>
   Lấy từ: IAM User → Security credentials

2. AWS_SECRET_ACCESS_KEY
   Giá trị: <your-aws-secret-access-key>
   Lấy từ: IAM User → Security credentials

3. AWS_REGION
   Giá trị: ${AWS_REGION}

4. EKS_CLUSTER_NAME
   Giá trị: ${EKS_CLUSTER_NAME}

5. DATA_SERVER_IP
   Giá trị: ${DB_NFS_PRIVATE_IP}
   ⚠️  LƯU Ý: Dùng PRIVATE IP, không phải Public IP!

6. DB_PASSWORD
   Giá trị: ${DB_PASSWORD}

7. DOCKER_USERNAME
   Giá trị: <your-dockerhub-username>
   Lấy từ: https://hub.docker.com

8. DOCKER_PASSWORD
   Giá trị: <your-dockerhub-password>
   Lấy từ: Docker Hub → Account Settings → Security

9. SONAR_TOKEN
   Giá trị: <your-sonarcloud-token>
   Lấy từ: SonarCloud → My Account → Security → Generate Token

10. SONAR_ORGANIZATION
    Giá trị: <your-sonarcloud-org>
    Lấy từ: SonarCloud → Organization Key

11. SONAR_PROJECT_KEY
    Giá trị: <your-sonarcloud-project-key>
    Lấy từ: SonarCloud → Project Key

💡 HƯỚNG DẪN THÊM SECRETS:
   1. Mở GitHub repository trong browser
   2. Click Settings → Secrets and variables → Actions
   3. Click "New repository secret"
   4. Nhập Name và Value
   5. Click "Add secret"
   6. Lặp lại cho tất cả 11 secrets

📖 Chi tiết về SonarCloud: xem file SONARCLOUD_SETUP.md

=============================================
EOF
echo -e "${NC}"

echo -e "${GREEN}"
cat << EOF
=============================================
           📝 NEXT STEPS
=============================================

1️⃣  Cấu hình SonarCloud (nếu chưa có):
   - Truy cập: https://sonarcloud.io
   - Đăng nhập bằng GitHub
   - Tạo Organization và Project
   - Generate Token
   - Xem chi tiết: SONARCLOUD_SETUP.md

2️⃣  Thêm GitHub Secrets:
   - Vào repo → Settings → Secrets and variables → Actions
   - Thêm tất cả 11 secrets ở trên
   - ⚠️  Đặc biệt chú ý DATA_SERVER_IP phải là PRIVATE IP

3️⃣  Deploy ứng dụng:
   - Push code lên GitHub: git push origin main
   - CI/CD sẽ tự động chạy
   - Xem tiến trình: GitHub → Actions tab

4️⃣  Kiểm tra deployment:
   - kubectl get pods -n productx
   - kubectl get ingress -n productx
EOF

if [ -n "$ALB_URL" ]; then
cat << EOF
   - Truy cập ứng dụng: http://${ALB_URL}
EOF
else
cat << EOF
   - Lấy ALB URL: kubectl get ingress -n productx
EOF
fi

cat << EOF

5️⃣  Kiểm tra logs (nếu có lỗi):
   - kubectl logs -f deployment/backend -n productx
   - kubectl logs -f deployment/frontend -n productx

=============================================
EOF
echo -e "${NC}"

print_info "Để xem lại kubectl command: echo '${KUBECONFIG_COMMAND}'"
print_info "Để test Ansible: cd ansible && ansible all -i inventory/hosts.ini -m ping"

if [ -n "$ALB_URL" ]; then
    echo ""
    print_success "🎉 Application Load Balancer URL: http://${ALB_URL}"
    print_info "Sau khi deploy xong, truy cập URL trên để xem ứng dụng"
fi
