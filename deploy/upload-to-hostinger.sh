#!/usr/bin/env bash
# Upload backend repo to VPS
set -euo pipefail
: "${VPS_HOST:?export VPS_HOST=root@YOUR_IP}"
DOMAIN="${DOMAIN:-}"
BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"
DESIGN_DIR="${DESIGN_DIR:-/var/www/anilax-software-design}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BACKEND="$(cd "$SCRIPT_DIR/.." && pwd)"

rsync -avz --delete \
  --exclude node_modules --exclude .env --exclude .git \
  "$LOCAL_BACKEND/" "${VPS_HOST}:${BACKEND_DIR}/"

ssh "$VPS_HOST" "BACKEND_DIR='${BACKEND_DIR}' DESIGN_DIR='${DESIGN_DIR}' DOMAIN='${DOMAIN}' bash ${BACKEND_DIR}/deploy/vps-first-install.sh"
