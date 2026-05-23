#!/usr/bin/env bash
# Fix wrong/old API on port 3001 and restart correct anilax-api
set -euo pipefail

BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

echo "→ Stop services using port 3001…"
systemctl stop anilax-api 2>/dev/null || true
fuser -k 3001/tcp 2>/dev/null || true
sleep 1

echo "→ Fresh backend code from GitHub…"
cd "$BACKEND_DIR"
git fetch origin
git reset --hard origin/main
npm ci

if [[ -n "$ADMIN_PASSWORD" ]]; then
  if [[ -f .env ]]; then
    if grep -q '^ADMIN_PASSWORD=' .env; then
      sed -i "s|^ADMIN_PASSWORD=.*|ADMIN_PASSWORD=${ADMIN_PASSWORD}|" .env
    else
      echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> .env
    fi
  fi
fi

# Allow admin login from IP and domain
if [[ -f .env ]] && ! grep -q '72.61.227.154' .env 2>/dev/null; then
  sed -i 's|^CORS_ORIGINS=\(.*\)|CORS_ORIGINS=\1,http://72.61.227.154,http://anilaxsoftware.com,https://anilaxsoftware.com|' .env || true
fi

chown -R www-data:www-data "$BACKEND_DIR"
chmod 600 .env 2>/dev/null || true

cp deploy/anilax-api.service /etc/systemd/system/anilax-api.service
systemctl daemon-reload
systemctl enable anilax-api
systemctl start anilax-api
sleep 2

echo "→ Health:"
curl -s http://127.0.0.1:3001/api/health
echo ""
echo "→ Admin login test (password-only API):"
curl -s -X POST http://127.0.0.1:3001/api/admin/login \
  -H "Content-Type: application/json" \
  -d "{\"password\":\"${ADMIN_PASSWORD:-CHANGE_ME}\"}"
echo ""
