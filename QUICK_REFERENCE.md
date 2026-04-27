# Quick Reference Guide

## Essential Commands Cheat Sheet

### GitHub Secrets Setup

```bash
# Set all required secrets at once
gh secret set AWS_ACCESS_KEY_ID --body "YOUR_KEY"
gh secret set AWS_SECRET_ACCESS_KEY --body "YOUR_SECRET"
gh secret set DOCKER_USERNAME --body "YOUR_USERNAME"
gh secret set DOCKER_PASSWORD --body "YOUR_TOKEN"
gh secret set EKS_CLUSTER_NAME --body "productx-eks-cluster"
gh secret set DOMAIN_NAME --body "tranduchuy.site"
gh secret set DB_PASSWORD --body "SecurePassword123!"
gh secret set DB_HOST --body "10.0.1.100"
gh secret set DB_NAME --body "productx_db"
gh secret set DB_USERNAME --body "productx_user"
gh secret set NFS_SERVER_IP --body "10.0.1.50"

# Verify all secrets
gh secret list
```

---

### Workflow Execution

```bash
# 1. Setup infrastructure (one-time)
gh workflow run infrastructure-cd.yml

# 2. Build and deploy (automatic on push, or manual)
gh workflow run build-ci.yml

# 3. Deploy specific version
gh workflow run deploy-cd.yml \
  -f image_tag="sha-abc1234" \
  -f reason="Deploy specific version"

# Watch workflow
gh run watch

# View logs
gh run view --log
```

---

### Kubernetes Quick Commands

```bash
# Configure kubectl
aws eks update-kubeconfig --name productx-eks-cluster --region ap-southeast-1

# Check everything
kubectl get all -n productx

# Check pods
kubectl get pods -n productx
kubectl describe pod <pod-name> -n productx
kubectl logs -l app=backend -n productx --tail=100 -f

# Check deployments
kubectl get deployments -n productx
kubectl rollout status deployment/backend -n productx

# Check services
kubectl get svc -n productx
kubectl get endpoints -n productx

# Check ingress
kubectl get ingress -n productx
kubectl describe ingress app-ingress -n productx

# Check HPA
kubectl get hpa -n productx

# Port forward for local testing
kubectl port-forward -n productx svc/backend-svc 8080:8080
kubectl port-forward -n productx svc/frontend-svc 8081:80
```

---

### Testing Commands

```bash
# Set domain
DOMAIN="www.tranduchuy.site"

# Health checks
curl https://$DOMAIN/actuator/health
curl https://$DOMAIN/

# API tests
curl https://$DOMAIN/api/products
curl https://$DOMAIN/api/products/1

# Create product
curl -X POST https://$DOMAIN/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "price": 99.99,
    "color": "Blue",
    "category": "Test",
    "stock": 10,
    "description": "Test",
    "image": "https://via.placeholder.com/150"
  }'

# Update product
curl -X PUT https://$DOMAIN/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Product",
    "price": 149.99,
    "color": "Red",
    "category": "Test",
    "stock": 20,
    "description": "Updated",
    "image": "https://via.placeholder.com/150"
  }'

# Delete product
curl -X DELETE https://$DOMAIN/api/products/1
```

---

### Monitoring Access

```bash
# Grafana (via port forward)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open: http://localhost:3000
# Default: admin / prom-operator

# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open: http://localhost:9090

# Alertmanager
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Open: http://localhost:9093
```

---

### Useful Prometheus Queries

```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total{namespace="productx"}[5m])) by (pod)

# Memory usage by pod
sum(container_memory_working_set_bytes{namespace="productx"}) by (pod)

# HTTP request rate
rate(http_server_requests_seconds_count{namespace="productx"}[5m])

# Error rate
sum(rate(http_server_requests_seconds_count{namespace="productx",status=~"5.."}[5m])) / 
sum(rate(http_server_requests_seconds_count{namespace="productx"}[5m])) * 100

# Response time (p95)
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{namespace="productx"}[5m]))

# Pod restarts
kube_pod_container_status_restarts_total{namespace="productx"}

# Database connections
hikaricp_connections_active{namespace="productx"}
```

---

### Troubleshooting

```bash
# Pod not starting
kubectl describe pod <pod-name> -n productx
kubectl logs <pod-name> -n productx
kubectl get events -n productx --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n productx
kubectl top nodes

# Check secrets
kubectl get secrets -n productx
kubectl describe secret app-secrets -n productx

# Check ConfigMap
kubectl get configmap -n productx
kubectl describe configmap app-config -n productx

# Restart deployment
kubectl rollout restart deployment/backend -n productx
kubectl rollout restart deployment/frontend -n productx

# Rollback deployment
kubectl rollout undo deployment/backend -n productx
kubectl rollout history deployment/backend -n productx
kubectl rollout undo deployment/backend -n productx --to-revision=2

# Scale deployment
kubectl scale deployment backend -n productx --replicas=3

# Delete and recreate pod
kubectl delete pod <pod-name> -n productx
```

---

### Docker Commands

```bash
# Build images
cd app/backend/common
docker build -t productx-backend:test .

cd app/frontend
docker build -t productx-frontend:test .

# Run with Docker Compose
docker-compose up -d
docker-compose ps
docker-compose logs -f
docker-compose down

# Security scan
trivy image productx-backend:test
trivy image productx-frontend:test
```

---

### Database Access

```bash
# Via Docker Compose
docker-compose exec postgres psql -U productx_user -d productx_db

# Via EC2 instance
ssh ec2-user@<db-host>
sudo -u postgres psql
\c productx_db
\dt
SELECT * FROM products LIMIT 5;
\q
```

---

### Log Management

