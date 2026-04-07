# CI/CD Pipeline Setup Guide

## Overview

The CI/CD pipeline consists of two workflows:
- **CI Pipeline**: Builds, tests, scans, and pushes Docker images
- **CD Pipeline**: Deploys to Kubernetes cluster

## Prerequisites

- GitHub repository
- Docker Hub account
- Kubernetes cluster with kubectl access
- Domain configured with HTTPS

## Step 1: Setup Docker Hub

1. Create Docker Hub account at https://hub.docker.com

2. Create two repositories:
   - `startupx-backend`
   - `startupx-frontend`

3. Generate access token:
   - Go to Account Settings → Security → New Access Token
   - Name: `github-actions`
   - Permissions: Read, Write, Delete
   - Save the token securely

## Step 2: Configure GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions

Add the following secrets:

### Docker Hub Credentials
```
DOCKERHUB_USERNAME: your-dockerhub-username
DOCKERHUB_TOKEN: your-access-token-from-step-1
```

### Kubernetes Access
```
KUBECONFIG: base64-encoded-kubeconfig
```

To get base64-encoded kubeconfig:
```bash
cat ~/.kube/config | base64 -w 0
```

Copy the entire output and paste as the secret value.

## Step 3: Update Workflow Files

1. Update `.github/workflows/ci.yml`:
   - Verify `DOCKERHUB_USERNAME` secret name matches
   - Adjust build context paths if needed

2. Update `.github/workflows/cd.yml`:
   - Verify manifest paths are correct
   - Adjust namespace if changed

## Step 4: Update Kubernetes Manifests

Ensure your manifests reference the correct image names:

`k8s/backend-deployment.yaml`:
```yaml
image: your-dockerhub-username/startupx-backend:latest
```

`k8s/frontend-deployment.yaml`:
```yaml
image: your-dockerhub-username/startupx-frontend:latest
```

## Step 5: Test CI Pipeline

1. Make a small change to your code
2. Commit and push to main branch:
```bash
git add .
git commit -m "test: trigger CI pipeline"
git push origin main
```

3. Go to GitHub → Actions tab
4. Watch the CI pipeline execute

### CI Pipeline Stages

The pipeline will:
1. ✅ Checkout code
2. ✅ Setup Node.js and Java
3. ✅ Cache dependencies
4. ✅ Lint frontend code
5. ✅ Build frontend
6. ✅ Build backend
7. ✅ Run security scans (Trivy)
8. ✅ Build Docker images
9. ✅ Push to Docker Hub
10. ✅ Scan Docker images

## Step 6: Test CD Pipeline

After CI completes successfully:

1. CD pipeline triggers automatically
2. Watch deployment in GitHub Actions
3. Verify in cluster:
```bash
kubectl get pods -n startupx
kubectl rollout status deployment/backend -n startupx
kubectl rollout status deployment/frontend -n startupx
```

### CD Pipeline Stages

The pipeline will:
1. ✅ Checkout code
2. ✅ Configure kubectl
3. ✅ Update image tags
4. ✅ Apply Kubernetes manifests
5. ✅ Wait for deployments
6. ✅ Verify deployment status

## Step 7: Verify End-to-End Flow

### Complete Test Scenario

1. **Make visible change**:
```javascript
// app/frontend/src/App.jsx
<h1>StartupX Product Manager v2.0</h1>
```

2. **Commit and push**:
```bash
git add app/frontend/src/App.jsx
git commit -m "feat: update version to 2.0"
git push origin main
```

3. **Watch CI pipeline**:
   - Go to GitHub Actions
   - Click on the running workflow
   - Verify all steps pass
   - Note the image SHA

4. **Watch CD pipeline**:
   - Automatically triggers after CI
   - Deploys new version to cluster

5. **Verify deployment**:
```bash
# Check pods are updated
kubectl get pods -n startupx

# Check image versions
kubectl describe deployment backend -n startupx | grep Image
kubectl describe deployment frontend -n startupx | grep Image
```

