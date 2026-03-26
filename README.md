# DevOps Final Project (Tier-Based Layout)

This repository is organized by architecture tier and matches the final exam direction.

## Tier Folders

- tier1-systemd/
- tier2-docker-compose/ (current active implementation)
- tier3-multi-server-lb/
- tier4-docker-swarm/
- tier5-kubernetes/

Each tier includes the same required domains:

- backend/
- public/
- cicd/
- infrastructure/
- deployment/
- monitoring/

## Deployment File Naming Standard

To keep grading and team collaboration consistent, each tier now has fixed deployment template names:

- Tier 1: app.service, deploy-systemd.sh, nginx.conf, .env.example
- Tier 2: docker-compose.yml, docker-compose.prod.yml, deploy-compose.sh, nginx.conf, .env.example
- Tier 3: load-balancer.conf, app-node-deploy.sh, inventory.ini, .env.example
- Tier 4: docker-stack.yml, deploy-swarm.sh, swarm.env.example
- Tier 5: deployment/k8s/namespace.yaml, deployment/k8s/deployment.yaml, deployment/k8s/service.yaml, deployment/k8s/ingress.yaml, deployment/k8s/configmap.yaml, deployment/k8s/secret.example.yaml, deployment/k8s/hpa.yaml, deploy-k8s.sh

## Current Active Tier

tier2-docker-compose/ currently contains the implemented frontend and detailed subfolder documentation.

## Frontend Placement by Tier

- Tier 2 is the single source of UI: tier2-docker-compose/public/index.html
- Tier 1/3/4/5 public/index.html files are lightweight redirect pages to Tier 2 UI.
- Redirect pages preserve query params and inject default tier/stack if missing.
- UI header shows active tier, stack, runtime environment badge, and app version.

## Demo Version Bump Scripts

For Section V demo flow (source change -> CI/CD update), use:

- tier2-docker-compose/scripts/demo-version-bump.sh
- tier2-docker-compose/scripts/demo-version-bump.ps1

Both scripts update tier2-docker-compose/public/assets/js/version.js with:

- APP_UI_VERSION (timestamp version)
- APP_RUNTIME_ENV (staging/production/dev)

## CI/CD Template Standard

Each tier now includes the same CI/CD template format:

- cicd/github-actions/ci.yml
- cicd/github-actions/cd.yml
- cicd/gitlab-ci/.gitlab-ci.yml
- cicd/jenkins/Jenkinsfile

## Monitoring Template Standard

Each tier includes baseline monitoring templates:

- monitoring/prometheus/prometheus.yml
- monitoring/grafana/dashboards/system-overview.json

## Usage Guidance

1. Keep active development in one tier folder.
2. Use other tiers as scaffolding or migration targets.
3. Keep deployment artifacts only in their matching tier/deployment folder.
