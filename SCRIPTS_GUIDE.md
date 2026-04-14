# Scripts Guide - ProductX DevOps

## 📜 Available Scripts

### 1. bootstrap-backend.sh
**Purpose:** Create S3 bucket and DynamoDB table for Terraform remote state

**Usage:**
```bash
chmod +x bootstrap-backend.sh
./bootstrap-backend.sh
```

**What it does:**
- ✅ Creates S3 bucket with unique name
- ✅ Enables versioning and encryption
- ✅ Creates DynamoDB table for state locking
- ✅ Outputs bucket name for GitHub Secret

**When to use:** Before first Terraform deployment

---

### 2. fix-iam-permissions.sh
**Purpose:** Automatically add required IAM policies to user

**Usage:**
```bash
chmod +x fix-iam-permissions.sh
./fix-iam-permissions.sh <iam-user-name>

# Example:
./fix-iam-permissions.sh devops-final-ci
```

**What it does:**
- ✅ Checks AWS credentials
- ✅ Verifies IAM user exists
- ✅ Attaches CloudWatchLogsFullAccess
- ✅ Attaches AWSKeyManagementServicePowerUser
- ✅ Attaches AWSCertificateManagerFullAccess
- ✅ Tests permissions

**When to use:** When getting AccessDeniedException errors

---

### 3. cleanup-failed-resources.sh
**Purpose:** Clean up leftover AWS resources from failed deployments

**Usage:**
```bash
chmod +x cleanup-failed-resources.sh
./cleanup-failed-resources.sh
```

**What it does:**
- ✅ Deletes CloudWatch Log Groups
- ✅ Deletes KMS Aliases
- ✅ Schedules KMS Key deletion
- ✅ Checks for leftover resources

**When to use:** When getting "AlreadyExistsException" errors

---

### 4. release-elastic-ips.sh
**Purpose:** Release unused Elastic IPs to free up quota

**Usage:**
```bash
chmod +x release-elastic-ips.sh
./release-elastic-ips.sh
```

**What it does:**
- ✅ Lists all Elastic IPs
- ✅ Finds unassociated EIPs
- ✅ Releases unused EIPs
- ✅ Shows remaining quota (5 max)

**When to use:** When getting "AddressLimitExceeded" error

---

### 5. full-cleanup.sh
**Purpose:** Complete cleanup of all AWS resources

**Usage:**
```bash
chmod +x full-cleanup.sh
./full-cleanup.sh [key-name]

# Example:
./full-cleanup.sh productx-key
```

**What it does:**
- ✅ Runs release-elastic-ips.sh
- ✅ Runs cleanup-failed-resources.sh
- ✅ Runs terraform destroy
- ✅ Verifies cleanup completion

**When to use:** When you want to start fresh

---

### 6. check-deployment-status.sh
**Purpose:** Check current deployment status and what's deployed

**Usage:**
```bash
chmod +x check-deployment-status.sh
./check-deployment-status.sh
```

**What it does:**
- ✅ Checks AWS credentials
- ✅ Checks Terraform state
- ✅ Lists AWS resources (VPC, EKS, EC2, EIP, ALB)
- ✅ Checks Kubernetes resources
- ✅ Provides recommendations

**When to use:** 
- To check deployment progress
- To debug what's missing
- After errors to see what was created

---

## 🔄 Common Workflows

### First Time Setup
```bash
# 1. Bootstrap Terraform backend
./bootstrap-backend.sh

# 2. Add bucket name to GitHub Secret: TF_BACKEND_BUCKET

# 3. Fix IAM permissions
./fix-iam-permissions.sh devops-final-ci

# 4. Deploy infrastructure
cd terraform
terraform init
terraform apply -var="key_name=productx-key"
```

---

### Fix Deployment Errors
```bash
# If getting "AlreadyExistsException"
./cleanup-failed-resources.sh

# If getting "AddressLimitExceeded"
./release-elastic-ips.sh

# If getting "AccessDeniedException"
./fix-iam-permissions.sh devops-final-ci

# Then re-deploy
cd terraform
terraform apply -var="key_name=productx-key"
```

---