```bash
# View logs
kubectl logs -l app=backend -n productx --tail=100
kubectl logs -l app=frontend -n productx --tail=100

# Follow logs
kubectl logs -l app=backend -n productx -f

# Logs with timestamps
kubectl logs -l app=backend -n productx --timestamps=true

# Logs from last hour
kubectl logs -l app=backend -n productx --since=1h

# Previous pod logs (if crashed)
kubectl logs <pod-name> -n productx --previous

# Export logs
kubectl logs -l app=backend -n productx > backend-logs.txt

# Filter logs
kubectl logs -l app=backend -n productx | grep ERROR
kubectl logs -l app=backend -n productx | grep "/api/products"

# Using stern (multi-pod)
stern backend -n productx
stern "backend|frontend" -n productx
```

---

### Load Testing

```bash
# Apache Bench
ab -n 1000 -c 10 https://$DOMAIN/api/products

# k6
k6 run load-test.js

# Stress test (trigger alerts)
kubectl run stress-test -n productx --image=polinux/stress --rm -it -- stress --cpu 4 --timeout 600s
```

---

### Security

```bash
# Scan images
trivy image productx-backend:latest
trivy image --severity HIGH,CRITICAL productx-backend:latest

# Check SSL certificate
openssl s_client -connect $DOMAIN:443 -servername $DOMAIN < /dev/null
echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -dates

# OWASP ZAP scan
docker run -t owasp/zap2docker-stable zap-baseline.py -t https://$DOMAIN -r zap-report.html
```

---

### Cleanup

```bash
# Delete namespace (removes all resources)
kubectl delete namespace productx

# Delete specific resources
kubectl delete deployment backend -n productx
kubectl delete service backend-svc -n productx
kubectl delete ingress app-ingress -n productx

# Clean up Docker
docker system prune -a
docker volume prune

# Clean up local images
docker rmi productx-backend:test
docker rmi productx-frontend:test
```

---

### Emergency Procedures

#### Application Down
```bash
# 1. Check pod status
kubectl get pods -n productx

# 2. Check logs
kubectl logs -l app=backend -n productx --tail=100

# 3. Check events
kubectl get events -n productx --sort-by='.lastTimestamp'

# 4. Restart if needed
kubectl rollout restart deployment/backend -n productx

# 5. If still down, rollback
kubectl rollout undo deployment/backend -n productx
```

#### High Error Rate
```bash
# 1. Check Grafana dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# 2. Check application logs
kubectl logs -l app=backend -n productx | grep ERROR

# 3. Check database connectivity
kubectl exec <backend-pod> -n productx -- curl http://localhost:8080/actuator/health

# 4. Scale up if needed
kubectl scale deployment backend -n productx --replicas=4
```

#### Database Issues
```bash
# 1. Check database connectivity from pod
kubectl exec <backend-pod> -n productx -- nc -zv <db-host> 5432

# 2. Check database logs
ssh ec2-user@<db-host>
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# 3. Check connection pool
kubectl logs -l app=backend -n productx | grep "HikariPool"

# 4. Restart backend if needed
kubectl rollout restart deployment/backend -n productx
```

---

### Performance Optimization

```bash
# Check resource usage
kubectl top pods -n productx
kubectl top nodes

# Check HPA status
kubectl get hpa -n productx
kubectl describe hpa backend-hpa -n productx

# Adjust HPA
kubectl edit hpa backend-hpa -n productx

# Adjust resource limits
kubectl edit deployment backend -n productx

# Check slow queries (if enabled)
kubectl logs -l app=backend -n productx | grep "slow query"
```

---

### Backup & Restore

```bash
# Backup database
ssh ec2-user@<db-host>
sudo -u postgres pg_dump productx_db > backup-$(date +%Y%m%d).sql

# Restore database
sudo -u postgres psql productx_db < backup-20240101.sql

# Backup Kubernetes resources
kubectl get all -n productx -o yaml > productx-backup.yaml

# Restore Kubernetes resources
kubectl apply -f productx-backup.yaml
```

---

## File Locations

| Resource | Location |
|----------|----------|
| GitHub Secrets Guide | `GITHUB_SECRETS.md` |
| Workflow Documentation | `WORKFLOW_SEQUENCE.md` |
| Testing Guide | `TESTING_GUIDE.md` |
| Monitoring Guide | `MONITORING_GUIDE.md` |
| Bug Fixes Summary | `BUGS_FIXED_SUMMARY.md` |
| Terraform Files | `terraform/` |
| Kubernetes Manifests | `kubernetes/` |
| Ansible Playbooks | `ansible/playbooks/` |
| Backend Code | `app/backend/common/` |
| Frontend Code | `app/frontend/` |
| GitHub Workflows | `.github/workflows/` |

---

## Important URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Application | `https://www.tranduchuy.site` | - |
| Backend API | `https://www.tranduchuy.site/api` | - |
| Health Check | `https://www.tranduchuy.site/actuator/health` | - |
| Grafana | `https://grafana.tranduchuy.site` | admin / (check secret) |
| Prometheus | Port forward 9090 | - |
| Alertmanager | Port forward 9093 | - |

---

## Support Contacts

| Issue Type | Contact | Documentation |
|------------|---------|---------------|
| Infrastructure | DevOps Team | `WORKFLOW_SEQUENCE.md` |
| Application Bugs | Development Team | `BUGS_FIXED_SUMMARY.md` |
| Monitoring | SRE Team | `MONITORING_GUIDE.md` |
| Security | Security Team | `GITHUB_SECRETS.md` |
| Testing | QA Team | `TESTING_GUIDE.md` |

---

## Quick Links

- [GitHub Repository](https://github.com/your-org/productx)
- [Docker Hub](https://hub.docker.com/u/your-username)
- [AWS Console](https://console.aws.amazon.com/)
- [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)

---

**Keep this guide handy for daily operations!**
