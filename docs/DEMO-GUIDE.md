# Mandatory Demonstration Scenario Guide

## Overview

This guide walks through the mandatory demonstration scenario required for the final project assessment. Follow these steps exactly as specified in the project requirements.

## Pre-Demo Checklist

Before starting the demo, ensure:

- [ ] Kubernetes cluster is running and accessible
- [ ] Application is deployed and working
- [ ] HTTPS certificate is valid
- [ ] Monitoring is set up and showing metrics
- [ ] CI/CD pipeline is configured
- [ ] Screen recording software is ready
- [ ] All browser tabs are prepared

## Demo Flow

### 1. Source Code Modification

**Objective**: Make a visible change to demonstrate end-to-end deployment

**Example Changes**:

#### Option A: Update UI Text (Recommended)
```javascript
// app/frontend/src/App.jsx
// Change line ~15
<h1>StartupX Product Manager v2.0 - DEMO UPDATE</h1>
```

#### Option B: Add Feature Flag
```javascript
// app/frontend/src/App.jsx
const DEMO_MODE = true;

{DEMO_MODE && (
  <div style={{background: 'yellow', padding: '10px'}}>
    🎬 DEMO VERSION - Updated at {new Date().toLocaleString()}
  </div>
)}
```

#### Option C: Backend Change
```java
// app/backend/common/src/main/java/com/startupx/controller/ProductController.java
@GetMapping("/version")
public String getVersion() {
    return "v2.0-demo-" + System.currentTimeMillis();
}
```

**What to Show**:
- Open the file in your editor
- Show the BEFORE state
- Make the change
- Show the AFTER state
- Explain what changed and why it's visible

### 2. Commit and Push

**Commands**:
```bash
# Check status
git status

# Add changes
git add app/frontend/src/App.jsx

# Commit with clear message
git commit -m "demo: update version to v2.0 for demonstration"

# Push to trigger pipeline
git push origin main
```

**What to Show**:
- Terminal with git commands
- Commit message
- Push confirmation
- Note the commit SHA

### 3. CI Pipeline Execution

**Navigate to**: GitHub → Actions → CI Pipeline

**What to Show**:

1. **Pipeline Triggered**
   - Show the workflow started automatically
   - Show commit message and SHA

2. **Lint and Test Stage**
   - Code checkout
   - Dependency installation
   - Linting execution
   - Build completion

3. **Security Scanning Stage**
   - Trivy scanning backend
   - Trivy scanning frontend
   - Vulnerability report
   - Pass/fail status

4. **Build and Push Stage**
   - Docker image build for backend
   - Docker image build for frontend
   - Image tagging with commit SHA
   - Push to Docker Hub
   - Image scanning results

**Explain**:
- What each stage does
- Why security scanning is important
- How images are versioned
- Any warnings or issues encountered

### 4. CD Pipeline Execution

**Navigate to**: GitHub → Actions → CD Pipeline

**What to Show**:

1. **Automatic Trigger**
   - CD starts after CI completes
   - Workflow dependency

2. **Deployment Stages**
   - kubectl configuration
   - Image tag updates
   - Kubernetes manifest application
   - Deployment rollout

3. **Verification**
   - Deployment status
   - Pod status
   - Service status
   - Rollout completion

**Terminal Commands** (parallel):
```bash
# Watch pods update
kubectl get pods -n startupx -w

# Watch rollout
kubectl rollout status deployment/frontend -n startupx
kubectl rollout status deployment/backend -n startupx

# Check deployment
kubectl describe deployment frontend -n startupx | grep Image
```

### 5. Application Verification

**What to Show**:

1. **Access Application**
   - Open browser
   - Navigate to https://your-domain.com
   - Show HTTPS certificate (click padlock)
   - Verify certificate is valid

2. **Verify Change**
   - Show the visible change you made
   - Compare with before (if you have screenshot)
   - Demonstrate functionality works

3. **Test API** (optional but impressive)
   ```bash
   curl https://your-domain.com/api/products
   ```

4. **Check Deployment Info**
   ```bash
   # Show new image version
   kubectl get deployment frontend -n startupx -o jsonpath='{.spec.template.spec.containers[0].image}'
   
   # Show pod creation time
   kubectl get pods -n startupx -o wide
   ```

### 6. Monitoring Validation

**What to Show**:

1. **Open Grafana**
   ```bash
   kubectl port-forward -n startupx svc/grafana-service 3000:3000
   ```
   - Navigate to http://localhost:3000
   - Login (admin/admin123)

2. **Show Dashboards**
   - CPU usage graphs
   - Memory usage graphs
   - Pod status
   - Network traffic (if available)

3. **Explain Metrics**
   - What each metric means
   - Current resource usage
   - Normal vs abnormal patterns

4. **Show Prometheus** (optional)
   ```bash
   kubectl port-forward -n startupx svc/prometheus-service 9090:9090
   ```
   - Show targets are UP
   - Run sample query
   - Show metrics collection

### 7. Failure Simulation

**Objective**: Demonstrate self-healing and resilience

#### Test 1: Pod Deletion

```bash
# Get current pods
kubectl get pods -n startupx

# Delete a frontend pod
kubectl delete pod -n startupx -l app=frontend --force --grace-period=0

# Watch it recreate
kubectl get pods -n startupx -w
```