### Complete Reset
```bash
# 1. Full cleanup
./full-cleanup.sh productx-key

# 2. Wait 5-10 minutes

# 3. Verify cleanup
aws ec2 describe-instances --region ap-southeast-1
aws eks list-clusters --region ap-southeast-1
aws ec2 describe-addresses --region ap-southeast-1

# 4. Re-deploy
cd terraform
terraform init
terraform apply -var="key_name=productx-key"
```

---

### Daily Operations
```bash
# Check resources
kubectl get all -n productx
kubectl get pods -n productx -o wide

# View logs
kubectl logs -f deployment/backend -n productx
kubectl logs -f deployment/frontend -n productx

# Check HPA
kubectl get hpa -n productx

# Get application URL
kubectl get ingress -n productx
```

---

## 🆘 Emergency Procedures

### Infrastructure is broken, need to start over
```bash
./full-cleanup.sh productx-key
# Wait 10 minutes
cd terraform
terraform apply -var="key_name=productx-key"
```

### Can't deploy, getting multiple errors
```bash
# Run all fixes
./fix-iam-permissions.sh devops-final-ci
./release-elastic-ips.sh
./cleanup-failed-resources.sh

# Wait 5 minutes
cd terraform
terraform apply -var="key_name=productx-key"
```

### Terraform state is corrupted
```bash
# Backup current state
cd terraform
cp terraform.tfstate terraform.tfstate.backup

# Try to refresh
terraform refresh -var="key_name=productx-key"

# If still broken, destroy and recreate
terraform destroy -var="key_name=productx-key"
terraform apply -var="key_name=productx-key"
```

### AWS quota exceeded
```bash
# Release Elastic IPs
./release-elastic-ips.sh

# Check other quotas
aws service-quotas list-service-quotas --service-code ec2

# Request quota increase (if needed)
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-0263D0A3 \
  --desired-value 10
```

---

## 📊 Script Execution Order

### For Clean Deployment
```
1. bootstrap-backend.sh
2. fix-iam-permissions.sh
3. terraform init
4. terraform apply
```

### For Fixing Errors
```
1. release-elastic-ips.sh (if EIP error)
2. cleanup-failed-resources.sh (if AlreadyExists error)
3. fix-iam-permissions.sh (if AccessDenied error)
4. terraform apply
```

### For Complete Reset
```
1. full-cleanup.sh
   ├─ release-elastic-ips.sh
   ├─ cleanup-failed-resources.sh
   └─ terraform destroy
2. Wait 5-10 minutes
3. terraform apply
```

---

## 🔍 Script Dependencies

```
bootstrap-backend.sh
  └─ Requires: AWS CLI configured

fix-iam-permissions.sh
  └─ Requires: AWS CLI configured
  └─ Requires: IAM user name as argument

cleanup-failed-resources.sh
  └─ Requires: AWS CLI configured

release-elastic-ips.sh
  └─ Requires: AWS CLI configured

full-cleanup.sh
  └─ Requires: All above scripts
  └─ Requires: Terraform initialized
  └─ Optional: SSH key name as argument
```

---

## 💡 Tips

1. **Always run scripts from project root directory**
   ```bash
   cd DevOps_Final
   ./script-name.sh
   ```

2. **Check AWS credentials before running**
   ```bash
   aws sts get-caller-identity
   ```

3. **Use correct region**
   ```bash
   export AWS_REGION=ap-southeast-1
   ```

4. **Make scripts executable once**
   ```bash
   chmod +x *.sh
   ```

5. **Read script output carefully**
   - Scripts provide detailed information
   - Follow suggested next steps
   - Check for warnings and errors

6. **Wait between operations**
   - AWS needs time to clean up resources
   - Wait 5-10 minutes after cleanup
   - Don't rush re-deployment

---

## 📚 Related Documentation

- [GITHUB_SECRETS_GUIDE.md](./GITHUB_SECRETS_GUIDE.md) - GitHub Secrets setup
- [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md) - Full deployment guide
- [FIX_IAM_PERMISSIONS.md](./FIX_IAM_PERMISSIONS.md) - IAM and resource fixes
- [TROUBLESHOOTING_QUICK_REFERENCE.md](./TROUBLESHOOTING_QUICK_REFERENCE.md) - Quick fixes
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture

---

## 🤝 Contributing

If you create new scripts:
1. Add them to this guide
2. Include usage examples
3. Document what they do
4. Add to appropriate workflow
5. Update dependencies section
