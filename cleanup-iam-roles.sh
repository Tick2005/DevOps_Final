#!/bin/bash
# =============================================================================
# CLEANUP-IAM-ROLES.SH - Clean up leftover IAM roles
# =============================================================================
# Usage:
#   chmod +x cleanup-iam-roles.sh
#   ./cleanup-iam-roles.sh
#
# Purpose: Remove IAM roles that prevent Terraform from creating new ones
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
PROJECT_NAME="productx"
CLUSTER_NAME="productx-eks-cluster"

# IAM Roles to clean up
IAM_ROLES=(
    "${CLUSTER_NAME}-aws-load-balancer-controller"
    "${CLUSTER_NAME}-cluster"
    "${CLUSTER_NAME}-node"
)

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
# LIST IAM ROLES
# =============================================================================
print_header "2. Listing IAM Roles"

echo "Searching for ProductX IAM roles..."
echo ""

FOUND_ROLES=()

for ROLE_NAME in "${IAM_ROLES[@]}"; do
    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        print_warning "Found: $ROLE_NAME"
        FOUND_ROLES+=("$ROLE_NAME")
    fi
done

# Also search for roles with productx prefix
ADDITIONAL_ROLES=$(aws iam list-roles \
    --query "Roles[?contains(RoleName, '$PROJECT_NAME')].RoleName" \
    --output text 2>/dev/null || echo "")

if [ -n "$ADDITIONAL_ROLES" ]; then
    for ROLE in $ADDITIONAL_ROLES; do
        if [[ ! " ${FOUND_ROLES[@]} " =~ " ${ROLE} " ]]; then
            print_warning "Found: $ROLE"
            FOUND_ROLES+=("$ROLE")
        fi
    done
fi

if [ ${#FOUND_ROLES[@]} -eq 0 ]; then
    print_success "No IAM roles found to clean up"
    exit 0
fi

echo ""
print_info "Total roles found: ${#FOUND_ROLES[@]}"

# =============================================================================
# CONFIRM DELETION
# =============================================================================
echo ""
print_warning "This will delete the following IAM roles:"
for ROLE in "${FOUND_ROLES[@]}"; do
    echo "  - $ROLE"
done

echo ""
read -p "Do you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Operation cancelled"
    exit 0
fi

# =============================================================================
# DELETE IAM ROLES
# =============================================================================
print_header "3. Deleting IAM Roles"

for ROLE_NAME in "${FOUND_ROLES[@]}"; do
    print_info "Processing role: $ROLE_NAME"
    
    # Detach managed policies
    print_info "  Detaching managed policies..."
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies \
        --role-name "$ROLE_NAME" \
        --query "AttachedPolicies[].PolicyArn" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$ATTACHED_POLICIES" ]; then
        for POLICY_ARN in $ATTACHED_POLICIES; do
            print_info "    Detaching: $POLICY_ARN"
            aws iam detach-role-policy \
                --role-name "$ROLE_NAME" \
                --policy-arn "$POLICY_ARN" 2>/dev/null || true
        done
    fi
    
    # Delete inline policies
    print_info "  Deleting inline policies..."
    INLINE_POLICIES=$(aws iam list-role-policies \
        --role-name "$ROLE_NAME" \
        --query "PolicyNames" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INLINE_POLICIES" ]; then
        for POLICY_NAME in $INLINE_POLICIES; do
            print_info "    Deleting: $POLICY_NAME"
            aws iam delete-role-policy \
                --role-name "$ROLE_NAME" \
                --policy-name "$POLICY_NAME" 2>/dev/null || true
        done
    fi
    
    # Delete instance profiles
    print_info "  Removing from instance profiles..."
    INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role \
        --role-name "$ROLE_NAME" \
        --query "InstanceProfiles[].InstanceProfileName" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INSTANCE_PROFILES" ]; then
        for PROFILE_NAME in $INSTANCE_PROFILES; do
            print_info "    Removing from: $PROFILE_NAME"
            aws iam remove-role-from-instance-profile \
                --instance-profile-name "$PROFILE_NAME" \
                --role-name "$ROLE_NAME" 2>/dev/null || true
        done
    fi
    
    # Delete the role
    print_info "  Deleting role..."
    if aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null; then
        print_success "Deleted: $ROLE_NAME"
    else
        print_error "Failed to delete: $ROLE_NAME"
    fi
    
    echo ""
done

# =============================================================================
# VERIFY DELETION
# =============================================================================
print_header "4. Verifying Deletion"

REMAINING=0
for ROLE_NAME in "${FOUND_ROLES[@]}"; do
    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        print_warning "Still exists: $ROLE_NAME"
        REMAINING=$((REMAINING + 1))
    fi
done

if [ $REMAINING -eq 0 ]; then
    print_success "All IAM roles deleted successfully"
else
    print_warning "$REMAINING role(s) still exist"
fi

# =============================================================================
# SUMMARY
# =============================================================================
print_header "🎉 CLEANUP COMPLETED!"

echo -e "${GREEN}"
cat << EOF
=============================================
     IAM ROLES CLEANUP SUMMARY
=============================================

Roles processed: ${#FOUND_ROLES[@]}
Roles deleted: $((${#FOUND_ROLES[@]} - REMAINING))
Roles remaining: $REMAINING

=============================================
EOF
echo -e "${NC}"

echo ""
print_header "📝 NEXT STEPS"

echo ""
echo -e "${YELLOW}1. Wait 1-2 minutes for IAM changes to propagate${NC}"
echo ""
echo -e "${YELLOW}2. Re-run Terraform:${NC}"
echo "   cd terraform"
echo "   terraform apply -var=\"key_name=productx-key\""
echo ""
echo -e "${YELLOW}3. Or re-run GitHub Actions workflow:${NC}"
echo "   Actions → Infrastructure Provisioning → Re-run all jobs"
echo ""

if [ $REMAINING -gt 0 ]; then
    print_warning "Some roles could not be deleted. Possible reasons:"
    echo "  1. Role is still attached to resources"
    echo "  2. Insufficient permissions"
    echo "  3. Role is being used by AWS service"
    echo ""
    echo "Try:"
    echo "  1. Run full-cleanup.sh to remove all resources first"
    echo "  2. Then run this script again"
else
    print_success "All IAM roles cleaned up successfully!"
    print_success "You can now re-deploy without IAM role conflicts."
fi
