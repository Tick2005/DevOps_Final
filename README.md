# StartupX - DevOps Final Project (Tier 5)

Production-grade CI/CD system với Kubernetes-based architecture cho môn Software Deployment, Operations & Maintenance.

## 🎯 Project Overview

Fullstack Product Management application được deploy trên Kubernetes cluster với:
- **Frontend**: React + Vite
- **Backend**: Spring Boot (Java 17)
- **Database**: MongoDB
- **Orchestration**: K3s/Kubernetes
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana
- **Infrastructure**: Terraform (AWS)

## 🏗️ Architecture - Tier 5: Kubernetes-Based

```
┌─────────────────────────────────────────────────────────┐
│                    Internet (HTTPS)                      │
└────────────────────┬────────────────────────────────────┘
                     │
              ┌──────▼──────┐
              │   Ingress   │ (Nginx + cert-manager)
              │  Controller │
              └──────┬──────┘
                     │
        ┌────────────┴────────────┐
        │                         │
   ┌────▼─────┐            ┌─────▼────┐
   │ Frontend │            │ Backend  │
   │ Service  │            │ Service  │
   │ (2 pods) │            │ (2 pods) │
   └──────────┘            └─────┬────┘
                                 │
                          ┌──────▼──────┐
                          │   MongoDB   │
                          │  (1 pod +   │
                          │    PVC)     │
                          └─────────────┘

Monitoring Stack:
┌──────────────┐      ┌──────────────┐
│  Prometheus  │─────▶│   Grafana    │
└──────────────┘      └──────────────┘
```

## 📁 Project Structure

```
DevOps_Final/
├── app/
│   ├── backend/common/          # Spring Boot application
│   └── frontend/                # React + Vite application
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                  # Main configuration
│   ├── network.tf               # VPC, subnets, routing
│   ├── security.tf              # Security groups, SSH keys
│   ├── compute.tf               # EC2 instances for K3s
│   ├── outputs.tf               # Output values
│   └── scripts/                 # Installation scripts
├── k8s/                         # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml.template
│   ├── mongodb-*.yaml           # MongoDB deployment
│   ├── backend-*.yaml           # Backend deployment + HPA
│   ├── frontend-*.yaml          # Frontend deployment + HPA
│   ├── ingress.yaml             # Ingress configuration
│   ├── cert-manager-issuer.yaml # Let's Encrypt setup
│   └── monitoring/              # Prometheus + Grafana
├── .github/workflows/           # CI/CD pipelines
│   ├── ci.yml                   # Continuous Integration
│   └── cd.yml                   # Continuous Deployment
├── scripts/                     # Utility scripts
│   ├── setup-cluster.sh         # K3s cluster setup
│   ├── deploy-app.sh            # Application deployment
│   └── cleanup.sh               # Resource cleanup
├── docs/                        # Documentation
│   ├── INFRASTRUCTURE-SETUP.md
│   ├── DEPLOYMENT-GUIDE.md
│   └── CICD-SETUP.md
├── docker-compose.yml           # Local development
└── TIER5-CHECKLIST.md          # Implementation checklist
```

## 🚀 Quick Start (Local Development)

### Prerequisites
- Docker Desktop running

### Run with Docker Compose

```bash
docker compose up -d --build
```

Access:
- Frontend: http://localhost:5173
- Backend API: http://localhost:8080/api/products

Stop:
```bash
docker compose down
```

## 🏭 Production Deployment

### Prerequisites

- AWS Account
- Terraform >= 1.0
- kubectl >= 1.28
- Domain name
- Docker Hub account

### Step-by-Step Guides

1. **Infrastructure Setup** (Terraform + K3s)
   - See [docs/INFRASTRUCTURE-SETUP.md](docs/INFRASTRUCTURE-SETUP.md)
   - Provisions VPC, EC2 instances, K3s cluster
   - Configures networking and security

2. **Application Deployment** (Kubernetes)
   - See [docs/DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md)
   - Deploys application to K8s
   - Configures HTTPS with Let's Encrypt
   - Sets up monitoring

3. **CI/CD Pipeline** (GitHub Actions)
   - See [docs/CICD-SETUP.md](docs/CICD-SETUP.md)
   - Automated build, test, scan, deploy
   - Security scanning with Trivy

## 📋 Implementation Checklist

Follow [TIER5-CHECKLIST.md](TIER5-CHECKLIST.md) for complete implementation guide covering:

- ✅ Infrastructure provisioning with Terraform
- ✅ Kubernetes cluster setup (K3s)
- ✅ Application deployment with K8s manifests
- ✅ Horizontal Pod Autoscaling (HPA)
- ✅ Self-healing verification
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Security scanning integration
- ✅ Monitoring with Prometheus + Grafana
- ✅ HTTPS with cert-manager + Let's Encrypt
- ✅ Mandatory demonstration scenario

## 🔑 Key Features

### Infrastructure (Tier 5)
- ✅ Infrastructure as Code with Terraform
- ✅ Idempotent infrastructure provisioning
- ✅ K3s Kubernetes cluster
- ✅ Multi-node architecture (1 master + 2 workers)
- ✅ Automated cluster setup

