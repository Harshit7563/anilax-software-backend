#!/usr/bin/env bash
# First-time or update install ON THE VPS (run as root)
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/anilax-software}"
DESIGN_DIR="${DESIGN_DIR:-$APP_ROOT/anilax-software-design}"
BACKEND_DIR="${BACKEND_DIR:-$APP_ROOT/anilax-software-backend}"
DOMAIN="${DOMAIN:-}"
DB_PASSWORD="${DB_PASSWORD:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

echo "→ Installing system packages (if needed)…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git nginx certbot python3-certbot-nginx curl postgresql postgresql-contrib

if ! command -v node >/dev/null 2>&1 || [[ "$(node -v | cut -d. -f1 | tr -d v)" -lt 20 ]]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y -qq nodejs
fi

echo "→ Node $(node -v) · npm $(npm -v)"

if [[ -z "$DB_PASSWORD" ]]; then
  DB_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 32)"
fi
if [[ -z "$ADMIN_PASSWORD" ]]; then
  ADMIN_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"
fi

export DB_PASSWORD
cd "$BACKEND_DIR"
bash deploy/setup-postgres.sh

CORS_LINE=""
if [[ -n "$DOMAIN" ]]; then
  CORS_LINE="CORS_ORIGINS=https://${DOMAIN},https://www.${DOMAIN}"
fi

cat > .env <<ENVFILE
NODE_ENV=production
API_HOST=127.0.0.1
API_PORT=3001
DATABASE_URL=postgresql://anilax_app:${DB_PASSWORD}@127.0.0.1:5432/anilax_software
ADMIN_PASSWORD=${ADMIN_PASSWORD}
${CORS_LINE}
ENVFILE

chmod 600 .env

echo "→ Design: npm install & build…"
cd "$DESIGN_DIR"
npm ci
npm run build

echo "→ Backend: npm install…"
cd "$BACKEND_DIR"
npm ci

echo "→ systemd API service…"
sed "s|/var/www/anilax-software|$BACKEND_DIR|g" deploy/anilax-api.service > /etc/systemd/system/anilax-api.service
systemctl daemon-reload
systemctl enable anilax-api
systemctl restart anilax-api

if [[ -n "$DOMAIN" ]]; then
  echo "→ Nginx for ${DOMAIN}…"
  sed -e "s/YOUR_DOMAIN.com/${DOMAIN}/g" -e "s|/var/www/anilax-software/dist|${DESIGN_DIR}/dist|g" \
    deploy/nginx-anilax.conf > /etc/nginx/sites-available/anilax-software
  ln -sf /etc/nginx/sites-available/anilax-software /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl reload nginx

  if ! certbot certificates 2>/dev/null | grep -q "$DOMAIN"; then
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "admin@${DOMAIN}" || true
  fi
fi

chown -R www-data:www-data "$APP_ROOT"

echo ""
echo "════════════════════════════════════════"
echo "✓ Deploy complete"
echo "  Design:   $DESIGN_DIR"
echo "  Backend:  $BACKEND_DIR"
if [[ -n "$DOMAIN" ]]; then
  echo "  Site:     https://${DOMAIN}"
  echo "  Admin:    https://${DOMAIN}/admin"
fi
echo "  Admin password: ${ADMIN_PASSWORD}"
echo "════════════════════════════════════════"
curl -s http://127.0.0.1:3001/api/health || true
echo ""
