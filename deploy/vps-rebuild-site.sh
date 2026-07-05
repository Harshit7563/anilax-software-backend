#!/usr/bin/env bash
# Redeploy after git pull — run ON THE VPS as root
#
#   cd /var/www/anilax-software-backend
#   git pull
#   bash deploy/vps-rebuild-site.sh
#
set -euo pipefail

DOMAIN="${DOMAIN:-anilaxsoftware.com}"
WWW_ROOT="${WWW_ROOT:-/var/www}"
BACKEND_DIR="${BACKEND_DIR:-$WWW_ROOT/anilax-software-backend}"
DESIGN_DIR="${DESIGN_DIR:-$WWW_ROOT/anilax-software-design}"
VITE_API_URL="${VITE_API_URL:-https://${DOMAIN}}"

echo "==> Backend: $BACKEND_DIR"
cd "$BACKEND_DIR"
npm ci
pm2 restart anilax-api || pm2 start server/index.js --name anilax-api
pm2 save

echo "==> Frontend: $DESIGN_DIR"
cd "$DESIGN_DIR"
npm ci
export VITE_API_URL
npm run build

echo "==> Nginx reload"
nginx -t
systemctl reload nginx

echo ""
echo "✓ Rebuild done"
echo "  Site:  https://${DOMAIN}"
echo "  API:   https://${DOMAIN}/api/health"
echo "  Admin: https://${DOMAIN}/admin/login"
curl -sf "http://127.0.0.1:3001/api/health" | head -c 120 || echo "(health check failed — check pm2 logs anilax-api)"
