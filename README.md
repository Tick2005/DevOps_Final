# DevOps Final Project

Production-oriented DevOps repository with an offline-ready frontend and folders for infrastructure, CI/CD, deployment, and monitoring artifacts.

## Current Code State

- Frontend is fully local/offline (no CDN dependencies).
- Data source in UI is LocalStorage.
- UI supports product CRUD, responsive layouts, loader, custom modals, and toast notifications.
- Backend folder is prepared for API implementation.

## Folder Map

- `public/`:
	- Final frontend runtime files (`index.html`, assets, icons, JS, CSS).
	- Open `public/index.html` directly to run UI.
- `backend/`:
	- Reserved for server/API code (Java service implementation by backend team).
- `infrastructure/`:
	- Terraform/Ansible/manual provisioning scripts and runbooks.
- `cicd/`:
	- Pipeline definitions for GitHub Actions, GitLab CI, or Jenkins.
- `deployment/`:
	- Deployment artifacts for the selected architecture tier.
- `monitoring/`:
	- Prometheus, Grafana dashboard exports, alerting configs.

## Frontend Features (public)

- Product add/edit/delete with custom confirmation modal.
- Search + color filtering + pagination.
- Responsive UI for phone/tablet/desktop.
- Loader overlay and skeleton placeholders.
- Toast notifications instead of blocking alerts.
- Runtime indicators for run address and data mode.

## Suggested Next Backend Integration

1. Build API inside `backend/` (e.g., Java Spring Boot).
2. Replace LocalStorage calls in `public/assets/js/app.js` with API calls.
3. Add pipeline and deployment files into `cicd/` and `deployment/tier2-docker-compose/`.
4. Add monitoring configuration in `monitoring/`.
