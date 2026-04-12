# Troubleshooting CI/CD Workflows

## Vấn đề: CD Workflow Tự Động Skip

### Triệu chứng
```
❌ CI PIPELINE FAILED!
CD Pipeline skipped because CI failed.
Please check the 'Build & Release Docker' workflow.
```

### Nguyên nhân
Workflow CD (`deploy-cd.yml`) chỉ chạy khi CI workflow (`main-ci.yml`) thành công. Nếu CI failed, CD sẽ tự động skip.

### Giải pháp

#### Bước 1: Kiểm tra lỗi CI
1. Vào GitHub Actions: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`
2. Chọn workflow **"Build & Release Docker"**
3. Click vào lần chạy gần nhất (icon màu đỏ ❌)
4. Xem log của từng job để tìm lỗi

#### Bước 2: Debug bằng script
```bash
cd DevOps_Final
chmod +x debug-ci-failure.sh
./debug-ci-failure.sh
```

---

## Các Lỗi CI Thường Gặp

### 1. Maven Build Failed (Backend)

**Lỗi:**
```
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin
[ERROR] Compilation failure
```

**Nguyên nhân:**
- Lỗi syntax trong Java code
- Dependency không tìm thấy
- Java version không khớp

**Fix:**
```bash
# Test build locally
cd app/backend/common
mvn clean package -DskipTests

# Check Java version
java -version  # Should be 21
```

**Nếu lỗi dependency:**
```xml
<!-- Check pom.xml dependencies -->
<dependency>
    <groupId>...</groupId>
    <artifactId>...</artifactId>
    <version>...</version>  <!-- Verify version exists -->
</dependency>
```

---

### 2. NPM Build Failed (Frontend)

**Lỗi:**
```
npm ERR! code ELIFECYCLE
npm ERR! errno 1
npm run build: command failed
```

**Nguyên nhân:**
- Lỗi syntax trong React/JS code
- Missing dependencies
- Environment variables không đúng

**Fix:**
```bash
# Test build locally
cd app/frontend
npm ci
npm run build

# Check Node version
node -v  # Should be 20.x
```

**Nếu lỗi dependencies:**
```bash
# Clean install
rm -rf node_modules package-lock.json
npm install
npm run build
```

---

### 3. Trivy Security Scan Failed

**Lỗi:**
```
Total: X (CRITICAL: Y)
Error: Process completed with exit code 1
```

**Nguyên nhân:**
- Docker image có CRITICAL vulnerabilities

**Fix Option 1: Update base image**
```dockerfile
# Backend Dockerfile
FROM eclipse-temurin:21-jre-alpine  # Use latest version

# Frontend Dockerfile
FROM nginx:1.27-alpine  # Use latest version
```

**Fix Option 2: Ignore unfixed vulnerabilities (đã có trong workflow)**
```yaml
- name: Run Trivy Vulnerability Scanner
  uses: aquasecurity/trivy-action@master
  with:
    exit-code: '1'
    severity: 'CRITICAL'
    ignore-unfixed: true  # ✅ Already set
```

**Fix Option 3: Temporarily disable Trivy**
```yaml
# Comment out Trivy step in main-ci.yml
# - name: Run Trivy Vulnerability Scanner
#   uses: aquasecurity/trivy-action@master
#   ...
```

---

### 4. Docker Login Failed

**Lỗi:**
```
Error: Cannot perform an interactive login from a non TTY device
Error: Process completed with exit code 1
```

**Nguyên nhân:**
- GitHub Secrets `DOCKER_USERNAME` hoặc `DOCKER_PASSWORD` không đúng
- Docker Hub account bị lock

**Fix:**
1. Verify Docker Hub credentials:
   ```bash
   docker login
   # Username: your_username
   # Password: your_password_or_token
   ```

2. Update GitHub Secrets:
   - Vào: `Settings` → `Secrets and variables` → `Actions`
   - Update `DOCKER_USERNAME` và `DOCKER_PASSWORD`
   - **Lưu ý:** Nên dùng Docker Hub Access Token thay vì password

3. Create Docker Hub Access Token:
   - Vào: https://hub.docker.com/settings/security
   - Click "New Access Token"
   - Copy token và update vào `DOCKER_PASSWORD` secret

---

### 5. Wait for Infrastructure Timeout

**Lỗi:**
```
⏳ Infrastructure workflow đang chạy...
Error: Process completed with exit code 1
```

**Nguyên nhân:**
- Infrastructure workflow chạy quá lâu (>60 phút)
- Infrastructure workflow failed

**Fix:**
1. Check infrastructure workflow status:
   ```bash
   # Vào GitHub Actions
   # Xem workflow "Infrastructure Provisioning & Configuration"
   ```

2. Nếu infrastructure đang chạy:
   - Đợi infrastructure hoàn thành
   - Sau đó re-run CI workflow

3. Nếu infrastructure failed:
   - Fix infrastructure issues trước
   - Sau đó mới chạy CI

---

## Cách Re-run Workflows

### Option 1: GitHub UI
1. Vào GitHub Actions
2. Click vào failed workflow run
3. Click nút **"Re-run failed jobs"** hoặc **"Re-run all jobs"**

### Option 2: GitHub CLI
```bash
# Install gh CLI first
# Windows: winget install --id GitHub.cli
# macOS: brew install gh

