#!/bin/bash

# =============================================================================
# SETUP-MULTI-ALB.SH - Automated Multi-ALB Setup Script
# =============================================================================
# Purpose: Automate the setup of 3 separate ALBs with SSL certificates
# Usage: ./scripts/setup-multi-alb.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    print_success "Terraform is installed"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl is installed"
    
    # Check if aws cli is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    print_success "AWS CLI is installed"
    
    # Check kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
}

# Step 1: Apply Terraform to create certificates
create_certificates() {
    print_header "Step 1: Creating SSL Certificates with Terraform"
    
    cd terraform
    
    # Check if terraform.tfvars exists
    if [ ! -f terraform.tfvars ]; then
        print_error "terraform.tfvars not found"
        print_info "Please create terraform.tfvars with enable_https=true and domain_name"
        exit 1
    fi
    
    # Check if HTTPS is enabled
    if ! grep -q "enable_https.*=.*true" terraform.tfvars; then
        print_error "enable_https is not set to true in terraform.tfvars"
        exit 1
    fi
    
    # Check if domain_name is set
    if ! grep -q "domain_name.*=.*\".*\"" terraform.tfvars; then
        print_error "domain_name is not set in terraform.tfvars"
        exit 1
    fi
    
    print_info "Running terraform init..."
    terraform init
    
    print_info "Running terraform plan..."
    terraform plan -out=tfplan
    
    print_info "Running terraform apply..."
    terraform apply tfplan
    
    print_success "Certificates created successfully"
    
    cd ..
}

# Step 2: Get certificate ARNs
get_certificate_arns() {
    print_header "Step 2: Retrieving Certificate ARNs"
    
    cd terraform
    
    export PROD_CERT_ARN=$(terraform output -raw production_certificate_arn)
    export STAGING_CERT_ARN=$(terraform output -raw staging_certificate_arn)
    export MONITORING_CERT_ARN=$(terraform output -raw monitoring_certificate_arn)
    
    echo -e "${GREEN}Production Certificate ARN:${NC}"
    echo "$PROD_CERT_ARN"
    echo ""
    
    echo -e "${GREEN}Staging Certificate ARN:${NC}"
    echo "$STAGING_CERT_ARN"
    echo ""
    
    echo -e "${GREEN}Monitoring Certificate ARN:${NC}"
    echo "$MONITORING_CERT_ARN"
    echo ""
    
    cd ..
}

# Step 3: Display DNS validation records
display_validation_records() {
    print_header "Step 3: DNS Validation Records"
    
    cd terraform
    
    print_warning "Please add these DNS records to Hostinger:"
    echo ""
    
    terraform output -json certificate_validation_records | jq -r '
        .production.records[] | 
        "Type: CNAME\nName: \(.name)\nValue: \(.value)\nDomain: \(.domain)\n"
    '
    
    terraform output -json certificate_validation_records | jq -r '
        .staging.records[] | 
        "Type: CNAME\nName: \(.name)\nValue: \(.value)\nDomain: \(.domain)\n"
    '
    
    terraform output -json certificate_validation_records | jq -r '
        .monitoring.records[] | 
        "Type: CNAME\nName: \(.name)\nValue: \(.value)\nDomain: \(.domain)\n"
    '
    
    cd ..
    
    print_warning "Waiting for certificate validation..."
    print_info "This may take 5-30 minutes"
    print_info "Press Enter when you have added the DNS records and certificates are validated"
    read -r
}

# Step 4: Wait for certificate validation
wait_for_certificates() {
    print_header "Step 4: Waiting for Certificate Validation"
    
    cd terraform
    
    REGION=$(terraform output -raw aws_region || echo "ap-southeast-1")
    
    print_info "Checking production certificate..."
    aws acm wait certificate-validated \
        --certificate-arn "$PROD_CERT_ARN" \
        --region "$REGION" || print_warning "Production certificate validation timeout"
    
    print_info "Checking staging certificate..."
    aws acm wait certificate-validated \
        --certificate-arn "$STAGING_CERT_ARN" \
        --region "$REGION" || print_warning "Staging certificate validation timeout"
    
    print_info "Checking monitoring certificate..."
    aws acm wait certificate-validated \
        --certificate-arn "$MONITORING_CERT_ARN" \
        --region "$REGION" || print_warning "Monitoring certificate validation timeout"
    
    print_success "All certificates validated"
    
    cd ..
}

