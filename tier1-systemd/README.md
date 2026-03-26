# tier1-systemd

Tier 1 workspace (single-server, non-containerized).

UI entry:
- public/index.html

UI behavior:
- public/index.html is a redirect page to ../../tier2-docker-compose/public/index.html
- Default context passed to shared UI: tier1-systemd + Systemd or PM2

Tier stack shown in UI header:
- Tier 1
- Systemd or PM2

Subfolders:
- backend/
- public/
- cicd/
- infrastructure/
- deployment/
- monitoring/
