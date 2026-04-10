#!/bin/bash
# =============================================================================
# CLEANUP.SH - Clean up ALL Kubernetes resources before Terraform destroy
# =============================================================================
# Chạy: chmod +x cleanup.sh && ./cleanup.sh
# =============================================================================

set -e

# Disable AWS CLI pager
export AWS_PAGER=""

REGION="ap-southeast-1"
CLUSTER_NAME="productx-eks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}🧹 KUBERNETES CLEANUP SCRIPT${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "${CYAN}Strategy: Delete ALL Kubernetes resources first${NC}"
echo -e "${CYAN}Then let Terraform destroy handle infrastructure${NC}"
echo ""

# =============================================================================
# STEP 0: Install kubectl if not present
# =============================================================================
if ! command -v kubectl &> /dev/null; then
  echo -e "${YELLOW}kubectl not found. Installing...${NC}"
  cd /tmp
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  cd - > /dev/null
  echo -e "${GREEN}✅ kubectl installed${NC}"
fi

# Configure kubectl
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${YELLOW}Configuring kubectl for EKS cluster...${NC}"
  aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION 2>/dev/null || true
fi

# =============================================================================
# STEP 1: Delete ALL Kubernetes resources
# =============================================================================
echo ""
echo -e "${YELLOW}=== Step 1: Deleting Kubernetes Resources ===${NC}"

if kubectl cluster-info &>/dev/null; then
  echo "🗑️  Deleting Ingress resources (triggers ALB deletion)..."
  kubectl delete ingress --all -n productx 2>/dev/null || echo "  No ingress in productx"
  
  echo "🗑️  Deleting LoadBalancer services..."
  kubectl delete svc --all -n productx 2>/dev/null || echo "  No services in productx"
  
  echo -e "${GREEN}✅ Kubernetes resources deleted${NC}"
  echo "⏳ Waiting 60 seconds for ALB deletion to start..."
  sleep 60
else
  echo -e "${YELLOW}⚠️  kubectl not configured, skipping Kubernetes cleanup${NC}"
fi

# =============================================================================
# STEP 2: Force delete ALL ALBs
# =============================================================================
echo ""
echo -e "${YELLOW}=== Step 2: Force deleting ALL ALBs ===${NC}"

ALB_ARNS=$(aws elbv2 describe-load-balancers --region $REGION 2>/dev/null | \
  grep -o 'arn:aws:elasticloadbalancing[^"]*' || echo "")

if [ -z "$ALB_ARNS" ]; then
  echo -e "${GREEN}✅ No ALBs found${NC}"
else
  echo "Found ALBs, deleting..."
  echo "$ALB_ARNS" | while read arn; do
    if [ ! -z "$arn" ]; then
      echo "  Deleting: $arn"
      aws elbv2 delete-load-balancer --load-balancer-arn "$arn" --region $REGION 2>/dev/null || true
    fi
  done
  echo -e "${GREEN}✅ ALB deletion triggered${NC}"
  echo "⏳ Waiting 120 seconds for ALB cleanup..."
  sleep 120
fi

# =============================================================================
# STEP 3: Delete ALL Security Groups
# =============================================================================
echo ""
echo -e "${YELLOW}=== Step 3: Deleting ALL Kubernetes Security Groups ===${NC}"

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs --region $REGION \
  --filters "Name=tag:Name,Values=productx-vpc" \
  --query "Vpcs[0].VpcId" --output text 2>/dev/null || echo "")