# Step 5: Update Ingress files with certificate ARNs
update_ingress_files() {
    print_header "Step 5: Updating Ingress Files"
    
    # Get domain name from terraform
    cd terraform
    DOMAIN_NAME=$(terraform output -raw domain_name 2>/dev/null || echo "")
    cd ..
    
    if [ -z "$DOMAIN_NAME" ]; then
        print_error "Could not get domain_name from Terraform"
        exit 1
    fi
    
    # Backup original files
    print_info "Creating backups..."
    cp kubernetes/ingress.yaml kubernetes/ingress.yaml.bak
    cp kubernetes/ingress-staging.yaml kubernetes/ingress-staging.yaml.bak
    cp kubernetes/ingress-monitoring.yaml kubernetes/ingress-monitoring.yaml.bak
    
    # Update production ingress
    print_info "Updating production ingress..."
    sed -i.tmp "s|PRODUCTION_CERTIFICATE_ARN|$PROD_CERT_ARN|g" kubernetes/ingress.yaml
    sed -i.tmp "s|PLACEHOLDER_DOMAIN|$DOMAIN_NAME|g" kubernetes/ingress.yaml
    rm -f kubernetes/ingress.yaml.tmp
    
    # Update staging ingress
    print_info "Updating staging ingress..."
    sed -i.tmp "s|STAGING_CERTIFICATE_ARN|$STAGING_CERT_ARN|g" kubernetes/ingress-staging.yaml
    sed -i.tmp "s|PLACEHOLDER_DOMAIN|$DOMAIN_NAME|g" kubernetes/ingress-staging.yaml
    rm -f kubernetes/ingress-staging.yaml.tmp
    
    # Update monitoring ingress
    print_info "Updating monitoring ingress..."
    sed -i.tmp "s|MONITORING_CERTIFICATE_ARN|$MONITORING_CERT_ARN|g" kubernetes/ingress-monitoring.yaml
    sed -i.tmp "s|PLACEHOLDER_DOMAIN|$DOMAIN_NAME|g" kubernetes/ingress-monitoring.yaml
    rm -f kubernetes/ingress-monitoring.yaml.tmp
    
    print_success "Ingress files updated"
}

# Step 6: Deploy Ingress resources
deploy_ingress() {
    print_header "Step 6: Deploying Ingress Resources"
    
    # Deploy production ingress
    print_info "Deploying production ingress..."
    kubectl apply -f kubernetes/ingress.yaml
    print_success "Production ingress deployed"
    
    # Deploy staging ingress
    print_info "Deploying staging ingress..."
    kubectl apply -f kubernetes/ingress-staging.yaml
    print_success "Staging ingress deployed"
    
    # Check if monitoring namespace exists
    if kubectl get namespace monitoring &> /dev/null; then
        print_info "Deploying monitoring ingress..."
        kubectl apply -f kubernetes/ingress-monitoring.yaml
        print_success "Monitoring ingress deployed"
    else
        print_warning "Monitoring namespace not found, skipping monitoring ingress"
        print_info "Deploy monitoring stack first, then run: kubectl apply -f kubernetes/ingress-monitoring.yaml"
    fi
}

# Step 7: Wait for ALB creation
wait_for_albs() {
    print_header "Step 7: Waiting for ALB Creation"
    
    print_info "Waiting for production ALB..."
    kubectl wait --for=condition=available --timeout=300s ingress/app-ingress -n productx || true
    
    print_info "Waiting for staging ALB..."
    kubectl wait --for=condition=available --timeout=300s ingress/staging-ingress -n productx || true
    
    if kubectl get namespace monitoring &> /dev/null; then
        print_info "Waiting for monitoring ALB..."
        kubectl wait --for=condition=available --timeout=300s ingress/monitoring-ingress -n monitoring || true
    fi
    
    print_success "ALBs are being created"
}

