#!/usr/bin/env bash
# First-time VPS setup — run as root on Ubuntu 22/24
# Usage:
#   export DOMAIN=anilaxsoftware.com
#   export DB_PASSWORD='your-db-password'
#   export ADMIN_PASSWORD='your-admin-password'
#   bash vps-bootstrap.sh
set -euo pipefail

DOMAIN="${DOMAIN:-anilaxsoftware.com}"
DESIGN_DIR="/var/www/anilax-software-design"
BACKEND_DIR="/var/www/anilax-software-backend"
GITHUB_DESIGN="${GITHUB_DESIGN:-https://github.com/Harshit7563/anilax-software-design.git}"
GITHUB_BACKEND="${GITHUB_BACKEND:-https://github.com/Harshit7563/anilax-software-backend.git}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

echo "→ Clone repositories…"
mkdir -p /var/www
if [[ ! -d "$BACKEND_DIR/.git" ]]; then
  git clone "$GITHUB_BACKEND" "$BACKEND_DIR"
fi
if [[ ! -d "$DESIGN_DIR/.git" ]]; then
  git clone "$GITHUB_DESIGN" "$DESIGN_DIR"
fi

chown -R www-data:www-data /var/www/anilax-software-design /var/www/anilax-software-backend

export DOMAIN
export DESIGN_DIR
export BACKEND_DIR
bash "$BACKEND_DIR/deploy/vps-first-install.sh"

echo ""
echo "════════════════════════════════════════"
echo "  Site:  https://${DOMAIN}"
echo "  Admin: https://${DOMAIN}/admin"
echo "  API:   https://${DOMAIN}/api/health"
echo "  Redeploy: bash ${BACKEND_DIR}/deploy/deploy.sh"
echo "════════════════════════════════════════"
