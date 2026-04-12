#!/bin/bash
# =============================================================================
# CHECK-DEPLOYMENT-STATUS.SH - Check current deployment status
# =============================================================================
# Usage:
#   chmod +x check-deployment-status.sh
#   ./check-deployment-status.sh
#
# Purpose: Quick check of what's deployed and what's missing
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
# CONFIGURATION
# =============================================================================
AWS_REGION=${AWS_REGION:-ap-southeast-1}
PROJECT_NAME="productx"
CLUSTER_NAME="productx-eks-cluster"

# =============================================================================
# CHECK AWS CREDENTIALS
# =============================================================================
print_header "1. AWS Credentials"

if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured!"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
AWS_USER=$(aws sts get-caller-identity --query "Arn" --output text | rev | cut -d'/' -f1 | rev)

print_success "Account: $AWS_ACCOUNT"
print_success "User: $AWS_USER"
print_success "Region: $AWS_REGION"

# =============================================================================
# CHECK TERRAFORM STATE
# =============================================================================
print_header "2. Terraform State"

if [ -d "terraform/.terraform" ]; then
    print_success "Terraform initialized"
    
    cd terraform
    
    if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
        RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l)
        print_info "Resources in state: $RESOURCE_COUNT"
        
        if [ "$RESOURCE_COUNT" -gt 0 ]; then
            print_success "Terraform state exists"
            echo ""
            echo "Resources:"
            terraform state list | head -20
            if [ "$RESOURCE_COUNT" -gt 20 ]; then
                echo "... and $((RESOURCE_COUNT - 20)) more"
            fi
        else
            print_warning "Terraform state is empty"
        fi
    else
        print_warning "No Terraform state file found"
    fi
    
    cd ..
else
    print_warning "Terraform not initialized"
fi

# =============================================================================
# CHECK AWS RESOURCES
# =============================================================================
print_header "3. AWS Resources"

# VPC
print_info "Checking VPC..."
VPC_COUNT=$(aws ec2 describe-vpcs \
    --region "$AWS_REGION" \
    --filters "Name=tag:Project,Values=$PROJECT_NAME" \
    --query "length(Vpcs)" \
    --output text 2>/dev/null || echo "0")

if [ "$VPC_COUNT" -gt 0 ]; then
    print_success "VPC: $VPC_COUNT found"
    VPC_ID=$(aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=$PROJECT_NAME" \
        --query "Vpcs[0].VpcId" \
        --output text)
    echo "  VPC ID: $VPC_ID"
else
    print_error "VPC: Not found"
fi

# EKS Cluster
print_info "Checking EKS Cluster..."
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
    print_success "EKS Cluster: $CLUSTER_NAME exists"
    
    EKS_STATUS=$(aws eks describe-cluster \
        --name "$CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --query "cluster.status" \
        --output text)
    echo "  Status: $EKS_STATUS"
    
    EKS_VERSION=$(aws eks describe-cluster \
        --name "$CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --query "cluster.version" \
        --output text)
    echo "  Version: $EKS_VERSION"
else
    print_error "EKS Cluster: Not found"
fi

# EC2 Instances
print_info "Checking EC2 Instances..."
EC2_COUNT=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters "Name=tag:Project,Values=$PROJECT_NAME" "Name=instance-state-name,Values=running,stopped,pending" \
    --query "length(Reservations[].Instances[])" \
    --output text 2>/dev/null || echo "0")

if [ "$EC2_COUNT" -gt 0 ]; then
    print_success "EC2 Instances: $EC2_COUNT found"
    aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --filters "Name=tag:Project,Values=$PROJECT_NAME" "Name=instance-state-name,Values=running,stopped,pending" \
        --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType,Tags[?Key=='Name'].Value|[0]]" \
        --output table
else
    print_error "EC2 Instances: Not found"
fi

# Elastic IPs
print_info "Checking Elastic IPs..."
EIP_COUNT=$(aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --query 'length(Addresses)' \
    --output text 2>/dev/null || echo "0")

print_info "Elastic IPs: $EIP_COUNT/5 (Free Tier limit)"

if [ "$EIP_COUNT" -gt 0 ]; then
    aws ec2 describe-addresses \
        --region "$AWS_REGION" \
        --query 'Addresses[*].[PublicIp,InstanceId,Tags[?Key==`Name`].Value|[0]]' \
        --output table
fi

# Load Balancers
print_info "Checking Load Balancers..."
LB_COUNT=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "length(LoadBalancers)" \
    --output text 2>/dev/null || echo "0")

