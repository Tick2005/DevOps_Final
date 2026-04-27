# GitHub Secrets Configuration Guide

## Required GitHub Secrets

Configure these secrets in your GitHub repository: **Settings → Secrets and variables → Actions → New repository secret**

### 1. AWS Credentials

| Secret Name | Description | Example | How to Get |
|------------|-------------|---------|------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key ID | `AKIAIOSFODNN7EXAMPLE` | AWS IAM Console → Users → Security credentials → Create access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret access key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` | Same as above (shown only once during creation) |

**Required IAM Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:UpdateKubeconfig",
        "ec2:*",
        "elasticloadbalancing:*",
        "acm:*",
        "route53:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2. Docker Hub Credentials

| Secret Name | Description | Example | How to Get |
|------------|-------------|---------|------------|
| `DOCKER_USERNAME` | Docker Hub username | `myusername` | Your Docker Hub account username |
| `DOCKER_PASSWORD` | Docker Hub password or access token | `dckr_pat_xxxxx` | Docker Hub → Account Settings → Security → New Access Token |

**Note:** Use Personal Access Token instead of password for better security.

### 3. EKS Configuration

| Secret Name | Description | Example | How to Get |
|------------|-------------|---------|------------|
| `EKS_CLUSTER_NAME` | Name of your EKS cluster | `productx-eks-cluster` | From Terraform output or AWS EKS Console |

### 4. Domain Configuration

| Secret Name | Description | Example | How to Get |
|------------|-------------|---------|------------|
| `DOMAIN_NAME` | Your application domain | `tranduchuy.site` | Your registered domain name |

### 5. Database Credentials

| Secret Name | Description | Example | How to Get |
|------------|-------------|---------|------------|
| `DB_PASSWORD` | PostgreSQL database password | `SecurePassword123!` | Set during database setup (Ansible playbook) |
| `DB_HOST` | Database host address | `10.0.1.100` | Private IP of database EC2 instance |
| `DB_NAME` | Database name | `productx_db` | From Ansible database playbook |
| `DB_USERNAME` | Database username | `productx_user` | From Ansible database playbook |

### 6. NFS Configuration

| Secret Name | Description | Example | How to Get |
|------------|-------------|---------|------------|
| `NFS_SERVER_IP` | NFS server IP address | `10.0.1.50` | Private IP of NFS EC2 instance |

### 7. SSL Certificate (Optional)

| Secret Name | Description | Example | How to Get |
|------------|-------------|---------|------------|
| `ACM_CERTIFICATE_ARN` | AWS ACM certificate ARN | `arn:aws:acm:ap-southeast-1:123456789012:certificate/xxxxx` | From Terraform output or AWS ACM Console |

---

## Quick Setup Commands

### 1. Set AWS Credentials
```bash
gh secret set AWS_ACCESS_KEY_ID --body "YOUR_ACCESS_KEY_ID"
gh secret set AWS_SECRET_ACCESS_KEY --body "YOUR_SECRET_ACCESS_KEY"
```

### 2. Set Docker Hub Credentials
```bash
gh secret set DOCKER_USERNAME --body "YOUR_DOCKER_USERNAME"
gh secret set DOCKER_PASSWORD --body "YOUR_DOCKER_TOKEN"
```

### 3. Set EKS Configuration
```bash
gh secret set EKS_CLUSTER_NAME --body "productx-eks-cluster"
```

### 4. Set Domain
```bash
gh secret set DOMAIN_NAME --body "tranduchuy.site"
```

### 5. Set Database Credentials
```bash
gh secret set DB_PASSWORD --body "SecurePassword123!"
gh secret set DB_HOST --body "10.0.1.100"
gh secret set DB_NAME --body "productx_db"
gh secret set DB_USERNAME --body "productx_user"
```

### 6. Set NFS Server
```bash
gh secret set NFS_SERVER_IP --body "10.0.1.50"
```

---

## Verification

### Check All Secrets Are Set
```bash
gh secret list
```

Expected output:
```
AWS_ACCESS_KEY_ID        Updated 2024-XX-XX
AWS_SECRET_ACCESS_KEY    Updated 2024-XX-XX
DOCKER_USERNAME          Updated 2024-XX-XX
DOCKER_PASSWORD          Updated 2024-XX-XX
EKS_CLUSTER_NAME         Updated 2024-XX-XX
DOMAIN_NAME              Updated 2024-XX-XX
DB_PASSWORD              Updated 2024-XX-XX
DB_HOST                  Updated 2024-XX-XX
DB_NAME                  Updated 2024-XX-XX
DB_USERNAME              Updated 2024-XX-XX
NFS_SERVER_IP            Updated 2024-XX-XX
ACM_CERTIFICATE_ARN      Updated 2024-XX-XX (optional)
```

---

## Security Best Practices

1. **Rotate Credentials Regularly**
   - AWS access keys: Every 90 days
   - Docker Hub tokens: Every 180 days
   - Database passwords: Every 90 days

2. **Use Least Privilege**
   - Create dedicated IAM user for CI/CD
   - Grant only required permissions
   - Use IAM roles when possible

3. **Monitor Secret Usage**
   - Check GitHub Actions logs for unauthorized access
   - Enable AWS CloudTrail for API monitoring
   - Review Docker Hub access logs

4. **Never Commit Secrets**
   - Use `.gitignore` for sensitive files
   - Scan commits with tools like `git-secrets`
   - Use pre-commit hooks to prevent leaks

5. **Backup Secrets Securely**
   - Store in password manager (1Password, LastPass)
   - Encrypt backup files
   - Limit access to team leads only

---

## Troubleshooting

### Secret Not Found Error
```
Error: Secret AWS_ACCESS_KEY_ID not found
```
**Solution:** Verify secret name matches exactly (case-sensitive)

### Invalid AWS Credentials
```
Error: The security token included in the request is invalid
```
**Solution:** 
1. Verify credentials are correct
2. Check IAM user has required permissions
3. Ensure credentials haven't expired

### Docker Login Failed
```
Error: unauthorized: incorrect username or password
```
**Solution:**
1. Use Docker Hub access token instead of password
2. Verify username is correct (not email)
3. Check token hasn't been revoked

### EKS Cluster Not Found
```
Error: cluster productx-eks-cluster not found
```
**Solution:**
1. Verify cluster name matches exactly
2. Check cluster is in correct AWS region
3. Ensure IAM user has EKS permissions

---

## Environment-Specific Secrets

If you have multiple environments (staging, production), use GitHub Environments:

### Create Environment
1. Go to **Settings → Environments → New environment**
2. Name it `production` or `staging`
3. Add environment-specific secrets

### Use in Workflow
```yaml
jobs:
  deploy:
    environment: production  # Uses production secrets
    steps:
      - name: Deploy
        run: echo "Deploying to ${{ secrets.DOMAIN_NAME }}"
```

---

## Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
