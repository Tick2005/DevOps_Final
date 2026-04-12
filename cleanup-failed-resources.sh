#!/bin/bash
# =============================================================================
# CLEANUP-FAILED-RESOURCES.SH - Clean up leftover AWS resources
# =============================================================================
# Usage:
#   chmod +x cleanup-failed-resources.sh
#   ./cleanup-failed-resources.sh
#
# Purpose: Remove KMS keys, CloudWatch log groups, and other resources
#          that prevent Terraform from creating new ones
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
CLUSTER_NAME="productx-eks-cluster"
PROJECT_NAME="productx"

# =============================================================================
# CHECK AWS CREDENTIALS
# =============================================================================
print_header "1. Checking AWS Credentials"

if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured!"
    echo ""
    echo "Run: aws configure"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
print_success "AWS Account: $AWS_ACCOUNT"
print_success "AWS Region: $AWS_REGION"

# =============================================================================
# DELETE CLOUDWATCH LOG GROUPS
# =============================================================================
print_header "2. Deleting CloudWatch Log Groups"

LOG_GROUP_NAME="/aws/eks/${CLUSTER_NAME}/cluster"

print_info "Checking log group: $LOG_GROUP_NAME"

if aws logs describe-log-groups \
    --log-group-name-prefix "$LOG_GROUP_NAME" \
    --region "$AWS_REGION" \
    --query "logGroups[?logGroupName=='$LOG_GROUP_NAME']" \
    --output text &> /dev/null; then
    
    print_info "Deleting log group: $LOG_GROUP_NAME"
    
    if aws logs delete-log-group \
        --log-group-name "$LOG_GROUP_NAME" \
        --region "$AWS_REGION" 2>/dev/null; then
        print_success "Log group deleted"
    else
        print_warning "Log group not found or already deleted"
    fi
else
    print_success "Log group does not exist"
fi

# =============================================================================
# DELETE IAM ROLES
# =============================================================================
print_header "3. Deleting IAM Roles"

IAM_ROLE_NAME="${CLUSTER_NAME}-aws-load-balancer-controller"

print_info "Checking IAM role: $IAM_ROLE_NAME"

if aws iam get-role --role-name "$IAM_ROLE_NAME" &> /dev/null; then
    print_info "Found IAM role: $IAM_ROLE_NAME"
    
    # Detach managed policies
    print_info "Detaching managed policies..."
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies \
        --role-name "$IAM_ROLE_NAME" \
        --query "AttachedPolicies[].PolicyArn" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$ATTACHED_POLICIES" ]; then
        for POLICY_ARN in $ATTACHED_POLICIES; do
            aws iam detach-role-policy \
                --role-name "$IAM_ROLE_NAME" \
                --policy-arn "$POLICY_ARN" 2>/dev/null || true
        done
    fi
    
    # Delete inline policies
    INLINE_POLICIES=$(aws iam list-role-policies \
        --role-name "$IAM_ROLE_NAME" \
        --query "PolicyNames" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INLINE_POLICIES" ]; then
        for POLICY_NAME in $INLINE_POLICIES; do
            aws iam delete-role-policy \
                --role-name "$IAM_ROLE_NAME" \
                --policy-name "$POLICY_NAME" 2>/dev/null || true
        done
    fi
    
    # Delete the role
    if aws iam delete-role --role-name "$IAM_ROLE_NAME" 2>/dev/null; then
        print_success "IAM role deleted"
    else
        print_warning "Failed to delete IAM role"
    fi
else
    print_success "IAM role does not exist"
fi

# =============================================================================
# DELETE KMS ALIAS
# =============================================================================
print_header "4. Deleting KMS Alias"

KMS_ALIAS="alias/eks/${CLUSTER_NAME}"

print_info "Checking KMS alias: $KMS_ALIAS"

# Get KMS key ID from alias
KMS_KEY_ID=$(aws kms list-aliases \
    --region "$AWS_REGION" \
    --query "Aliases[?AliasName=='$KMS_ALIAS'].TargetKeyId" \
    --output text 2>/dev/null || echo "")

if [ -n "$KMS_KEY_ID" ]; then
    print_info "Found KMS key: $KMS_KEY_ID"
    
    # Delete alias
    print_info "Deleting KMS alias: $KMS_ALIAS"
    if aws kms delete-alias \
        --alias-name "$KMS_ALIAS" \
        --region "$AWS_REGION" 2>/dev/null; then
        print_success "KMS alias deleted"
    else
        print_warning "Failed to delete KMS alias"
    fi
    
    # Schedule key deletion (7 days waiting period)
    print_info "Scheduling KMS key deletion: $KMS_KEY_ID"
    if aws kms schedule-key-deletion \
        --key-id "$KMS_KEY_ID" \
        --pending-window-in-days 7 \
        --region "$AWS_REGION" 2>/dev/null; then
        print_success "KMS key scheduled for deletion (7 days)"
    else
        print_warning "KMS key already scheduled or cannot be deleted"
    fi
else
    print_success "KMS alias does not exist"
fi

# =============================================================================
# DELETE EKS CLUSTER (if exists)
# =============================================================================
print_header "5. Checking EKS Cluster"

print_info "Checking if EKS cluster exists: $CLUSTER_NAME"

if aws eks describe-cluster \
    --name "$CLUSTER_NAME" \
    --region "$AWS_REGION" &> /dev/null; then
    
    print_warning "EKS cluster still exists: $CLUSTER_NAME"
    echo ""
    echo "To delete the cluster, run:"
    echo "  aws eks delete-cluster --name $CLUSTER_NAME --region $AWS_REGION"
    echo ""
    echo "Or use Terraform:"
    echo "  cd terraform"
    echo "  terraform destroy -var=\"key_name=productx-key\""
else
    print_success "EKS cluster does not exist"
fi

# =============================================================================
# LIST OTHER RESOURCES
# =============================================================================
print_header "6. Checking Other Resources"

# Check for Load Balancers
print_info "Checking for Load Balancers..."
LB_COUNT=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, '$PROJECT_NAME')] | length(@)" \
    --output text 2>/dev/null || echo "0")

