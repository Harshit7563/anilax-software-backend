#!/usr/bin/env bash
# First-time install ON VPS — backend repo only (API + DB)
# Clone design repo separately for static site — see HOSTINGER-VPS.md
set -euo pipefail

BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"
DESIGN_DIR="${DESIGN_DIR:-/var/www/anilax-software-design}"
DOMAIN="${DOMAIN:-}"
DB_PASSWORD="${DB_PASSWORD:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

echo "→ System packages…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git nginx certbot python3-certbot-nginx curl postgresql postgresql-contrib

if ! command -v node >/dev/null 2>&1 || [[ "$(node -v | cut -d. -f1 | tr -d v)" -lt 20 ]]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y -qq nodejs
fi

if [[ -z "$DB_PASSWORD" ]]; then DB_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 32)"; fi
if [[ -z "$ADMIN_PASSWORD" ]]; then ADMIN_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"; fi

export DB_PASSWORD
cd "$BACKEND_DIR"
bash deploy/setup-postgres.sh

CORS_LINE=""
[[ -n "$DOMAIN" ]] && CORS_LINE="CORS_ORIGINS=https://${DOMAIN},https://www.${DOMAIN}"

cat > .env <<ENVFILE
NODE_ENV=production
API_HOST=127.0.0.1
API_PORT=3001
DATABASE_URL=postgresql://anilax_app:${DB_PASSWORD}@127.0.0.1:5432/anilax_software
ADMIN_PASSWORD=${ADMIN_PASSWORD}
${CORS_LINE}
ENVFILE
chmod 600 .env

cd "$BACKEND_DIR" && npm ci

if [[ -d "$DESIGN_DIR" && -f "$DESIGN_DIR/package.json" ]]; then
  echo "→ Design build…"
  cd "$DESIGN_DIR" && npm ci && npm run build
fi

sed "s|/var/www/anilax-software/anilax-software-backend|$BACKEND_DIR|g" "$BACKEND_DIR/deploy/anilax-api.service" > /etc/systemd/system/anilax-api.service
systemctl daemon-reload
systemctl enable anilax-api
systemctl restart anilax-api

if [[ -n "$DOMAIN" && -d "$DESIGN_DIR/dist" ]]; then
  sed -e "s/YOUR_DOMAIN.com/${DOMAIN}/g" \
      -e "s|/var/www/anilax-software/anilax-software-design/dist|${DESIGN_DIR}/dist|g" \
    "$BACKEND_DIR/deploy/nginx-anilax.conf" > /etc/nginx/sites-available/anilax-software
  ln -sf /etc/nginx/sites-available/anilax-software /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
  nginx -t && systemctl reload nginx
  certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "admin@${DOMAIN}" 2>/dev/null || true
fi

echo "✓ Backend: $BACKEND_DIR"
echo "  Admin password: $ADMIN_PASSWORD"
curl -s http://127.0.0.1:3001/api/health || true
echo ""
