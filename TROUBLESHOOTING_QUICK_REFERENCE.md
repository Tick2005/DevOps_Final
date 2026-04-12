# Troubleshooting Quick Reference

## 🚨 Common Errors & Quick Fixes

### 1. AlreadyExistsException: KMS alias already exists

**Quick Fix:**
```bash
./cleanup-failed-resources.sh
```

**Manual Fix:**
```bash
aws kms delete-alias --alias-name alias/eks/productx-eks-cluster --region ap-southeast-1
```

---

### 2. ResourceAlreadyExistsException: Log group already exists

**Quick Fix:**
```bash
./cleanup-failed-resources.sh
```

**Manual Fix:**
```bash
aws logs delete-log-group --log-group-name /aws/eks/productx-eks-cluster/cluster --region ap-southeast-1
```

---

### 3. AccessDeniedException: acm:RequestCertificate

**Quick Fix:**
```bash
./fix-iam-permissions.sh devops-final-ci
```

**Manual Fix:**
```bash
aws iam attach-user-policy \
  --user-name devops-final-ci \
  --policy-arn arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess
```

---

### 4. AccessDeniedException: kms:TagResource

**Quick Fix:**
```bash
./fix-iam-permissions.sh devops-final-ci
```

**Manual Fix:**
```bash
aws iam attach-user-policy \
  --user-name devops-final-ci \
  --policy-arn arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser
```

---

### 5. AccessDeniedException: logs:CreateLogGroup

**Quick Fix:**
```bash
./fix-iam-permissions.sh devops-final-ci
```

**Manual Fix:**
```bash
aws iam attach-user-policy \
  --user-name devops-final-ci \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
```

---

### 6. InvalidParameterCombination: Instance type not eligible for Free Tier

**Already Fixed:** Instance types updated to t3.micro and t3.small

**If you want Free Tier:**
Edit `terraform/variables.tf`:
```hcl
variable "db_instance_type" {
  default = "t2.micro"  # Free Tier
}

variable "node_instance_type" {
  default = "t2.micro"  # Free Tier
}
```

---

### 7. Terraform state lock error

**Quick Fix:**
```bash
cd terraform
terraform force-unlock <LOCK_ID>
```

---

### 8. EKS cluster not accessible

**Quick Fix:**
```bash
aws eks update-kubeconfig --name productx-eks-cluster --region ap-southeast-1
kubectl cluster-info
```

---

### 9. Pods in CrashLoopBackOff

**Check logs:**
```bash
kubectl logs <pod-name> -n productx
kubectl describe pod <pod-name> -n productx
```

**Common causes:**
- Database connection failed
- ConfigMap/Secrets incorrect
- Image pull failed

---

### 10. ALB not created

**Check Load Balancer Controller:**
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

**Check Ingress:**
```bash
kubectl describe ingress app-ingress -n productx
```

---

## 🔄 Complete Cleanup & Redeploy

### Step 1: Cleanup
```bash
# Run cleanup script
./cleanup-failed-resources.sh

# Or full destroy
cd terraform
terraform destroy -var="key_name=productx-key"
```

### Step 2: Fix IAM Permissions
```bash
./fix-iam-permissions.sh devops-final-ci
```

### Step 3: Redeploy
```bash
cd terraform
terraform init
terraform plan -var="key_name=productx-key"
terraform apply -var="key_name=productx-key"
```

---

## 📞 Emergency Commands

### Force delete all resources
```bash
# Delete EKS cluster
aws eks delete-cluster --name productx-eks-cluster --region ap-southeast-1

# Delete node group first
aws eks delete-nodegroup \
  --cluster-name productx-eks-cluster \
  --nodegroup-name productx-main-ng \
  --region ap-southeast-1

# Delete EC2 instances
aws ec2 terminate-instances --instance-ids <instance-id> --region ap-southeast-1

# Delete VPC (after all resources deleted)
aws ec2 delete-vpc --vpc-id <vpc-id> --region ap-southeast-1
```

### Check what's running
```bash
# List all EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=productx" \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}" \
  --output table

# List all EKS clusters
aws eks list-clusters --region ap-southeast-1

# List all Load Balancers
aws elbv2 describe-load-balancers --region ap-southeast-1 --output table

# List all VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=productx" \
  --query "Vpcs[].{ID:VpcId,CIDR:CidrBlock,Name:Tags[?Key=='Name'].Value|[0]}" \
  --output table
```

---

## 💰 Cost Check

```bash
# Check current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE

# Or use AWS Cost Explorer in Console
# https://console.aws.amazon.com/cost-management/home
```

---

## 🔍 Debug Checklist

Before asking for help, check:

- [ ] AWS credentials configured: `aws sts get-caller-identity`
- [ ] IAM permissions correct: `aws iam list-attached-user-policies --user-name <user>`
- [ ] Region correct: `ap-southeast-1`
- [ ] SSH key exists: `aws ec2 describe-key-pairs --region ap-southeast-1`
- [ ] Terraform state clean: `cd terraform && terraform state list`
- [ ] No leftover resources: `./cleanup-failed-resources.sh`
- [ ] GitHub Secrets correct: Check in GitHub Settings
- [ ] Logs checked: GitHub Actions logs, kubectl logs, CloudWatch logs

---

## 📚 Useful Links

- [AWS Free Tier](https://aws.amazon.com/free/)
- [EKS Pricing](https://aws.amazon.com/eks/pricing/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)

---

## 🆘 Still Having Issues?

1. Check detailed guides:
   - [FIX_IAM_PERMISSIONS.md](./FIX_IAM_PERMISSIONS.md)
   - [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md)

2. Run diagnostic scripts:
   ```bash
   ./cleanup-failed-resources.sh
   ./fix-iam-permissions.sh devops-final-ci
   ```

3. Check GitHub Actions logs:
   - Repository → Actions → Click on failed workflow
   - Expand failed steps to see detailed errors

4. Enable Terraform debug:
   ```bash
   export TF_LOG=DEBUG
   terraform apply -var="key_name=productx-key"
   ```

5. Contact AWS Support or create GitHub issue with:
   - Error message
   - Terraform/kubectl output
   - AWS region and account ID (masked)
   - Steps to reproduce