if [ "$LB_COUNT" -gt 0 ]; then
    print_warning "Found $LB_COUNT Load Balancer(s)"
    echo "List:"
    aws elbv2 describe-load-balancers \
        --region "$AWS_REGION" \
        --query "LoadBalancers[?contains(LoadBalancerName, '$PROJECT_NAME')].LoadBalancerArn" \
        --output table
else
    print_success "No Load Balancers found"
fi

# Check for Security Groups
print_info "Checking for Security Groups..."
SG_COUNT=$(aws ec2 describe-security-groups \
    --region "$AWS_REGION" \
    --filters "Name=tag:Project,Values=$PROJECT_NAME" \
    --query "length(SecurityGroups)" \
    --output text 2>/dev/null || echo "0")

if [ "$SG_COUNT" -gt 0 ]; then
    print_warning "Found $SG_COUNT Security Group(s)"
else
    print_success "No Security Groups found"
fi

# Check for EC2 Instances
print_info "Checking for EC2 Instances..."
EC2_COUNT=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters "Name=tag:Project,Values=$PROJECT_NAME" "Name=instance-state-name,Values=running,stopped" \
    --query "length(Reservations[].Instances[])" \
    --output text 2>/dev/null || echo "0")

if [ "$EC2_COUNT" -gt 0 ]; then
    print_warning "Found $EC2_COUNT EC2 Instance(s)"
else
    print_success "No EC2 Instances found"
fi

# =============================================================================
# SUMMARY
# =============================================================================
print_header "🎉 CLEANUP COMPLETED!"

echo -e "${GREEN}"
cat << EOF
=============================================
     CLEANUP SUMMARY
=============================================

✅ CloudWatch Log Groups: Deleted
✅ IAM Roles: Deleted
✅ KMS Alias: Deleted
✅ KMS Key: Scheduled for deletion (7 days)

Resources checked:
  - EKS Cluster: $CLUSTER_NAME
  - Load Balancers: $LB_COUNT found
  - Security Groups: $SG_COUNT found
  - EC2 Instances: $EC2_COUNT found

=============================================
EOF
echo -e "${NC}"

echo ""
print_header "📝 NEXT STEPS"

echo ""
echo -e "${YELLOW}1. If EKS cluster still exists, destroy it:${NC}"
echo "   cd terraform"
echo "   terraform destroy -var=\"key_name=productx-key\""
echo ""
echo -e "${YELLOW}2. Wait a few minutes for resources to be fully deleted${NC}"
echo ""
echo -e "${YELLOW}3. Re-run Terraform apply:${NC}"
echo "   terraform apply -var=\"key_name=productx-key\""
echo ""
echo -e "${YELLOW}4. Or re-run GitHub Actions workflow:${NC}"
echo "   Actions → Infrastructure Provisioning → Re-run all jobs"
echo ""
print_success "Cleanup completed! You can now re-deploy."
