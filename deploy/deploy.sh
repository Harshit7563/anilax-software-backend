#!/usr/bin/env bash
# Redeploy on VPS after git pull (both repos)
set -euo pipefail

DESIGN_DIR="${DESIGN_DIR:-/var/www/anilax-software-design}"
BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"

echo "→ Design…"
cd "$DESIGN_DIR"
git pull origin main
npm ci
npm run build

echo "→ Backend…"
cd "$BACKEND_DIR"
git pull origin main
npm ci

if systemctl is-active --quiet anilax-api 2>/dev/null; then
  systemctl restart anilax-api
  echo "✓ anilax-api restarted"
fi

systemctl reload nginx 2>/dev/null || true
echo "✓ Deploy done — $(date)"
