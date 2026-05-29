#!/usr/bin/env bash
# Rebuild site on VPS — API via same host /api (no cross-domain issues)
set -euo pipefail

DESIGN_DIR="${DESIGN_DIR:-/var/www/anilax-software-design}"
BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"
DOMAIN="${DOMAIN:-anilaxsoftware.com}"
VPS_IP="${VPS_IP:-72.61.227.154}"

git config --global --add safe.directory "$DESIGN_DIR" 2>/dev/null || true
git config --global --add safe.directory "$BACKEND_DIR" 2>/dev/null || true

echo "→ Backend…"
cd "$BACKEND_DIR"
git fetch origin && git reset --hard origin/main
npm ci

if ! grep -q '^DOMAIN=' .env 2>/dev/null; then
  echo "DOMAIN=${DOMAIN}" >> .env
else
  sed -i "s/^DOMAIN=.*/DOMAIN=${DOMAIN}/" .env
fi
if ! grep -q '^API_PORT=' .env 2>/dev/null; then
  echo 'API_PORT=3002' >> .env
else
  sed -i 's/^API_PORT=.*/API_PORT=3002/' .env
fi
if ! grep -q '^CORS_ORIGINS=' .env 2>/dev/null; then
  echo "CORS_ORIGINS=https://${DOMAIN},https://www.${DOMAIN},http://${DOMAIN},http://www.${DOMAIN},http://${VPS_IP}" >> .env
else
  sed -i "s|^CORS_ORIGINS=.*|CORS_ORIGINS=https://${DOMAIN},https://www.${DOMAIN},http://${DOMAIN},http://www.${DOMAIN},http://${VPS_IP}|" .env
fi

systemctl restart anilax-api
sleep 2
curl -sf http://127.0.0.1:3002/api/health >/dev/null || { echo "API not up on 3002"; exit 1; }

echo "→ Design build (same-origin /api)…"
cd "$DESIGN_DIR"
git fetch origin && git reset --hard origin/main
rm -f .env.local
printf '%s\n' 'VITE_API_URL=' > .env.production
npm ci
npm run build

echo "→ Nginx…"
cat > /etc/nginx/sites-available/anilax-software <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} ${VPS_IP};

    root ${DESIGN_DIR}/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3002;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/anilax-software /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "✓ Done"
curl -s http://127.0.0.1/api/health
echo ""