if [ "$LB_COUNT" -gt 0 ]; then
    print_success "Load Balancers: $LB_COUNT found"
else
    print_warning "Load Balancers: Not found"
fi

# =============================================================================
# CHECK KUBERNETES
# =============================================================================
print_header "4. Kubernetes Resources"

# Try to configure kubectl
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
    print_info "Configuring kubectl..."
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null || true
    
    if kubectl cluster-info &> /dev/null; then
        print_success "kubectl configured and connected"
        
        # Check namespaces
        if kubectl get namespace productx &> /dev/null; then
            print_success "Namespace 'productx' exists"
            
            # Check pods
            POD_COUNT=$(kubectl get pods -n productx --no-headers 2>/dev/null | wc -l)
            print_info "Pods in productx: $POD_COUNT"
            
            if [ "$POD_COUNT" -gt 0 ]; then
                echo ""
                kubectl get pods -n productx
            fi
            
            # Check services
            echo ""
            print_info "Services:"
            kubectl get svc -n productx 2>/dev/null || echo "  No services found"
            
            # Check ingress
            echo ""
            print_info "Ingress:"
            kubectl get ingress -n productx 2>/dev/null || echo "  No ingress found"
        else
            print_warning "Namespace 'productx' not found"
        fi
    else
        print_warning "kubectl not configured or cluster not accessible"
    fi
else
    print_warning "EKS cluster not found, skipping kubectl checks"
fi

# =============================================================================
# SUMMARY
# =============================================================================
print_header "📊 DEPLOYMENT SUMMARY"

echo -e "${CYAN}"
cat << EOF
AWS Resources:
  - VPC: $VPC_COUNT
  - EKS Cluster: $([ -n "$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" 2>/dev/null)" ] && echo "✅ Exists" || echo "❌ Not found")
  - EC2 Instances: $EC2_COUNT
  - Elastic IPs: $EIP_COUNT/5
  - Load Balancers: $LB_COUNT

Terraform:
  - Initialized: $([ -d "terraform/.terraform" ] && echo "✅ Yes" || echo "❌ No")
  - State exists: $([ -f "terraform/terraform.tfstate" ] && echo "✅ Yes" || echo "❌ No")

Kubernetes:
  - Cluster accessible: $(kubectl cluster-info &> /dev/null && echo "✅ Yes" || echo "❌ No")
  - Namespace exists: $(kubectl get namespace productx &> /dev/null && echo "✅ Yes" || echo "❌ No")
  - Pods running: $(kubectl get pods -n productx --no-headers 2>/dev/null | wc -l)
EOF
echo -e "${NC}"

# =============================================================================
# RECOMMENDATIONS
# =============================================================================
print_header "💡 RECOMMENDATIONS"

if [ "$VPC_COUNT" -eq 0 ]; then
    echo "❌ No VPC found - Infrastructure not deployed"
    echo "   Run: cd terraform && terraform apply -var=\"key_name=productx-key\""
elif ! aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
    echo "⚠️  VPC exists but EKS cluster not found"
    echo "   Deployment may be in progress or failed"
    echo "   Check: GitHub Actions logs or run terraform apply"
elif ! kubectl cluster-info &> /dev/null; then
    echo "⚠️  EKS cluster exists but kubectl not configured"
    echo "   Run: aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION"
elif ! kubectl get namespace productx &> /dev/null; then
    echo "⚠️  Cluster accessible but namespace not found"
    echo "   Run: kubectl apply -f kubernetes/namespace.yaml"
else
    echo "✅ Infrastructure looks good!"
    echo ""
    echo "Next steps:"
    echo "  1. Check application: kubectl get pods -n productx"
    echo "  2. Get ALB URL: kubectl get ingress -n productx"
    echo "  3. View logs: kubectl logs -f deployment/backend -n productx"
fi

echo ""
print_info "For detailed troubleshooting, see: TROUBLESHOOTING_QUICK_REFERENCE.md"