**What to Show**:
- Pod is deleted
- Kubernetes automatically creates new pod
- New pod becomes ready
- Application remains accessible
- Monitoring shows the event

#### Test 2: Deployment Rollback (Optional)

```bash
# Check rollout history
kubectl rollout history deployment/frontend -n startupx

# Rollback to previous version
kubectl rollout undo deployment/frontend -n startupx

# Watch rollback
kubectl rollout status deployment/frontend -n startupx
```

#### Test 3: HPA Scaling (If Time Permits)

```bash
# Check current HPA status
kubectl get hpa -n startupx

# Generate load (in separate terminal)
hey -z 60s -c 50 https://your-domain.com/api/products

# Watch HPA scale up
kubectl get hpa -n startupx -w

# Watch pods scale
kubectl get pods -n startupx -w
```

**What to Show**:
- Initial replica count
- Load generation
- HPA detecting high CPU/memory
- Pods scaling up
- Metrics in Grafana during load
- Pods scaling down after load stops

## Demo Script Template

Use this script for your video:

```
[INTRO]
"Hello, I'm demonstrating the Tier 5 Kubernetes-based deployment for StartupX application."

[SECTION 1: CODE CHANGE]
"First, I'll make a visible change to the application..."
[Show code change]
"I'm updating the version number in the frontend to v2.0."

[SECTION 2: COMMIT & PUSH]
"Now I'll commit and push this change to trigger the CI/CD pipeline..."
[Show git commands]
"The commit SHA is [SHA]. This will trigger our automated pipeline."

[SECTION 3: CI PIPELINE]
"Let's watch the CI pipeline execute..."
[Show GitHub Actions]
"The pipeline is running linting, building, security scanning, and pushing Docker images."
[Explain each stage]

[SECTION 4: CD PIPELINE]
"After CI completes, the CD pipeline automatically deploys to Kubernetes..."
[Show deployment]
"The new images are being deployed with rolling update strategy."

[SECTION 5: VERIFICATION]
"Let's verify the deployment..."
[Show website]
"As you can see, the change is now live on the production site with valid HTTPS."

[SECTION 6: MONITORING]
"Here's our monitoring dashboard..."
[Show Grafana]
"We can see CPU usage, memory usage, and pod status in real-time."

[SECTION 7: SELF-HEALING]
"Now I'll demonstrate self-healing by deleting a pod..."
[Delete pod]
"Kubernetes automatically recreates the pod. The application remains available."

[CONCLUSION]
"This demonstrates a complete production-grade CI/CD system with Kubernetes orchestration."
```

## Recording Tips

### Video Recording

1. **Screen Resolution**: 1920x1080 recommended
2. **Frame Rate**: 30 FPS minimum
3. **Audio**: Clear microphone, no background noise
4. **Duration**: 10-15 minutes ideal

### What to Record

- [ ] Full screen or relevant windows only
- [ ] Terminal with clear font size (14-16pt)
- [ ] Browser with visible URL bar
- [ ] GitHub Actions full workflow
- [ ] Grafana dashboards
- [ ] kubectl commands and outputs

### Editing Tips

- Add timestamps for each section
- Zoom in on important details
- Add text annotations if needed
- Speed up long waits (2x-4x)
- Keep audio commentary throughout

## Common Issues & Solutions

### Issue: Pipeline Doesn't Trigger

**Solution**:
```bash
# Check webhook
# Go to GitHub → Settings → Webhooks
# Verify recent deliveries

# Manual trigger
gh workflow run ci.yml
```

### Issue: Deployment Fails

**Solution**:
```bash
# Check pod status
kubectl get pods -n startupx
kubectl describe pod <pod-name> -n startupx
kubectl logs <pod-name> -n startupx

# Check events
kubectl get events -n startupx --sort-by='.lastTimestamp'
```

### Issue: Change Not Visible

**Solution**:
```bash
# Force browser refresh (Ctrl+Shift+R)
# Clear browser cache
# Check image version
kubectl describe deployment frontend -n startupx | grep Image
```

### Issue: Monitoring Not Showing Data

**Solution**:
```bash
# Restart port-forward
kubectl port-forward -n startupx svc/grafana-service 3000:3000

# Check Prometheus targets
kubectl port-forward -n startupx svc/prometheus-service 9090:9090
# Visit: http://localhost:9090/targets
```

## Post-Demo Checklist

After recording:

- [ ] Review video for clarity
- [ ] Check audio quality
- [ ] Verify all required sections covered
- [ ] Ensure timestamps are visible
- [ ] Test video playback
- [ ] Export in compatible format (MP4)
- [ ] Keep file size reasonable (<500MB)

## Submission

Include in your submission:

1. **Video file** (MP4 format)
2. **Screenshots** of key moments
3. **Pipeline logs** (exported from GitHub)
4. **kubectl outputs** (saved to text files)
5. **Grafana dashboard** (exported JSON)

## Grading Criteria

Your demo will be evaluated on:

- ✅ Completeness (all 7 sections covered)
- ✅ Clarity (easy to follow and understand)
- ✅ Technical correctness (everything works)
- ✅ Explanation quality (good commentary)
- ✅ Professional presentation

## Practice Run

Before final recording:

1. Do a complete dry run
2. Time each section
3. Note any issues
4. Prepare backup plans
5. Test recording software
6. Check audio levels

Good luck with your demonstration! 🎬