6. **Access application**:
   - Open https://your-domain.com
   - Verify the change is visible
   - Check HTTPS certificate is valid

## Security Scanning Configuration

### Trivy Configuration

The pipeline uses Trivy for vulnerability scanning:

- **Scan types**: Filesystem and container images
- **Severity levels**: CRITICAL, HIGH
- **Exit code**: Currently set to 0 (warning only)

To fail on vulnerabilities:

Edit `.github/workflows/ci.yml`:
```yaml
exit-code: '1'  # Change from '0' to '1'
```

### Handling Vulnerabilities

If vulnerabilities are found:

1. **Review the scan results** in GitHub Actions
2. **Update dependencies** to patched versions
3. **Document accepted risks** in your report if updates break functionality
4. **Use allowlists** for false positives:

Create `.trivyignore`:
```
# Example: Ignore specific CVE
CVE-2023-12345

# Ignore with expiration
CVE-2023-67890 exp:2024-12-31
```

## Pipeline Optimization

### Dependency Caching

Already configured in the pipeline:

```yaml
- name: Cache Maven dependencies
  uses: actions/cache@v3
  with:
    path: ~/.m2/repository
    key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
```

### Docker Layer Caching

Already configured:

```yaml
cache-from: type=registry,ref=${{ env.BACKEND_IMAGE_NAME }}:buildcache
cache-to: type=registry,ref=${{ env.BACKEND_IMAGE_NAME }}:buildcache,mode=max
```

## Monitoring Pipeline

### View Pipeline Logs

```bash
# Using GitHub CLI
gh run list
gh run view <run-id>
gh run view <run-id> --log
```

### Pipeline Metrics

Track in your report:
- Average pipeline duration
- Success rate
- Failed stages
- Build time improvements from caching

## Troubleshooting

### CI Pipeline Fails

**Build errors**:
```bash
# Test locally first
cd app/frontend
npm install
npm run build

cd ../backend/common
mvn clean package
```

**Security scan failures**:
- Review Trivy output
- Update vulnerable dependencies
- Document accepted risks

**Docker push fails**:
- Verify Docker Hub credentials
- Check repository exists
- Verify token has write permissions

### CD Pipeline Fails

**kubectl connection fails**:
```bash
# Test kubeconfig locally
export KUBECONFIG=~/.kube/config
kubectl cluster-info
```

**Deployment timeout**:
```bash
# Check pod status
kubectl get pods -n startupx
kubectl describe pod <pod-name> -n startupx
kubectl logs <pod-name> -n startupx
```

**Image pull errors**:
- Verify image exists in Docker Hub
- Check image tag is correct
- Ensure repository is public or add imagePullSecrets

## Advanced: Multi-Environment Setup

### Add Staging Environment

1. Create staging namespace:
```yaml
# k8s/staging/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: startupx-staging
```

2. Update CD workflow:
```yaml
jobs:
  deploy-staging:
    # Deploy to staging automatically
    
  deploy-production:
    needs: deploy-staging
    # Require manual approval
    environment:
      name: production
      url: https://your-domain.com
```

3. Configure environment in GitHub:
   - Settings → Environments → New environment
   - Name: `production`
   - Add required reviewers

## Verification Checklist

- [ ] Docker Hub repositories created
- [ ] GitHub secrets configured
- [ ] CI pipeline runs successfully
- [ ] Docker images pushed to registry
- [ ] Security scans complete
- [ ] CD pipeline deploys automatically
- [ ] Application updates visible
- [ ] Rollout completes without errors
- [ ] All pipeline logs captured for report

## Documentation for Report

Capture the following for your technical report:

1. **Pipeline architecture diagram**
2. **Screenshots of successful CI run**
3. **Screenshots of successful CD run**
4. **Security scan results**
5. **Before/after deployment comparison**
6. **Pipeline execution times**
7. **Rollout status outputs**

## Next Steps

- Setup monitoring: [Monitoring Guide](./MONITORING-GUIDE.md)
- Prepare demo scenario: [Demo Guide](./DEMO-GUIDE.md)
