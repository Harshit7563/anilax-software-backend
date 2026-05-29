#!/usr/bin/env bash
# Repair the live VPS setup for the public site and same-origin API.
set -euo pipefail

DOMAIN="${DOMAIN:-anilaxsoftware.com}"
VPS_IP="${VPS_IP:-72.61.227.154}"
BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"
DESIGN_DIR="${DESIGN_DIR:-/var/www/anilax-software-design}"
API_PORT="${API_PORT:-3002}"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-admin@${DOMAIN}}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo DOMAIN=${DOMAIN} VPS_IP=${VPS_IP} bash $0"
  exit 1
fi

if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Backend directory not found: $BACKEND_DIR"
  exit 1
fi

if [[ ! -f "$BACKEND_DIR/.env" ]]; then
  echo "Missing $BACKEND_DIR/.env"
  echo "Create it first with DATABASE_URL and ADMIN_PASSWORD, then run this script again."
  exit 1
fi

set_env() {
  local key="$1"
  local value="$2"
  local escaped_value

  escaped_value="$(printf '%s' "$value" | sed 's/[|&]/\\&/g')"

  if grep -q "^${key}=" "$BACKEND_DIR/.env"; then
    sed -i "s|^${key}=.*|${key}=${escaped_value}|" "$BACKEND_DIR/.env"
  else
    printf '%s=%s\n' "$key" "$value" >> "$BACKEND_DIR/.env"
  fi
}

echo "==> Backend environment"
git config --global --add safe.directory "$BACKEND_DIR" 2>/dev/null || true
cd "$BACKEND_DIR"
npm ci

set_env "NODE_ENV" "production"
set_env "DOMAIN" "$DOMAIN"
set_env "API_HOST" "127.0.0.1"
set_env "API_PORT" "$API_PORT"
set_env "CORS_ORIGINS" "https://${DOMAIN},https://www.${DOMAIN},http://${DOMAIN},http://www.${DOMAIN},http://${VPS_IP}"
if [[ -n "$ADMIN_PASSWORD" ]]; then
  set_env "ADMIN_PASSWORD" "$ADMIN_PASSWORD"
fi

chmod 600 "$BACKEND_DIR/.env"
chown -R www-data:www-data "$BACKEND_DIR"

echo "==> API service on 127.0.0.1:${API_PORT}"
cp "$BACKEND_DIR/deploy/anilax-api.service" /etc/systemd/system/anilax-api.service
sed -i "s/API_PORT=3002/API_PORT=${API_PORT}/" /etc/systemd/system/anilax-api.service
systemctl daemon-reload
systemctl enable anilax-api
systemctl restart anilax-api
sleep 2
curl -fsS "http://127.0.0.1:${API_PORT}/api/health"
echo ""

if [[ -d "$DESIGN_DIR" && -f "$DESIGN_DIR/package.json" ]]; then
  echo "==> Design build with same-origin /api"
  git config --global --add safe.directory "$DESIGN_DIR" 2>/dev/null || true
  cd "$DESIGN_DIR"
  rm -f .env.local
  printf '%s\n' 'VITE_API_URL=' > .env.production
  npm ci
  npm run build
  chown -R www-data:www-data "$DESIGN_DIR"
else
  echo "WARN: design repo not found at $DESIGN_DIR; skipping frontend rebuild."
fi

echo "==> Nginx site for ${DOMAIN}, www.${DOMAIN}, and ${VPS_IP}"
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
        proxy_pass http://127.0.0.1:${API_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /assets/ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/css application/javascript application/json image/svg+xml;
}
NGINX

ln -sf /etc/nginx/sites-available/anilax-software /etc/nginx/sites-enabled/anilax-software
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "==> DNS seen from VPS"
getent hosts "$DOMAIN" "www.${DOMAIN}" || true
echo ""
echo "Both ${DOMAIN} and www.${DOMAIN} must point to ${VPS_IP}."
echo "If an old AAAA record points elsewhere, remove it before issuing SSL."

echo "==> Let's Encrypt certificate"
if ! certbot --nginx \
  -d "$DOMAIN" \
  -d "www.${DOMAIN}" \
  --non-interactive \
  --agree-tos \
  -m "$CERTBOT_EMAIL" \
  --redirect; then
  echo ""
  echo "Certbot failed. Fix DNS first, then rerun:"
  echo "  DOMAIN=${DOMAIN} VPS_IP=${VPS_IP} bash ${BACKEND_DIR}/deploy/vps-fix-live-domain.sh"
  exit 1
fi

nginx -t
systemctl reload nginx

echo "==> Final checks"
curl -fsSL "http://${DOMAIN}/api/health"
echo ""
curl -fsSL "https://${DOMAIN}/api/health"
echo ""
echo "Done. The Connect With Us form should submit through https://${DOMAIN}/api/contact-leads."
