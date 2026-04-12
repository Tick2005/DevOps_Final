#!/bin/bash
# =============================================================================
# RELEASE-ELASTIC-IPS.SH - Release unused Elastic IPs
# =============================================================================
# Usage:
#   chmod +x release-elastic-ips.sh
#   ./release-elastic-ips.sh
#
# Purpose: Release all unassociated Elastic IPs to free up quota
# AWS Free Tier limit: 5 Elastic IPs per region
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
# LIST ALL ELASTIC IPs
# =============================================================================
print_header "2. Listing All Elastic IPs"

echo "Current Elastic IPs in $AWS_REGION:"
echo ""

aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --query 'Addresses[*].[PublicIp,AllocationId,AssociationId,Tags[?Key==`Name`].Value|[0]]' \
    --output table

# Count total EIPs
TOTAL_EIPS=$(aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --query 'length(Addresses)' \
    --output text)

print_info "Total Elastic IPs: $TOTAL_EIPS/5 (Free Tier limit)"

# =============================================================================
# FIND UNASSOCIATED ELASTIC IPs
# =============================================================================
print_header "3. Finding Unassociated Elastic IPs"

# Get list of unassociated EIPs
UNASSOCIATED_EIPS=$(aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --query 'Addresses[?AssociationId==null].[AllocationId,PublicIp]' \
    --output text)

if [ -z "$UNASSOCIATED_EIPS" ]; then
    print_success "No unassociated Elastic IPs found"
    echo ""
    print_warning "All Elastic IPs are in use. Options:"
    echo "  1. Terminate unused EC2 instances to free up EIPs"
    echo "  2. Manually release EIPs from AWS Console"
    echo "  3. Use different region"
    exit 0
fi

echo "Unassociated Elastic IPs:"
echo "$UNASSOCIATED_EIPS" | while read -r ALLOC_ID PUBLIC_IP; do
    echo "  - $PUBLIC_IP ($ALLOC_ID)"
done

UNASSOC_COUNT=$(echo "$UNASSOCIATED_EIPS" | wc -l)
print_info "Found $UNASSOC_COUNT unassociated Elastic IP(s)"

# =============================================================================
# CONFIRM RELEASE
# =============================================================================
echo ""
print_warning "This will release ALL unassociated Elastic IPs!"
echo ""
read -p "Do you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Operation cancelled"
    exit 0
fi

# =============================================================================
# RELEASE UNASSOCIATED ELASTIC IPs
# =============================================================================
print_header "4. Releasing Unassociated Elastic IPs"

RELEASED_COUNT=0
FAILED_COUNT=0

echo "$UNASSOCIATED_EIPS" | while read -r ALLOC_ID PUBLIC_IP; do
    if [ -n "$ALLOC_ID" ]; then
        print_info "Releasing: $PUBLIC_IP ($ALLOC_ID)"
        
        if aws ec2 release-address \
            --allocation-id "$ALLOC_ID" \
            --region "$AWS_REGION" 2>/dev/null; then
            print_success "Released: $PUBLIC_IP"
            RELEASED_COUNT=$((RELEASED_COUNT + 1))
        else
            print_error "Failed to release: $PUBLIC_IP"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    fi
done

# =============================================================================
# SUMMARY
# =============================================================================
print_header "5. Summary"

# Count remaining EIPs
REMAINING_EIPS=$(aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --query 'length(Addresses)' \
    --output text)

echo -e "${GREEN}"
cat << EOF
=============================================
     ELASTIC IP CLEANUP COMPLETED
=============================================

Before: $TOTAL_EIPS Elastic IPs
After:  $REMAINING_EIPS Elastic IPs
Available: $((5 - REMAINING_EIPS))/5

=============================================
EOF
echo -e "${NC}"

if [ "$REMAINING_EIPS" -lt 5 ]; then
    print_success "You now have available Elastic IP quota!"
    echo ""
    echo "You can now re-run Terraform:"
    echo "  cd terraform"
    echo "  terraform apply -var=\"key_name=productx-key\""
else
    print_warning "Still at Elastic IP limit!"
    echo ""
    echo "Options:"
    echo "  1. Terminate unused EC2 instances"
    echo "  2. Manually release EIPs from AWS Console"
    echo "  3. Contact AWS Support to increase limit"
fi

# =============================================================================
# LIST REMAINING ELASTIC IPs
# =============================================================================
print_header "6. Remaining Elastic IPs"

echo "Current Elastic IPs:"
aws ec2 describe-addresses \
    --region "$AWS_REGION" \
    --query 'Addresses[*].[PublicIp,InstanceId,Tags[?Key==`Name`].Value|[0]]' \
    --output table

echo ""
print_info "To manually release an EIP:"
echo "  aws ec2 release-address --allocation-id <alloc-id> --region $AWS_REGION"