if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  echo "🔍 Finding Kubernetes Security Groups..."
  
  # Get ALL SGs in VPC (except default)
  ALL_SG_IDS=$(aws ec2 describe-security-groups --region $REGION \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[?GroupName!='default'].GroupId" \
    --output text 2>/dev/null || echo "")
  
  if [ -z "$ALL_SG_IDS" ]; then
    echo -e "${GREEN}✅ No Security Groups to clean${NC}"
  else
    echo "Found Security Groups: $ALL_SG_IDS"
    
    # Remove ALL rules from ALL SGs
    echo "🔓 Removing all ingress/egress rules..."
    for SG_ID in $ALL_SG_IDS; do
      SG_NAME=$(aws ec2 describe-security-groups --region $REGION --group-ids $SG_ID \
        --query "SecurityGroups[0].GroupName" --output text 2>/dev/null || echo "unknown")
      echo "  Processing: $SG_ID ($SG_NAME)"
      
      # Revoke ingress
      INGRESS=$(aws ec2 describe-security-groups --region $REGION --group-ids $SG_ID \
        --query "SecurityGroups[0].IpPermissions" --output json 2>/dev/null || echo "[]")
      if [ "$INGRESS" != "[]" ] && [ "$INGRESS" != "null" ]; then
        echo "$INGRESS" > /tmp/ing-$SG_ID.json
        aws ec2 revoke-security-group-ingress --region $REGION \
          --group-id $SG_ID --ip-permissions file:///tmp/ing-$SG_ID.json 2>/dev/null || true
        rm -f /tmp/ing-$SG_ID.json
      fi
      
      # Revoke egress
      EGRESS=$(aws ec2 describe-security-groups --region $REGION --group-ids $SG_ID \
        --query "SecurityGroups[0].IpPermissionsEgress" --output json 2>/dev/null || echo "[]")
      if [ "$EGRESS" != "[]" ] && [ "$EGRESS" != "null" ]; then
        echo "$EGRESS" > /tmp/eg-$SG_ID.json
        aws ec2 revoke-security-group-egress --region $REGION \
          --group-id $SG_ID --ip-permissions file:///tmp/eg-$SG_ID.json 2>/dev/null || true
        rm -f /tmp/eg-$SG_ID.json
      fi
    done
    
    echo "⏳ Waiting 10 seconds for rule removal to propagate..."
    sleep 10
    
    # Delete Kubernetes SGs
    echo "🗑️  Deleting Kubernetes Security Groups..."
    for SG_ID in $ALL_SG_IDS; do
      SG_NAME=$(aws ec2 describe-security-groups --region $REGION --group-ids $SG_ID \
        --query "SecurityGroups[0].GroupName" --output text 2>/dev/null || echo "")
      
      # Only delete Kubernetes SGs
      IS_K8S_SG=false
      if [[ "$SG_NAME" == k8s-traffic-* ]]; then
        IS_K8S_SG=true
      fi
      
      # Check for ALB tag
      HAS_ALB_TAG=$(aws ec2 describe-security-groups --region $REGION --group-ids $SG_ID \
        --query "SecurityGroups[0].Tags[?Key=='elbv2.k8s.aws/cluster'].Value" \
        --output text 2>/dev/null || echo "")
      if [ ! -z "$HAS_ALB_TAG" ]; then
        IS_K8S_SG=true
      fi
      
      if [ "$IS_K8S_SG" = true ]; then
        echo "  Deleting Kubernetes SG: $SG_ID ($SG_NAME)"
        aws ec2 delete-security-group --region $REGION --group-id $SG_ID 2>/dev/null && {
          echo -e "${GREEN}    ✅ Deleted${NC}"
        } || {
          echo -e "${YELLOW}    ⚠️  Cannot delete (will retry)${NC}"
        }
      else
        echo "  Skipping Terraform SG: $SG_ID ($SG_NAME)"
      fi
    done
    
    echo -e "${GREEN}✅ Security Groups cleanup completed${NC}"
  fi
fi

# =============================================================================
# STEP 4: Terraform Destroy
# =============================================================================
echo ""
echo -e "${YELLOW}=== Step 4: Running Terraform Destroy ===${NC}"
echo ""
echo -e "${CYAN}All Kubernetes resources have been cleaned up!${NC}"
echo -e "${CYAN}Now Terraform can safely destroy infrastructure...${NC}"
echo ""

cd terraform

echo -e "${RED}⚠️  This will destroy all Terraform-managed resources:${NC}"
echo "  - VPC, Subnets, Internet Gateway, NAT Gateway"
echo "  - EKS Cluster, Node Groups"
echo "  - EC2 instances (DB+NFS)"
echo "  - IAM Roles, Policies"
echo "  - Terraform-managed Security Groups"
echo ""
echo -e "${YELLOW}Press Ctrl+C to cancel, or wait 10 seconds to continue...${NC}"
sleep 10

terraform destroy -auto-approve

cd ..

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}✅ CLEANUP COMPLETED!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo "  ✅ Kubernetes resources deleted"
echo "  ✅ ALBs deleted"
echo "  ✅ Kubernetes Security Groups deleted"
echo "  ✅ Terraform infrastructure destroyed"
echo ""
echo -e "${YELLOW}📝 If you see any errors, you may need to:${NC}"
echo "  1. Wait a few minutes for AWS to finish cleanup"
echo "  2. Run this script again"
echo "  3. Check AWS Console for remaining resources"
echo ""
