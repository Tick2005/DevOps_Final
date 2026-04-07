# Quick Start Guide - Tier 5 Implementation

## 🎯 Goal

Deploy StartupX application on Kubernetes with full CI/CD pipeline, monitoring, and HTTPS.

## 📋 Prerequisites Checklist

- [ ] AWS Account (or other cloud provider)
- [ ] Domain name registered
- [ ] Docker Hub account
- [ ] GitHub account
- [ ] Local tools installed:
  - [ ] Terraform >= 1.0
  - [ ] kubectl >= 1.28
  - [ ] git
  - [ ] SSH client

## 🚀 Implementation Steps

### Phase 1: Infrastructure (Day 1-2)

1. **Generate SSH Key**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/k3s-key -N ""
   ```

2. **Configure Terraform**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Provision Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   # Save outputs!
   ```

4. **Setup K3s Cluster**
   ```bash
   # SSH to master
   ssh -i ~/.ssh/k3s-key ubuntu@<master-ip>
   
   # Run setup script
   curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644 --disable traefik
   ```

5. **Configure kubectl Locally**
   ```bash
   scp -i ~/.ssh/k3s-key ubuntu@<master-ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
   sed -i 's/127.0.0.1/<master-ip>/g' ~/.kube/config
   kubectl get nodes
   ```

**✅ Checkpoint**: `kubectl get nodes` shows Ready

### Phase 2: Kubernetes Components (Day 2-3)

1. **Install Ingress Controller**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
   ```

2. **Install cert-manager**
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
   kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
   ```

3. **Install Metrics Server**
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   kubectl patch deployment metrics-server -n kube-system --type='json' \
     -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
   ```

**✅ Checkpoint**: All components running

### Phase 3: DNS & Domain (Day 3)

1. **Configure DNS**
   - Get master IP: `terraform output master_public_ip`
   - In domain registrar:
     - A record: `@` → `<master-ip>`
     - A record: `www` → `<master-ip>`

2. **Update Manifests**
   - Edit `k8s/ingress.yaml`: Replace `your-domain.com`
   - Edit `k8s/cert-manager-issuer.yaml`: Replace email

**✅ Checkpoint**: `nslookup your-domain.com` resolves correctly

### Phase 4: Application Deployment (Day 3-4)

1. **Build and Push Images**
   ```bash
   # Backend
   cd app/backend/common
   docker build -t your-username/startupx-backend:v1.0.0 .
   docker push your-username/startupx-backend:v1.0.0
   
   # Frontend
   cd ../../frontend
   docker build -t your-username/startupx-frontend:v1.0.0 .
   docker push your-username/startupx-frontend:v1.0.0
   ```

2. **Update Deployment Manifests**
   - Edit `k8s/backend-deployment.yaml`: Update image
   - Edit `k8s/frontend-deployment.yaml`: Update image

3. **Create Secrets**
   ```bash
   cp k8s/secret.yaml.template k8s/secret.yaml
   # Edit with your values (base64 encoded)
   ```

4. **Deploy Application**
   ```bash
   chmod +x scripts/deploy-app.sh
   ./scripts/deploy-app.sh
   ```

5. **Wait for Certificate**
   ```bash
   kubectl get certificate -n startupx -w
   # Wait until Ready: True
   ```

**✅ Checkpoint**: Application accessible via HTTPS

### Phase 5: CI/CD Pipeline (Day 4-5)

1. **Setup Docker Hub Token**
   - Go to Docker Hub → Account Settings → Security
   - Create new access token
   - Save token

2. **Configure GitHub Secrets**
   - Go to GitHub repo → Settings → Secrets
   - Add:
     - `DOCKERHUB_USERNAME`
     - `DOCKERHUB_TOKEN`
     - `KUBECONFIG` (base64 encoded)

3. **Get kubeconfig**
   ```bash
   cat ~/.kube/config | base64 -w 0
   ```

4. **Test Pipeline**
   ```bash
   # Make a change
   echo "// test" >> app/frontend/src/App.jsx
   git add .
   git commit -m "test: trigger pipeline"
   git push origin main
   ```

**✅ Checkpoint**: Pipeline runs successfully, app updates

### Phase 6: Monitoring (Day 5)

1. **Deploy Monitoring Stack**
   ```bash
   kubectl apply -f k8s/monitoring/
   ```

2. **Access Grafana**
   ```bash
   kubectl port-forward -n startupx svc/grafana-service 3000:3000
   # Open: http://localhost:3000
   # Login: admin/admin123
   ```

3. **Create Dashboards**
   - Import dashboard 315 (Kubernetes cluster)
   - Import dashboard 6417 (Deployments)
   - Create custom dashboard

**✅ Checkpoint**: Metrics visible in Grafana

### Phase 7: Testing & Verification (Day 6)

1. **Test Self-Healing**
   ```bash
   kubectl delete pod -n startupx -l app=backend --force
   kubectl get pods -n startupx -w
   ```

2. **Test Autoscaling**
   ```bash
   # Install hey
   go install github.com/rakyll/hey@latest
   
   # Generate load
   hey -z 60s -c 50 https://your-domain.com/api/products
   
   # Watch scaling
   kubectl get hpa -n startupx -w
   ```

3. **Test Rolling Update**
   ```bash
   kubectl set image deployment/frontend frontend=your-username/startupx-frontend:v1.1.0 -n startupx
   kubectl rollout status deployment/frontend -n startupx
   ```

**✅ Checkpoint**: All tests pass

### Phase 8: Documentation & Demo (Day 7)

1. **Prepare Demo**
   - Review [DEMO-GUIDE.md](docs/DEMO-GUIDE.md)
   - Practice demo flow
   - Prepare code change

2. **Record Video**
   - Follow mandatory scenario
   - 10-15 minutes
   - Clear audio and video

3. **Write Report**
   - Use academic template
   - Include all screenshots
   - Document decisions

4. **Export Artifacts**
   - Grafana dashboards (JSON)
   - Pipeline logs
   - kubectl outputs

**✅ Checkpoint**: All deliverables ready

## 📊 Progress Tracking

Use [TIER5-CHECKLIST.md](TIER5-CHECKLIST.md) to track detailed progress.

## ⏱️ Time Estimates

- Infrastructure Setup: 4-6 hours
- Kubernetes Components: 2-3 hours
- Application Deployment: 3-4 hours
- CI/CD Pipeline: 3-4 hours
- Monitoring Setup: 2-3 hours
- Testing & Verification: 2-3 hours
- Documentation & Demo: 4-6 hours

**Total**: 20-30 hours over 7 days

## 🆘 Quick Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n startupx
kubectl logs <pod-name> -n startupx
```

