#!/bin/bash
# =============================================================================
# FIX-IAM-PERMISSIONS.SH - Automatically add required IAM policies
# =============================================================================
# Usage:
#   chmod +x fix-iam-permissions.sh
#   ./fix-iam-permissions.sh <iam-user-name>
#
# Example:
#   ./fix-iam-permissions.sh devops-final-ci
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
# CHECK ARGUMENTS
# =============================================================================
if [ -z "$1" ]; then
    print_error "Missing IAM user name!"
    echo ""
    echo "Usage: ./fix-iam-permissions.sh <iam-user-name>"
    echo "Example: ./fix-iam-permissions.sh devops-final-ci"
    exit 1
fi

IAM_USER=$1

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

# =============================================================================
# CHECK IAM USER EXISTS
# =============================================================================
print_header "2. Checking IAM User"

if ! aws iam get-user --user-name "$IAM_USER" &> /dev/null; then
    print_error "IAM user '$IAM_USER' not found!"
    echo ""
    echo "Available users:"
    aws iam list-users --query "Users[].UserName" --output table
    exit 1
fi

print_success "IAM user found: $IAM_USER"

# =============================================================================
# ATTACH REQUIRED POLICIES
# =============================================================================
print_header "3. Attaching Required IAM Policies"

# List of required policies
POLICIES=(
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
    "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"
)

POLICY_NAMES=(
    "CloudWatchLogsFullAccess"
    "AWSKeyManagementServicePowerUser"
    "AWSCertificateManagerFullAccess"
)

for i in "${!POLICIES[@]}"; do
    POLICY_ARN="${POLICIES[$i]}"
    POLICY_NAME="${POLICY_NAMES[$i]}"
    
    print_info "Attaching: $POLICY_NAME"
    
    if aws iam attach-user-policy \
        --user-name "$IAM_USER" \
        --policy-arn "$POLICY_ARN" 2>/dev/null; then
        print_success "$POLICY_NAME attached"
    else
        print_warning "$POLICY_NAME already attached or failed"
    fi
done

# =============================================================================
# VERIFY POLICIES
# =============================================================================
print_header "4. Verifying Attached Policies"

echo "Current attached policies for $IAM_USER:"
aws iam list-attached-user-policies --user-name "$IAM_USER" --query "AttachedPolicies[].PolicyName" --output table

# =============================================================================
# TEST PERMISSIONS
# =============================================================================
print_header "5. Testing Permissions"

print_info "Testing ACM permissions..."
if aws acm list-certificates --region ap-southeast-1 &> /dev/null; then
    print_success "ACM permissions OK"
else
    print_warning "ACM permissions may still be missing"
fi

print_info "Testing KMS permissions..."
if aws kms list-keys --region ap-southeast-1 &> /dev/null; then
    print_success "KMS permissions OK"
else
    print_warning "KMS permissions may still be missing"
fi

print_info "Testing CloudWatch Logs permissions..."
if aws logs describe-log-groups --region ap-southeast-1 --max-items 1 &> /dev/null; then
    print_success "CloudWatch Logs permissions OK"
else
    print_warning "CloudWatch Logs permissions may still be missing"
fi

# =============================================================================
# SUMMARY
# =============================================================================
print_header "🎉 COMPLETED!"

echo -e "${GREEN}"
cat << EOF
=============================================
     IAM PERMISSIONS UPDATED
=============================================

User: $IAM_USER
Account: $AWS_ACCOUNT

Policies attached:
  ✅ CloudWatchLogsFullAccess
  ✅ AWSKeyManagementServicePowerUser
  ✅ AWSCertificateManagerFullAccess

=============================================
EOF
echo -e "${NC}"

echo ""
print_header "📝 NEXT STEPS"

echo ""
echo -e "${YELLOW}1. Update AWS credentials in GitHub Secrets (if needed)${NC}"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo ""
echo -e "${YELLOW}2. Re-run Terraform or GitHub Actions workflow${NC}"
echo "   cd terraform"
echo "   terraform plan -var=\"key_name=productx-key\""
echo "   terraform apply -var=\"key_name=productx-key\""
echo ""
echo -e "${YELLOW}3. If still getting errors, check:${NC}"
echo "   - IAM user has correct permissions"
echo "   - AWS credentials are up to date"
echo "   - Region is correct (ap-southeast-1)"
echo ""
print_success "IAM permissions fix completed!"