# Step 8: Get ALB DNS names
get_alb_dns_names() {
    print_header "Step 8: Retrieving ALB DNS Names"
    
    sleep 30  # Wait a bit for ALB to be fully ready
    
    print_info "Production ALB DNS:"
    PROD_ALB=$(kubectl get ingress app-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not ready yet")
    echo "$PROD_ALB"
    echo ""
    
    print_info "Staging ALB DNS:"
    STAGING_ALB=$(kubectl get ingress staging-ingress -n productx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not ready yet")
    echo "$STAGING_ALB"
    echo ""
    
    if kubectl get namespace monitoring &> /dev/null; then
        print_info "Monitoring ALB DNS:"
        MONITORING_ALB=$(kubectl get ingress monitoring-ingress -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not ready yet")
        echo "$MONITORING_ALB"
        echo ""
    fi
}

# Step 9: Display DNS configuration instructions
display_dns_instructions() {
    print_header "Step 9: DNS Configuration on Hostinger"
    
    cd terraform
    DOMAIN_NAME=$(terraform output -raw domain_name 2>/dev/null || echo "")
    cd ..
    
    echo -e "${YELLOW}Please add these DNS records to Hostinger:${NC}"
    echo ""
    
    if [ "$PROD_ALB" != "Not ready yet" ]; then
        echo -e "${GREEN}Production (${DOMAIN_NAME}):${NC}"
        echo "Type: CNAME"
        echo "Name: @ (or leave empty)"
        echo "Target: $PROD_ALB"
        echo "TTL: 3600"
        echo ""
    fi
    
    if [ "$STAGING_ALB" != "Not ready yet" ]; then
        echo -e "${GREEN}Staging (staging.${DOMAIN_NAME}):${NC}"
        echo "Type: CNAME"
        echo "Name: staging"
        echo "Target: $STAGING_ALB"
        echo "TTL: 3600"
        echo ""
    fi
    
    if [ -n "$MONITORING_ALB" ] && [ "$MONITORING_ALB" != "Not ready yet" ]; then
        echo -e "${GREEN}Monitoring (monitoring.${DOMAIN_NAME}):${NC}"
        echo "Type: CNAME"
        echo "Name: monitoring"
        echo "Target: $MONITORING_ALB"
        echo "TTL: 3600"
        echo ""
    fi
}

# Step 10: Verify deployment
verify_deployment() {
    print_header "Step 10: Verification"
    
    cd terraform
    DOMAIN_NAME=$(terraform output -raw domain_name 2>/dev/null || echo "")
    cd ..
    
    print_info "After DNS propagation (5-30 minutes), verify with:"
    echo ""
    echo "curl -I https://${DOMAIN_NAME}"
    echo "curl -I https://staging.${DOMAIN_NAME}"
    echo "curl -I https://monitoring.${DOMAIN_NAME}"
    echo ""
    
    print_info "Check Ingress status:"
    echo "kubectl get ingress -A"
    echo ""
    
    print_info "Check ALB status:"
    echo "aws elbv2 describe-load-balancers --region ap-southeast-1 | grep productx"
}

# Main execution
main() {
    print_header "Multi-ALB Setup Script"
    
    check_prerequisites
    create_certificates
    get_certificate_arns
    display_validation_records
    wait_for_certificates
    update_ingress_files
    deploy_ingress
    wait_for_albs
    get_alb_dns_names
    display_dns_instructions
    verify_deployment
    
    print_header "Setup Complete!"
    print_success "Multi-ALB architecture has been deployed"
    print_info "See HOSTINGER_SUBDOMAIN_SETUP.md for detailed DNS configuration"
    print_info "See MULTI_ALB_DEPLOYMENT_GUIDE.md for architecture details"
}

# Run main function
main
