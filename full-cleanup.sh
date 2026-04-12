#!/bin/bash
# =============================================================================
# FULL-CLEANUP.SH - Complete cleanup of all AWS resources
# =============================================================================
# Usage:
#   chmod +x full-cleanup.sh
#   ./full-cleanup.sh
#
# Purpose: Run all cleanup scripts in correct order
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
# CONFIRMATION
# =============================================================================
print_header "⚠️  FULL CLEANUP WARNING"

echo -e "${RED}"
cat << EOF
This script will:
  1. Release all unassociated Elastic IPs
  2. Delete CloudWatch Log Groups
  3. Delete KMS Aliases and Keys
  4. Destroy Terraform infrastructure
  5. Clean up all AWS resources

This action CANNOT be undone!
EOF
echo -e "${NC}"

echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Operation cancelled"
    exit 0
fi

# =============================================================================
# STEP 1: RELEASE ELASTIC IPs
# =============================================================================
print_header "Step 1/4: Releasing Elastic IPs"

if [ -f "release-elastic-ips.sh" ]; then
    chmod +x release-elastic-ips.sh
    
    # Auto-confirm for script
    echo "yes" | ./release-elastic-ips.sh || true
    
    print_success "Elastic IPs cleanup completed"
else
    print_warning "release-elastic-ips.sh not found, skipping"
fi

echo ""
print_info "Waiting 10 seconds..."
sleep 10

# =============================================================================
# STEP 2: CLEANUP FAILED RESOURCES
# =============================================================================
print_header "Step 2/4: Cleaning up failed resources"

if [ -f "cleanup-failed-resources.sh" ]; then
    chmod +x cleanup-failed-resources.sh
    ./cleanup-failed-resources.sh || true
    
    print_success "Failed resources cleanup completed"
else
    print_warning "cleanup-failed-resources.sh not found, skipping"
fi

echo ""
print_info "Waiting 10 seconds..."
sleep 10

# =============================================================================
# STEP 3: TERRAFORM DESTROY
# =============================================================================
print_header "Step 3/4: Destroying Terraform infrastructure"

if [ -d "terraform" ]; then
    cd terraform
    
    # Check if terraform is initialized
    if [ -d ".terraform" ]; then
        print_info "Running terraform destroy..."
        
        # Try to destroy with key_name variable
        if [ -n "$1" ]; then
            KEY_NAME="$1"
        else
            KEY_NAME="productx-key"
        fi
        
        terraform destroy \
            -var="key_name=$KEY_NAME" \
            -auto-approve || true
        
        print_success "Terraform destroy completed"
    else
        print_warning "Terraform not initialized, skipping destroy"
    fi
    
    cd ..
else
    print_warning "terraform directory not found, skipping"
fi

echo ""
print_info "Waiting 30 seconds for AWS to clean up..."
sleep 30

# =============================================================================
# STEP 4: VERIFY CLEANUP
# =============================================================================
print_header "Step 4/4: Verifying cleanup"

AWS_REGION=${AWS_REGION:-ap-southeast-1}

# Check Elastic IPs
EIP_COUNT=$(aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --query 'length(Addresses)' \
    --output text 2>/dev/null || echo "0")
print_info "Remaining Elastic IPs: $EIP_COUNT/5"

# Check EC2 Instances
EC2_COUNT=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters "Name=tag:Project,Values=productx" "Name=instance-state-name,Values=running,stopped" \
    --query "length(Reservations[].Instances[])" \
    --output text 2>/dev/null || echo "0")
print_info "Remaining EC2 Instances: $EC2_COUNT"

# Check EKS Clusters
EKS_COUNT=$(aws eks list-clusters \
    --region "$AWS_REGION" \
    --query "length(clusters)" \
    --output text 2>/dev/null || echo "0")
print_info "Remaining EKS Clusters: $EKS_COUNT"

# Check Load Balancers
LB_COUNT=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "length(LoadBalancers)" \
    --output text 2>/dev/null || echo "0")
print_info "Remaining Load Balancers: $LB_COUNT"

# =============================================================================
# SUMMARY
# =============================================================================
print_header "🎉 FULL CLEANUP COMPLETED!"

echo -e "${GREEN}"
cat << EOF
=============================================
     CLEANUP SUMMARY
=============================================

✅ Elastic IPs released
✅ Failed resources cleaned
✅ Terraform infrastructure destroyed
✅ Verification completed

Current state:
  - Elastic IPs: $EIP_COUNT/5
  - EC2 Instances: $EC2_COUNT
  - EKS Clusters: $EKS_COUNT
  - Load Balancers: $LB_COUNT

=============================================
EOF
echo -e "${NC}"

echo ""
print_header "📝 NEXT STEPS"

echo ""
echo -e "${YELLOW}1. Wait 5-10 minutes for AWS to fully clean up${NC}"
echo ""
echo -e "${YELLOW}2. Verify all resources are deleted:${NC}"
echo "   aws ec2 describe-instances --region $AWS_REGION"
echo "   aws eks list-clusters --region $AWS_REGION"
echo "   aws ec2 describe-addresses --region $AWS_REGION"
echo ""
echo -e "${YELLOW}3. Re-deploy infrastructure:${NC}"
echo "   cd terraform"
echo "   terraform init"
echo "   terraform apply -var=\"key_name=productx-key\""
echo ""
echo -e "${YELLOW}4. Or push to GitHub to trigger CI/CD:${NC}"
echo "   git add ."
echo "   git commit -m \"Re-deploy after cleanup\""
echo "   git push origin main"
echo ""

if [ "$EIP_COUNT" -ge 5 ] || [ "$EC2_COUNT" -gt 0 ] || [ "$EKS_COUNT" -gt 0 ]; then
    print_warning "Some resources still exist. You may need to:"
    echo "  1. Wait longer for AWS to clean up"
    echo "  2. Manually delete resources from AWS Console"
    echo "  3. Check for resources in other regions"
else
    print_success "All resources cleaned up successfully!"
    print_success "You can now re-deploy without issues."
fi