### Kubernetes Resources
- ✅ Namespaces for isolation
- ✅ ConfigMaps for configuration
- ✅ Secrets for sensitive data
- ✅ PersistentVolumeClaims for stateful services
- ✅ Deployments with rolling updates
- ✅ Services for internal networking
- ✅ Ingress for external access
- ✅ HorizontalPodAutoscaler for scaling

### CI/CD Pipeline
- ✅ Automated linting and code quality checks
- ✅ Dependency caching for faster builds
- ✅ Security scanning with Trivy
- ✅ Container image building and versioning
- ✅ Automated deployment to Kubernetes
- ✅ Rollout status verification

### Monitoring & Observability
- ✅ Prometheus for metrics collection
- ✅ Grafana dashboards for visualization
- ✅ CPU and memory monitoring
- ✅ Pod status tracking
- ✅ Real-time metrics

### Security
- ✅ HTTPS with Let's Encrypt
- ✅ Automatic certificate renewal
- ✅ Security group configuration
- ✅ Vulnerability scanning in CI pipeline
- ✅ Secrets management

### Self-Healing & Scaling
- ✅ Automatic pod restart on failure
- ✅ Liveness and readiness probes
- ✅ Horizontal Pod Autoscaling based on CPU/memory
- ✅ Rolling updates with zero downtime
- ✅ Automatic rollback on failure

## 🧪 Testing & Verification

### Test Self-Healing
```bash
# Delete a pod and watch it recreate
kubectl delete pod -n startupx -l app=backend --force
kubectl get pods -n startupx -w
```

### Test Autoscaling
```bash
# Generate load
hey -z 60s -c 50 https://your-domain.com/api/products

# Watch HPA scale
kubectl get hpa -n startupx -w
```

### Verify Monitoring
```bash
# Access Grafana
kubectl port-forward -n startupx svc/grafana-service 3000:3000
# Open: http://localhost:3000 (admin/admin123)

# Access Prometheus
kubectl port-forward -n startupx svc/prometheus-service 9090:9090
# Open: http://localhost:9090
```

## 📊 Monitoring Access

### Grafana
- **URL**: Port-forward or expose via Ingress
- **Default credentials**: admin / admin123
- **Dashboards**: CPU, Memory, Pod Status

### Prometheus
- **URL**: Port-forward to localhost:9090
- **Metrics**: Node, Pod, Container metrics

## 🔧 Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl cluster-info

# Check application status
kubectl get all -n startupx
kubectl get pods -n startupx
kubectl get hpa -n startupx

# View logs
kubectl logs -n startupx -l app=backend --tail=50
kubectl logs -n startupx -l app=frontend --tail=50

# Describe resources
kubectl describe deployment backend -n startupx
kubectl describe hpa backend-hpa -n startupx

# Check certificate
kubectl get certificate -n startupx
kubectl describe certificate startupx-tls -n startupx

# Scale manually
kubectl scale deployment backend -n startupx --replicas=3

# Rollout management
kubectl rollout status deployment/backend -n startupx
kubectl rollout history deployment/backend -n startupx
kubectl rollout undo deployment/backend -n startupx
```

## 🎬 Demo Scenario

Follow the mandatory demonstration scenario:

1. Make visible code change
2. Commit and push to trigger CI/CD
3. Watch pipeline execution
4. Verify deployment
5. Access via HTTPS
6. Show monitoring dashboards
7. Simulate failure and demonstrate self-healing

## 📝 Documentation

- [Infrastructure Setup Guide](docs/INFRASTRUCTURE-SETUP.md)
- [Deployment Guide](docs/DEPLOYMENT-GUIDE.md)
- [CI/CD Setup Guide](docs/CICD-SETUP.md)
- [Tier 5 Checklist](TIER5-CHECKLIST.md)

## 🎓 Academic Requirements

This project fulfills all Tier 5 requirements:

- ✅ Kubernetes-based orchestration
- ✅ Production-grade infrastructure
- ✅ Fully automated CI/CD pipeline
- ✅ Security integration (DevSecOps)
- ✅ Horizontal Pod Autoscaling
- ✅ Self-healing behavior
- ✅ HTTPS with valid certificate
- ✅ Monitoring and observability
- ✅ Infrastructure as Code
- ✅ Idempotent provisioning

## 🏆 Bonus Features (Optional)

- [ ] Self-hosted CI/CD (Jenkins/GitLab)
- [ ] Multi-environment (Staging + Production)
- [ ] Advanced deployment strategies (Blue-Green/Canary)
- [ ] Automated rollback mechanisms
- [ ] Centralized logging (Loki/ELK)
- [ ] Alerting (Alertmanager)

## 📧 Support

For issues or questions:
1. Check documentation in `docs/` folder
2. Review troubleshooting sections
3. Check Kubernetes events: `kubectl get events -n startupx`
4. Review pod logs: `kubectl logs <pod-name> -n startupx`

## 📄 License

This is an academic project for educational purposes.
