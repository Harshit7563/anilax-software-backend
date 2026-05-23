#!/usr/bin/env bash
# Run FROM YOUR MAC — uploads full repo (design + backend) to Hostinger VPS
#
# Usage:
#   export VPS_HOST=root@YOUR_VPS_IP
#   export DOMAIN=anilaxsoftware.com
#   bash anilax-software-backend/deploy/upload-to-hostinger.sh
#
set -euo pipefail

: "${VPS_HOST:?Set VPS_HOST — example: export VPS_HOST=root@123.45.67.89}"
DOMAIN="${DOMAIN:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REMOTE_DIR="/var/www/anilax-software"

echo "→ Uploading repo to ${VPS_HOST}:${REMOTE_DIR}"

ssh "$VPS_HOST" "mkdir -p ${REMOTE_DIR}"

rsync -avz --delete \
  --exclude node_modules \
  --exclude .git \
  --exclude .env \
  --exclude dist \
  --exclude ".DS_Store" \
  "$REPO_ROOT/" "${VPS_HOST}:${REMOTE_DIR}/"

echo "→ Running server install…"
ssh "$VPS_HOST" "chmod +x ${REMOTE_DIR}/anilax-software-backend/deploy/*.sh && DOMAIN='${DOMAIN}' bash ${REMOTE_DIR}/anilax-software-backend/deploy/vps-first-install.sh"

echo ""
echo "Done. Open https://${DOMAIN:-YOUR_DOMAIN} when DNS is ready."
