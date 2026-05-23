#!/usr/bin/env bash
# Fix API: move Anilax to port 3002 (3001 often used by another app on Hostinger VPS)
set -euo pipefail

BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
API_PORT="${API_PORT:-3002}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

git config --global --add safe.directory "$BACKEND_DIR" 2>/dev/null || true

echo "→ What is on port 3001?"
ss -tlnp | grep -E ':300[12]' || true
grep -rn "Username and password" /var/www 2>/dev/null | head -5 || true

echo "→ Stop anilax-api, free port ${API_PORT}…"
systemctl stop anilax-api 2>/dev/null || true
fuser -k "${API_PORT}/tcp" 2>/dev/null || true

cd "$BACKEND_DIR"
git fetch origin
git reset --hard origin/main
npm ci

if [[ -f .env ]]; then
  sed -i "s/^API_PORT=.*/API_PORT=${API_PORT}/" .env || echo "API_PORT=${API_PORT}" >> .env
  if [[ -n "$ADMIN_PASSWORD" ]]; then
    sed -i "s|^ADMIN_PASSWORD=.*|ADMIN_PASSWORD=${ADMIN_PASSWORD}|" .env
  fi
  if ! grep -q '72.61.227.154' .env 2>/dev/null; then
    sed -i 's|^CORS_ORIGINS=\(.*\)|CORS_ORIGINS=\1,http://72.61.227.154|' .env 2>/dev/null || true
  fi
else
  echo "Missing .env — create it first (see HOSTINGER-VPS.md)"
  exit 1
fi

chown -R www-data:www-data "$BACKEND_DIR"
chmod 600 .env

cp deploy/anilax-api.service /etc/systemd/system/
sed -i "s/API_PORT=3002/API_PORT=${API_PORT}/" /etc/systemd/system/anilax-api.service

if [[ -f /etc/nginx/sites-available/anilax-software ]]; then
  sed -i 's|127.0.0.1:3001|127.0.0.1:'"${API_PORT}"'|g' /etc/nginx/sites-available/anilax-software
  nginx -t && systemctl reload nginx
fi

systemctl daemon-reload
systemctl enable anilax-api
systemctl start anilax-api
sleep 2

echo "→ Health on ${API_PORT}:"
curl -s "http://127.0.0.1:${API_PORT}/api/health"
echo ""
echo "→ Login:"
curl -s -X POST "http://127.0.0.1:${API_PORT}/api/admin/login" \
  -H "Content-Type: application/json" \
  -d "{\"password\":\"${ADMIN_PASSWORD:-CHECK_ENV}\"}"
echo ""
