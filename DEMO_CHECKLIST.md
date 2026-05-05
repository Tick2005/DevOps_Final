# ✅ Demo Checklist - Quick Reference

## 🎬 Timeline (20 min)
- [ ] 0:00-2:00 | Introduction & Current State
- [ ] 2:00-4:00 | Source Code Modification
- [ ] 4:00-5:00 | Commit & Push
- [ ] 5:00-10:00 | CI Pipeline Execution
- [ ] 10:00-13:00 | CD Pipeline & Deployment
- [ ] 13:00-15:00 | Verification
- [ ] 15:00-17:00 | Monitoring Validation
- [ ] 17:00-19:30 | Failure Simulation
- [ ] 19:30-20:00 | Summary

## 📋 Pre-Demo Setup

### Browser Tabs (in order):
1. [ ] GitHub Repository
2. [ ] GitHub Actions
3. [ ] Application: https://www.tranduchuy.site
4. [ ] Grafana: https://monitoring.tranduchuy.site

### Terminal Commands Ready:
```bash
# Git commands
cd DevOps_Final
git status
git add app/backend/common/src/main/java/com/startupx/common/product/ProductRequest.java
git commit -m "Remove image size validation limit"
git push origin main

# Kubectl commands
kubectl get pods -n productx
kubectl delete pod <pod-name> -n productx
kubectl get pods -n productx -w
kubectl logs -l app=backend -n productx --tail=10
```

### Files to Open:
- [ ] ProductRequest.java (line 27)

### Test Data:
- [ ] Large base64 image (>100KB) ready to paste

## 🎯 Key Points to Demonstrate

### 5.1 Source Code Modification
- [ ] Show current code with validation
- [ ] Comment out line 27
- [ ] Save file

### 5.2 Commit & Push
- [ ] Clear commit message
- [ ] Push to main branch
- [ ] Show successful push

### 5.3 CI Pipeline
- [ ] Show workflow triggered
- [ ] Explain build steps
- [ ] **Highlight: Security scanning (Trivy)**
- [ ] Show Docker images pushed

### 5.4 CD Pipeline
- [ ] Show version increment (v1.0.1 → v1.0.2)
- [ ] Show rolling update
- [ ] **Highlight: Health checks**
- [ ] **Highlight: Smoke tests (CRUD)**

### 5.5 Verification
- [ ] Show version changed on UI
- [ ] Test large image upload (works now!)
- [ ] Verify HTTPS (lock icon)

### 5.6 Monitoring
- [ ] Show CPU usage
- [ ] Show Memory usage
- [ ] Show Pod status
- [ ] Explain metrics are real-time

### 5.7 Failure Simulation
- [ ] Delete backend pod
- [ ] Show Kubernetes auto-recovery
- [ ] Show no downtime
- [ ] Show in Grafana

## ⚠️ Backup Plans

### If CI/CD takes too long:
- [ ] Explain steps while waiting
- [ ] Show previous successful run
- [ ] Fast-forward in editing

### If deployment fails:
- [ ] Show rollback mechanism
- [ ] Explain failure handling
- [ ] This demonstrates resilience!

### If app not accessible:
- [ ] Use ALB hostname
- [ ] Explain DNS caching
- [ ] Show kubectl port-forward

### If Grafana no data:
- [ ] Wait 1-2 minutes
- [ ] Show Prometheus targets
- [ ] Explain metric intervals

## 🎤 Key Phrases

### Introduction:
> "Hệ thống CI/CD tự động với Kubernetes Tier 5 architecture"

### Source Code:
> "Loại bỏ giới hạn 100KB cho image upload"

### CI Pipeline:
> "Security scanning với Trivy - fail nếu có CRITICAL vulnerabilities"

### CD Pipeline:
> "Version tự động tăng từ v1.0.1 lên v1.0.2"

### Verification:
> "Thay đổi đã có hiệu lực - có thể upload ảnh lớn hơn 100KB"

### Monitoring:
> "Real-time metrics từ production environment"

### Failure:
> "Kubernetes tự động recover - self-healing capability"

## 📹 Recording Settings

- [ ] Resolution: 1080p minimum
- [ ] Frame rate: 30fps
- [ ] Audio: Clear microphone
- [ ] Disable notifications
- [ ] Close unnecessary apps
- [ ] Zoom in when showing code

## ✅ Final Check (5 min before)

- [ ] All tabs open and logged in
- [ ] Terminal ready with commands
- [ ] ProductRequest.java open at line 27
- [ ] Test data prepared
- [ ] Screen recording software ready
- [ ] Audio test done
- [ ] Deep breath taken 😊

---

**Print this and keep beside you during recording!**
