#!/usr/bin/env bash
# Rebuild frontend on VPS (same-origin /api) and reload services
set -euo pipefail

DESIGN_DIR="${DESIGN_DIR:-/var/www/anilax-software-design}"
BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"

cd "$DESIGN_DIR"
git pull origin main
rm -f .env.production .env.local
# Empty = use same host /api via nginx
echo 'VITE_API_URL=' > .env.production
npm ci
npm run build

cd "$BACKEND_DIR"
git pull origin main
npm ci
systemctl restart anilax-api
nginx -t && systemctl reload nginx

echo "✓ Rebuilt. Test: curl -s http://127.0.0.1/api/health"
curl -s http://127.0.0.1/api/health || true
echo ""