# Authenticate
gh auth login

# Re-run failed jobs only
gh run rerun <RUN_ID> --failed

# Re-run entire workflow
gh run rerun <RUN_ID>

# Trigger new manual run
gh workflow run main-ci.yml
```

### Option 3: Manual Trigger
1. Vào GitHub Actions
2. Chọn workflow **"Build & Release Docker"**
3. Click nút **"Run workflow"**
4. Chọn branch `main`
5. Nhập reason (optional)
6. Click **"Run workflow"**

---

## Workflow Dependencies

```
Infrastructure CD (infrastructure-cd.yml)
    ↓
    Creates: EKS, EC2, VPC, ALB Controller
    ↓
Build & Release Docker (main-ci.yml)
    ↓
    Waits for Infrastructure
    ↓
    Builds: Backend + Frontend images
    ↓
    Pushes to Docker Hub
    ↓
Continuous Deployment (deploy-cd.yml)
    ↓
    Triggered by: CI success
    ↓
    Deploys: Pods to EKS
```

**Thứ tự chạy đúng:**
1. Chạy Infrastructure CD trước (nếu chưa có infrastructure)
2. Đợi Infrastructure hoàn thành
3. Chạy Build & Release Docker (CI)
4. CD tự động trigger khi CI success

---

## Debug Commands

### Check Workflow Status
```bash
# List recent workflow runs
gh run list --limit 10

# View specific run
gh run view <RUN_ID>

# View failed logs
gh run view <RUN_ID> --log-failed

# Watch running workflow
gh run watch <RUN_ID>
```

### Check Docker Images
```bash
# List images on Docker Hub
docker search YOUR_USERNAME/productx

# Pull and test image locally
docker pull YOUR_USERNAME/productx-backend:sha-abc1234
docker run -p 8080:8080 YOUR_USERNAME/productx-backend:sha-abc1234
```

### Check EKS Deployment
```bash
# Configure kubectl
aws eks update-kubeconfig --name productx-eks --region ap-southeast-1

# Check pods
kubectl get pods -n productx

# Check if images exist
kubectl describe pod <POD_NAME> -n productx | grep Image
```

---

## Quick Fixes Checklist

- [ ] Infrastructure workflow đã hoàn thành?
- [ ] GitHub Secrets đã được set đúng?
  - [ ] `DOCKER_USERNAME`
  - [ ] `DOCKER_PASSWORD`
  - [ ] `AWS_ACCESS_KEY_ID`
  - [ ] `AWS_SECRET_ACCESS_KEY`
  - [ ] `EKS_CLUSTER_NAME`
- [ ] Docker Hub credentials còn valid?
- [ ] Backend code compile được locally?
- [ ] Frontend code build được locally?
- [ ] Base Docker images còn available?
- [ ] Network/firewall không block Docker Hub?

---

## Liên Hệ & Resources

- GitHub Actions Docs: https://docs.github.com/en/actions
- Docker Hub: https://hub.docker.com
- Trivy Docs: https://aquasecurity.github.io/trivy
- Maven Docs: https://maven.apache.org
- NPM Docs: https://docs.npmjs.com
