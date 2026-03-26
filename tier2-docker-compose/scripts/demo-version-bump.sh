#!/usr/bin/env bash
set -euo pipefail

version_file="tier2-docker-compose/public/assets/js/version.js"

if [ ! -f "$version_file" ]; then
  echo "Missing $version_file"
  exit 1
fi

new_version="v$(date +%Y.%m.%d)-$(date +%H%M%S)"
new_env="${1:-staging}"

cat > "$version_file" <<EOF
window.APP_UI_VERSION = "$new_version";
window.APP_RUNTIME_ENV = "$new_env";
EOF

echo "Updated UI demo version to $new_version (env=$new_env)"