### Certificate not issuing
```bash
kubectl describe certificate startupx-tls -n startupx
kubectl logs -n cert-manager -l app=cert-manager
```

### HPA not working
```bash
kubectl top nodes
kubectl top pods -n startupx
```

### Pipeline failing
- Check GitHub Actions logs
- Verify secrets are set
- Test Docker Hub access

## 📚 Detailed Guides

- [Infrastructure Setup](docs/INFRASTRUCTURE-SETUP.md)
- [Deployment Guide](docs/DEPLOYMENT-GUIDE.md)
- [CI/CD Setup](docs/CICD-SETUP.md)
- [Monitoring Guide](docs/MONITORING-GUIDE.md)
- [Demo Guide](docs/DEMO-GUIDE.md)

## ✅ Final Checklist

Before submission:

- [ ] Infrastructure provisioned with Terraform
- [ ] K3s cluster running
- [ ] Application deployed on Kubernetes
- [ ] HTTPS working with valid certificate
- [ ] CI/CD pipeline functional
- [ ] Monitoring showing metrics
- [ ] HPA configured and tested
- [ ] Self-healing demonstrated
- [ ] Video recorded
- [ ] Report written
- [ ] All artifacts exported

## 🎓 Grading Criteria

- Infrastructure (20%): Terraform, K3s, idempotency
- Deployment (25%): K8s manifests, HPA, self-healing
- CI/CD (25%): Pipeline, security scanning, automation
- Monitoring (15%): Prometheus, Grafana, dashboards
- Documentation (10%): Report, clarity, completeness
- Demo (5%): Video quality, explanation

## 💡 Tips for Success

1. **Start Early**: Don't wait until last week
2. **Test Incrementally**: Verify each phase before moving on
3. **Document Everything**: Take screenshots as you go
4. **Ask Questions**: Use office hours if stuck
5. **Practice Demo**: Record multiple times if needed
6. **Backup Work**: Commit to git frequently
7. **Monitor Costs**: Use AWS free tier, stop instances when not testing

Good luck! 🚀
