# =============================================================================
# BACKEND.TF - Remote State Backend Configuration for ProductX
# =============================================================================
# Purpose: Store Terraform state in S3 with DynamoDB locking
# =============================================================================

terraform {
  backend "s3" {
    # IMPORTANT: Replace "REPLACE_ME" with your actual bucket name
    # Get bucket name from bootstrap-backend.sh output
    bucket = "productx-tfstate-REPLACE_ME"
    
    # State file path within bucket
    key = "production/terraform.tfstate"
    
    # AWS region
    region = "ap-southeast-1"
    
    # DynamoDB table for state locking
    dynamodb_table = "productx-tflock"
    
    # Enable encryption at rest
    encrypt = true
  }
}

# =============================================================================
# SETUP INSTRUCTIONS
# =============================================================================
# 1. Run bootstrap-backend.sh to create S3 bucket and DynamoDB table
# 2. Copy bucket name from script output
# 3. Replace "productx-tfstate-REPLACE_ME" above with actual bucket name
# 4. Run: terraform init
# =============================================================================
