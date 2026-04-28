# 🔍 SonarQube Setup Guide

## 📋 Overview

SonarQube is automatically deployed as part of the infrastructure workflow and integrated into the CI pipeline for code quality analysis.

---

## 🚀 Automatic Deployment

### **When**: During `infrastructure-cd.yml` workflow

### **What's Deployed**:
- ✅ SonarQube Community Edition (LTS)
- ✅ PostgreSQL database for SonarQube
- ✅ Persistent storage (15Gi total)
- ✅ ALB Ingress for public access

### **Resources**:
```yaml
SonarQube:
  CPU: 500m - 2000m
  Memory: 2Gi - 4Gi
  Storage: 10Gi (data + extensions + logs)

PostgreSQL:
  CPU: 250m - 500m
  Memory: 256Mi - 512Mi
  Storage: 5Gi
```

---

## 🔧 Initial Setup (After Infrastructure Deployment)

### **Step 1: Wait for SonarQube to be Ready**

```bash
# Check SonarQube pods
kubectl get pods -n sonarqube

# Expected output:
# NAME                                    READY   STATUS    RESTARTS   AGE
# sonarqube-xxxxxxxxxx-xxxxx              1/1     Running   0          5m
# sonarqube-postgresql-xxxxxxxxxx-xxxxx   1/1     Running   0          5m

# Wait for SonarQube to be ready (may take 5-10 minutes)
kubectl wait --for=condition=ready pod -l app=sonarqube -n sonarqube --timeout=600s
```

### **Step 2: Access SonarQube**

**Option A: Via Domain (Recommended)**
```
URL: http://sonarqube.tranduchuy.site
```

**Option B: Via Port Forward**
```bash
kubectl port-forward -n sonarqube svc/sonarqube 9000:9000
# Access: http://localhost:9000
```

### **Step 3: First Login**

1. **Default Credentials**:
   - Username: `admin`
   - Password: `admin`

2. **Change Password** (Required on first login):
   - You will be prompted to change the password
   - Choose a strong password
   - Save it to GitHub Secrets as `SONAR_ADMIN_PASSWORD`

### **Step 4: Generate Token for CI/CD**

1. **Navigate to**: User → My Account → Security → Generate Token

2. **Create Token**:
   - Name: `GitHub Actions CI/CD`
   - Type: `Global Analysis Token`
   - Expires: `No expiration` (or set expiration as needed)
   - Click: `Generate`

