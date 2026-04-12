# Fix IAM Permissions Errors

## 🔴 Lỗi gặp phải

```
1. AccessDeniedException: acm:RequestCertificate
2. AccessDeniedException: kms:TagResource  
3. AccessDeniedException: logs:CreateLogGroup
4. InvalidParameterCombination: Instance type not eligible for Free Tier
```

## ✅ Giải pháp

### Option 1: Thêm IAM Policies (Khuyến nghị)

#### Bước 1: Đăng nhập AWS Console
```
https://console.aws.amazon.com/iam/
```

#### Bước 2: Tìm IAM User
```
1. Sidebar → Users
2. Tìm user: devops-final-ci (hoặc productx-ci-user)
3. Click vào user
```

#### Bước 3: Thêm Policies
```
1. Tab "Permissions"
2. Click "Add permissions" → "Attach policies directly"
3. Tìm và thêm các policies sau:
```

**Policies cần thêm:**
- ✅ `AWSCertificateManagerFullAccess` - Cho ACM certificate
- ✅ `CloudWatchLogsFullAccess` - Cho EKS logs
- ✅ `AWSKeyManagementServicePowerUser` - Cho KMS encryption

**Hoặc tạo Custom Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "acm:RequestCertificate",
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:DeleteCertificate",
        "acm:AddTagsToCertificate"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:ListKeys",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:ScheduleKeyDeletion",
        "kms:EnableKeyRotation",
        "kms:PutKeyPolicy",
        "kms:GetKeyPolicy"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:DeleteLogGroup",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Bước 4: Lưu và Verify
```bash
# Test permissions
aws acm list-certificates --region ap-southeast-1
aws kms list-keys --region ap-southeast-1
aws logs describe-log-groups --region ap-southeast-1
```

### Option 2: Disable HTTPS tạm thời (Nhanh nhất)

Nếu không cần HTTPS ngay, disable tạm thời:

#### Cách 1: Qua GitHub Secrets
```
1. GitHub → Repository → Settings → Secrets
2. Xóa hoặc để trống secret: DOMAIN_NAME
3. Hoặc không thêm secret DOMAIN_NAME
```

#### Cách 2: Qua Terraform variables
```bash
# Khi chạy terraform apply
terraform apply \
  -var="key_name=productx-key" \
  -var="enable_https=false" \
  -var="domain_name="
```

#### Cách 3: Comment ACM resource
Tạm thời comment file `terraform/acm.tf`:

```bash
cd DevOps_Final/terraform
mv acm.tf acm.tf.disabled
```

### Option 3: Sử dụng Free Tier Instance Types

File `variables.tf` đã được update:
- ✅ DB Server: `t3.micro` (Free Tier eligible)
- ✅ EKS Nodes: `t3.small` (Rẻ hơn, đủ dùng)

**Lưu ý Free Tier limits:**
- t2.micro: 750 hours/month (1 instance 24/7)
- t3.micro: Không free tier nhưng rẻ (~$7.5/month)

**Nếu muốn hoàn toàn free:**

```hcl
# terraform/variables.tf
variable "db_instance_type" {
  default = "t2.micro"  # Free Tier
}

variable "node_instance_type" {
  default = "t2.micro"  # Free Tier
}
```

## 🔧 Quick Fix Commands

### Fix 1: Update IAM Policies (AWS CLI)

```bash
# Attach managed policies
aws iam attach-user-policy \
  --user-name devops-final-ci \
  --policy-arn arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess

aws iam attach-user-policy \
  --user-name devops-final-ci \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

aws iam attach-user-policy \
  --user-name devops-final-ci \
  --policy-arn arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser
```

### Fix 2: Disable HTTPS và Re-run

```bash
# Update GitHub Secret
# DOMAIN_NAME = (để trống)

# Hoặc chạy local
cd terraform
terraform apply \
  -var="key_name=productx-key" \
  -var="enable_https=false"
```

### Fix 3: Destroy và Recreate với Free Tier

```bash
# Destroy current infrastructure
cd terraform
terraform destroy -var="key_name=productx-key"

# Update variables.tf (đã update rồi)
# Re-apply
terraform apply -var="key_name=productx-key"
```

## 📋 Checklist

Sau khi fix, verify:

- [ ] IAM user có đủ permissions (ACM, KMS, CloudWatch Logs)
- [ ] Instance types đã đổi sang Free Tier hoặc rẻ hơn
- [ ] HTTPS disabled nếu không cần (hoặc có đủ permissions)
- [ ] Terraform plan chạy thành công
- [ ] Terraform apply không có lỗi permissions

## 🎯 Khuyến nghị

**Cho môi trường học tập/test:**
1. ✅ Disable HTTPS (không cần domain)
2. ✅ Dùng t3.micro cho DB (hoặc t2.micro nếu muốn free)
3. ✅ Dùng t3.small cho EKS nodes (2 nodes)
4. ✅ Thêm IAM permissions cho KMS và CloudWatch Logs

**Cho môi trường production:**
1. ✅ Thêm đầy đủ IAM permissions
2. ✅ Enable HTTPS với domain
3. ✅ Dùng instance types phù hợp (t3.medium+)
4. ✅ Enable monitoring và logging

## 💰 Cost Estimate (sau khi fix)

| Service | Configuration | Cost/Month |
|---------|--------------|------------|
| EKS Cluster | 1 cluster | $73 |
| EC2 Nodes | 2x t3.small | $30 |
| EC2 DB | 1x t3.micro | $7.5 |
| NAT Gateway | 1 NAT | $35 |
| ALB | 1 load balancer | $20 |
| **Total** | | **~$165/month** |

**Với Free Tier (first 12 months):**
- EC2 t2.micro: Free 750 hours/month
- Estimated: ~$140/month

## 🆘 Nếu vẫn gặp lỗi

1. **Check IAM permissions:**
```bash
aws iam get-user-policy --user-name devops-final-ci --policy-name <policy-name>
aws iam list-attached-user-policies --user-name devops-final-ci
```

2. **Check AWS limits:**
```bash
aws service-quotas list-service-quotas --service-code ec2
```

3. **Enable CloudTrail để debug:**
```bash
aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=devops-final-ci
```

4. **Contact AWS Support** nếu vẫn bị denied sau khi thêm policies

## 📚 Tài liệu tham khảo

- [AWS IAM Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
