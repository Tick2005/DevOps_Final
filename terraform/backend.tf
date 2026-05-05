# =============================================================================
# BACKEND.TF - Remote State Backend Configuration for ProductX
# =============================================================================
# Purpose: Store Terraform state in S3 with DynamoDB locking
# =============================================================================

terraform {
  backend "s3" {
    bucket = "productx-tfstate-REPLACE_ME"
    key = "production/terraform.tfstate"
    region = "ap-southeast-1"
    dynamodb_table = "productx-tflock"
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