3. **Copy Token** (you won't see it again!)

4. **Add to GitHub Secrets**:
   ```
   Name: SONAR_TOKEN
   Value: <your-generated-token>
   ```

### **Step 5: Add SonarQube URL to GitHub Secrets**

```
Name: SONAR_HOST_URL
Value: http://sonarqube.tranduchuy.site
```

Or if using port-forward for CI (not recommended):
```
Value: http://sonarqube.sonarqube.svc.cluster.local:9000
```

---

## 📊 Project Configuration

### **Projects are Auto-Created by CI Pipeline**

The CI pipeline will automatically create two projects:
- `productx-backend` - Java/Spring Boot analysis
- `productx-frontend` - JavaScript/React analysis

### **Manual Project Setup (Optional)**

If you want to configure projects manually:

1. **Go to**: Administration → Projects → Management

2. **Create Project**:
   - Project Key: `productx-backend`
   - Display Name: `ProductX Backend`
   - Click: `Create`

3. **Repeat for Frontend**:
   - Project Key: `productx-frontend`
   - Display Name: `ProductX Frontend`

---

## 🎯 Quality Gates

### **Default Quality Gate**

SonarQube comes with a default "Sonar way" quality gate:
- Coverage on New Code: ≥ 80%
- Duplicated Lines on New Code: ≤ 3%
- Maintainability Rating on New Code: ≥ A
- Reliability Rating on New Code: ≥ A
- Security Rating on New Code: ≥ A
- Security Hotspots Reviewed: 100%

### **Custom Quality Gate for ProductX**

1. **Go to**: Quality Gates → Create

2. **Name**: `ProductX Quality Gate`

3. **Add Conditions**:
   ```
   On Overall Code:
   - Bugs: is greater than 0
   - Vulnerabilities: is greater than 0
   - Code Smells: is greater than 10
   - Coverage: is less than 70%
   - Duplicated Lines (%): is greater than 5%
   
   On New Code:
   - Bugs: is greater than 0
   - Vulnerabilities: is greater than 0
   - Code Smells: is greater than 5
   - Coverage: is less than 80%
   - Duplicated Lines (%): is greater than 3%
   ```

4. **Set as Default**: Click "Set as Default"

---

## 🔐 Security Configuration

### **Authentication**

1. **Go to**: Administration → Security → Users

2. **Create CI User** (Optional):
   - Login: `ci-user`
   - Name: `CI/CD User`
   - Password: (strong password)
   - Add to group: `sonar-users`

3. **Generate Token for CI User**

### **Permissions**

1. **Go to**: Administration → Security → Global Permissions

2. **Verify Permissions**:
   - `Execute Analysis`: sonar-users ✓
   - `Create Projects`: sonar-users ✓

---

## 📈 Monitoring & Maintenance

### **Check SonarQube Health**

```bash
# Check pod status
kubectl get pods -n sonarqube

# Check pod logs
kubectl logs -n sonarqube -l app=sonarqube --tail=100

# Check database logs
kubectl logs -n sonarqube -l app=sonarqube-postgresql --tail=100

# Check resource usage
kubectl top pods -n sonarqube
```

### **Access SonarQube Logs**

```bash
# Real-time logs
kubectl logs -n sonarqube -l app=sonarqube -f

# Last 500 lines
kubectl logs -n sonarqube -l app=sonarqube --tail=500
```

### **Backup SonarQube Data**

```bash
# Backup PostgreSQL database
kubectl exec -n sonarqube -it <postgresql-pod-name> -- \
  pg_dump -U sonarqube sonarqube > sonarqube-backup-$(date +%Y%m%d).sql

# Backup SonarQube data directory
kubectl exec -n sonarqube -it <sonarqube-pod-name> -- \
  tar czf /tmp/sonarqube-data.tar.gz /opt/sonarqube/data

kubectl cp sonarqube/<sonarqube-pod-name>:/tmp/sonarqube-data.tar.gz \
  ./sonarqube-data-backup-$(date +%Y%m%d).tar.gz
```

---

## 🔧 Troubleshooting

### **Issue 1: SonarQube Pod Not Starting**

**Symptoms**: Pod stuck in `CrashLoopBackOff` or `Pending`

**Check**:
```bash
kubectl describe pod -n sonarqube -l app=sonarqube
kubectl logs -n sonarqube -l app=sonarqube --previous
```

**Common Causes**:
1. **Insufficient Resources**: SonarQube needs at least 2Gi RAM
   ```bash
   # Check node resources
   kubectl top nodes
   ```

2. **vm.max_map_count too low**: Check init container logs
   ```bash
   kubectl logs -n sonarqube <pod-name> -c init-sysctl
   ```

3. **Database Connection Failed**: Check PostgreSQL
   ```bash
   kubectl logs -n sonarqube -l app=sonarqube-postgresql
   ```

**Solution**:
```bash
# Restart SonarQube
kubectl rollout restart deployment/sonarqube -n sonarqube

# If still failing, check events
kubectl get events -n sonarqube --sort-by='.lastTimestamp'
```

### **Issue 2: Cannot Access SonarQube via Domain**

**Check Ingress**:
```bash
kubectl get ingress -n sonarqube
kubectl describe ingress sonarqube-ingress -n sonarqube
```

**Check ALB**:
```bash
# Get ALB URL
kubectl get ingress sonarqube-ingress -n sonarqube \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test ALB directly
curl -I http://<ALB-URL>/api/system/status
```

**Check DNS**:
```bash
nslookup sonarqube.tranduchuy.site
```

### **Issue 3: CI Pipeline Fails at SonarQube Scan**

**Check**:
1. **SONAR_TOKEN is valid**:
   ```bash
   curl -u "<token>:" http://sonarqube.tranduchuy.site/api/authentication/validate
   ```

2. **SONAR_HOST_URL is correct**:
   ```
   Should be: http://sonarqube.tranduchuy.site
   NOT: https:// (unless you configured SSL)
   ```

3. **SonarQube is accessible from GitHub Actions**:
   - If using internal URL, ensure it's reachable
   - If using public URL, ensure ALB is working

**Solution**:
```bash
# Test from a pod in the cluster
kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl -v http://sonarqube.sonarqube.svc.cluster.local:9000/api/system/status
```

### **Issue 4: Quality Gate Always Fails**

**Check Quality Gate Settings**:
1. Go to: Quality Gates → Your Gate
2. Review conditions
3. Adjust thresholds if too strict

**Check Project Analysis**:
1. Go to: Projects → Your Project
2. Check: Activity tab for analysis history
3. Review: Issues, Coverage, Duplications

---

## 📊 Integration with CI/CD

### **How It Works**

```
┌─────────────────────────────────────────────────────────────┐
│  CI PIPELINE WITH SONARQUBE                                 │
└─────────────────────────────────────────────────────────────┘

1. Code Push to main branch
   ↓
2. infrastructure-cd.yml (if needed)
   ↓
3. main-ci.yml starts
   ↓
4. Job: sonarqube-scan
   ├─ Checkout code (full history)
   ├─ Setup Java 21
   ├─ Build & Analyze Backend (Maven + SonarQube)
   ├─ Setup Node.js 20
   ├─ Run Frontend Tests with Coverage
   ├─ Analyze Frontend (SonarQube Scanner)
   └─ Check Quality Gate (continue even if fails)
   ↓
5. Job: build-backend (depends on sonarqube-scan)
   ↓
6. Job: build-frontend (depends on sonarqube-scan)
   ↓
7. Deploy to Staging
   ↓
8. Deploy to Production
```

### **View Analysis Results**

After each CI run:
1. Go to SonarQube dashboard
2. Navigate to Projects
3. Select `productx-backend` or `productx-frontend`
4. Review:
   - Bugs
   - Vulnerabilities
   - Code Smells
   - Coverage
   - Duplications
   - Security Hotspots

---

## 🎓 Best Practices

### **1. Review SonarQube Reports Regularly**
- Check after each deployment
- Address critical issues immediately
- Plan to fix major issues in next sprint

### **2. Set Realistic Quality Gates**
- Start with lenient gates
- Gradually increase standards
- Don't block deployments for minor issues

### **3. Focus on New Code**
- Prioritize quality of new code
- Gradually improve legacy code
- Use "Clean as You Code" approach

### **4. Integrate with PR Reviews**
- Review SonarQube findings before merging
- Add SonarQube link to PR description
- Discuss findings in code reviews

### **5. Monitor Technical Debt**
- Track technical debt over time
- Allocate time to reduce debt
- Set debt reduction goals

---

## 📚 Additional Resources

### **SonarQube Documentation**
- Official Docs: https://docs.sonarqube.org/latest/
- Java Analysis: https://docs.sonarqube.org/latest/analysis/languages/java/
- JavaScript Analysis: https://docs.sonarqube.org/latest/analysis/languages/javascript/

### **Quality Gates**
- Quality Gates Guide: https://docs.sonarqube.org/latest/user-guide/quality-gates/

### **CI/CD Integration**
- GitHub Actions: https://docs.sonarqube.org/latest/analysis/github-integration/

---

## 🎯 Quick Reference

### **Access URLs**
```
SonarQube Web:  http://sonarqube.tranduchuy.site
Default Login:  admin / admin (change on first login)
Backend Project: http://sonarqube.tranduchuy.site/dashboard?id=productx-backend
Frontend Project: http://sonarqube.tranduchuy.site/dashboard?id=productx-frontend
```

### **Required GitHub Secrets**
```
SONAR_TOKEN:           <generated-from-sonarqube>
SONAR_HOST_URL:        http://sonarqube.tranduchuy.site
SONARQUBE_DB_PASSWORD: <set-in-terraform-variables>
```

### **Useful Commands**
```bash
# Check SonarQube status
kubectl get pods -n sonarqube

# Access SonarQube logs
kubectl logs -n sonarqube -l app=sonarqube -f

# Port forward SonarQube
kubectl port-forward -n sonarqube svc/sonarqube 9000:9000

# Restart SonarQube
kubectl rollout restart deployment/sonarqube -n sonarqube

# Check SonarQube health
curl http://sonarqube.tranduchuy.site/api/system/status
```

---

**Document Version**: 1.0
**Last Updated**: 2026-04-28
**Maintained By**: DevOps Team
