# Fix Terraform Timeout & Output Issues

## 🔴 Vấn đề

Terraform plan/apply bị timeout hoặc output bị cắt giữa chừng trong GitHub Actions.

```
Error: Terraform exited with code 1.
Error: Process completed with exit code 1.
```

## ✅ Giải pháp

### Option 1: Tăng timeout cho GitHub Actions (Khuyến nghị)

Cập nhật file `.github/workflows/infrastructure-cd.yml`:

```yaml
# Trong job terraform-plan
- name: Terraform Plan
  id: plan
  working-directory: terraform
  timeout-minutes: 30  # Thêm dòng này
  run: |
    terraform plan ...

# Trong job terraform-apply
- name: Terraform Apply
  working-directory: terraform
  timeout-minutes: 60  # Thêm dòng này
  run: terraform apply -auto-approve tfplan
```

### Option 2: Giảm output verbosity

Thêm flag `-compact-warnings` vào terraform plan:

```yaml
- name: Terraform Plan
  run: |
    terraform plan \
      -compact-warnings \
      -out=tfplan \
      ...
```

### Option 3: Chạy local thay vì GitHub Actions

```bash
cd DevOps_Final/terraform

# Init
terraform init

# Plan
terraform plan -var="key_name=productx-key" -out=tfplan

# Apply
terraform apply tfplan
```

### Option 4: Split thành nhiều applies nhỏ

Thay vì apply tất cả cùng lúc, apply từng phần:

```bash
# 1. Apply VPC first
terraform apply -target=module.vpc -var="key_name=productx-key"

# 2. Apply EKS
terraform apply -target=module.eks -var="key_name=productx-key"

# 3. Apply EC2
terraform apply -target=aws_instance.db_server -var="key_name=productx-key"

# 4. Apply remaining
terraform apply -var="key_name=productx-key"
```

## 🔍 Debug Steps

### 1. Check if it's actually an error

Output bị cắt không có nghĩa là failed. Check:

```bash
# Trong GitHub Actions, xem full logs
# Click vào failed step → Expand all

# Hoặc check Terraform state
cd terraform
terraform state list
```

Nếu có resources trong state, nghĩa là đã apply thành công một phần.

### 2. Check actual error

Scroll lên trên output để tìm dòng `Error:` thực sự:

```
Common errors:
- Error: creating EC2 EIP: AddressLimitExceeded
- Error: creating KMS Alias: AlreadyExistsException
- Error: timeout waiting for...
```

### 3. Enable debug mode

```bash
export TF_LOG=DEBUG
terraform plan -var="key_name=productx-key"
```

## 🚀 Recommended Workflow

### For GitHub Actions

1. **Increase timeouts** trong workflow file
2. **Add retry logic** cho failed steps
3. **Split large plans** thành nhiều stages

### For Local Development

1. **Run locally first** để test
2. **Commit working config** 
3. **Then run in GitHub Actions**

## 📝 Update Workflow File

Tạo file mới hoặc update `.github/workflows/infrastructure-cd.yml`:

```yaml
jobs:
  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    timeout-minutes: 30  # Add this
    
    steps:
      # ... existing steps ...
      
      - name: Terraform Plan
        id: plan
        working-directory: terraform
        timeout-minutes: 20  # Add this
        continue-on-error: true  # Don't fail immediately
        run: |
          terraform plan \
            -compact-warnings \
            -out=tfplan \
            -no-color \
            -detailed-exitcode \
            -var="key_name=${{ secrets.AWS_KEY_NAME }}" \
            || export exitcode=$?
          
          echo "exitcode=$exitcode" >> $GITHUB_OUTPUT
          
          if [ $exitcode -eq 1 ]; then
            echo "Terraform plan failed"
            exit 1
          fi
      
      - name: Check Plan Output
        if: always()
        run: |
          echo "Plan exitcode: ${{ steps.plan.outputs.exitcode }}"
          if [ "${{ steps.plan.outputs.exitcode }}" == "1" ]; then
            echo "Plan failed, check logs above"
            exit 1
          fi

  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    timeout-minutes: 60  # Add this
    needs: terraform-plan
    
    steps:
      # ... existing steps ...
      
      - name: Terraform Apply
        working-directory: terraform
        timeout-minutes: 45  # Add this
        run: |
          terraform apply -auto-approve tfplan
      
      - name: Verify Apply
        if: always()
        working-directory: terraform
        run: |
          echo "Checking Terraform state..."
          terraform state list || echo "No state found"
```

## 🔧 Quick Fixes

### If plan succeeds but apply times out

```bash
# Check what was created
cd terraform
terraform state list

# Continue from where it stopped
terraform apply -var="key_name=productx-key"
```

### If getting "Error: Terraform exited with code 1"

```bash
# This is generic error, check actual error above in logs
# Common causes:
# 1. Resource already exists → Run cleanup
# 2. Permission denied → Fix IAM
# 3. Quota exceeded → Release resources
# 4. Timeout → Increase timeout or run local
```

### If output is too long

```bash
# Save to file instead
terraform plan -var="key_name=productx-key" -out=tfplan 2>&1 | tee plan.log

# Then review
less plan.log
```

## 💡 Best Practices

1. **Always run `terraform plan` first** locally
2. **Check plan output** before apply
3. **Use `-target`** for large infrastructures
4. **Enable state locking** (already configured)
5. **Use remote state** (already configured)
6. **Set appropriate timeouts** in CI/CD
7. **Monitor apply progress** in AWS Console

## 🆘 If Still Failing

1. **Run locally** to isolate issue:
   ```bash
   cd terraform
   terraform init
   terraform plan -var="key_name=productx-key"
   terraform apply -var="key_name=productx-key"
   ```

2. **Check GitHub Actions logs** carefully:
   - Expand all steps
   - Look for actual error message
   - Check timestamps for timeouts

3. **Verify AWS resources** in Console:
   - Check what was created
   - Check for errors in CloudTrail
   - Verify quotas and limits

4. **Contact support** with:
   - Full error message
   - Terraform version
   - AWS region
   - Resources being created
