#!/usr/bin/env bash
# Anilax Software — Hostinger VPS first-time setup (Ubuntu 22/24)
#
# Run on a fresh VPS as root:
#   curl -fsSL https://raw.githubusercontent.com/Harshit7563/anilax-software-backend/main/deploy/vps-setup.sh | bash
# Or after clone:
#   cd /var/www/anilax-software-backend && bash deploy/vps-setup.sh
#
# Optional env (export before running):
#   DOMAIN=anilaxsoftware.com
#   DATABASE_URL=postgresql://...
#   ADMIN_USERNAME=Bawji
#   ADMIN_PASSWORD=your-password
#   GEMINI_API_KEY=your-key
#   SKIP_SSL=1          # skip certbot (DNS not ready yet)
#   SKIP_CLONE=1        # repos already cloned
#
set -euo pipefail

DOMAIN="${DOMAIN:-anilaxsoftware.com}"
WWW_ROOT="${WWW_ROOT:-/var/www}"
BACKEND_DIR="${BACKEND_DIR:-$WWW_ROOT/anilax-software-backend}"
DESIGN_DIR="${DESIGN_DIR:-$WWW_ROOT/anilax-software-design}"
BACKEND_REPO="${BACKEND_REPO:-https://github.com/Harshit7563/anilax-software-backend.git}"
DESIGN_REPO="${DESIGN_REPO:-https://github.com/Harshit7563/anilax-software-design.git}"
VITE_API_URL="${VITE_API_URL:-https://${DOMAIN}}"

if [[ "${EUID:-0}" -ne 0 ]]; then
  echo "Run as root: sudo bash deploy/vps-setup.sh"
  exit 1
fi

echo "=============================================="
echo " Anilax VPS setup — ${DOMAIN}"
echo "=============================================="

echo "==> [1/9] System packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq curl git nginx certbot python3-certbot-nginx ca-certificates

if ! command -v node >/dev/null 2>&1 || [[ "$(node -v | cut -d. -f1 | tr -d v)" -lt 20 ]]; then
  echo "    Installing Node.js 22…"
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y -qq nodejs
fi

if ! command -v pm2 >/dev/null 2>&1; then
  npm install -g pm2
fi

echo "    Node $(node -v) · npm $(npm -v)"

echo "==> [2/9] Clone repositories"
mkdir -p "$WWW_ROOT"
if [[ "${SKIP_CLONE:-0}" != "1" ]]; then
  if [[ ! -d "$BACKEND_DIR/.git" ]]; then
    git clone "$BACKEND_REPO" "$BACKEND_DIR"
  else
    echo "    Backend already cloned — git pull"
    git -C "$BACKEND_DIR" pull --ff-only || true
  fi
  if [[ ! -d "$DESIGN_DIR/.git" ]]; then
    git clone "$DESIGN_REPO" "$DESIGN_DIR"
  else
    echo "    Design already cloned — git pull"
    git -C "$DESIGN_DIR" pull --ff-only || true
  fi
fi

echo "==> [3/9] Backend .env"
ENV_FILE="$BACKEND_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f "$BACKEND_DIR/deploy/env.vps" ]]; then
    cp "$BACKEND_DIR/deploy/env.vps" "$ENV_FILE"
    echo "    Created .env from deploy/env.vps"
  else
    cp "$BACKEND_DIR/deploy/env.vps.example" "$ENV_FILE"
    sed -i "s/anilaxsoftware.com/${DOMAIN}/g" "$ENV_FILE"
    sed -i "s|https://anilaxsoftware.com|https://${DOMAIN}|g" "$ENV_FILE"
    echo "    Created .env from deploy/env.vps.example — EDIT REQUIRED"
  fi
fi

# Apply env vars passed to script (non-empty only)
apply_env() {
  local key="$1" val="$2"
  [[ -z "$val" ]] && return
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
  else
    echo "${key}=${val}" >> "$ENV_FILE"
  fi
}

apply_env "DOMAIN" "$DOMAIN"
apply_env "DATABASE_URL" "${DATABASE_URL:-}"
apply_env "ADMIN_USERNAME" "${ADMIN_USERNAME:-Bawji}"
apply_env "ADMIN_PASSWORD" "${ADMIN_PASSWORD:-}"
apply_env "GEMINI_API_KEY" "${GEMINI_API_KEY:-}"
apply_env "CORS_ORIGINS" "https://${DOMAIN},https://www.${DOMAIN}"

if ! grep -q "^DATABASE_URL=postgresql" "$ENV_FILE" 2>/dev/null; then
  echo ""
  echo "⚠️  DATABASE_URL not set in $ENV_FILE"
  echo "    1) Supabase: run database/schema.sql in SQL editor"
  echo "    2) Paste DATABASE_URL into $ENV_FILE"
  echo "    3) Re-run: bash deploy/vps-setup.sh"
  echo ""
fi

echo "==> [4/9] Backend npm + PM2"
cd "$BACKEND_DIR"
npm ci
pm2 delete anilax-api 2>/dev/null || true
pm2 start server/index.js --name anilax-api
pm2 save
pm2 startup systemd -u root --hp /root 2>/dev/null | tail -1 | bash || true

sleep 2
if curl -sf "http://127.0.0.1:3001/api/health" >/dev/null; then
  echo "    API health OK"
else
  echo "    ⚠️  API health failed — check DATABASE_URL and: pm2 logs anilax-api"
fi

echo "==> [5/9] Frontend build"
cd "$DESIGN_DIR"
npm ci
export VITE_API_URL
npm run build
echo "    Built → $DESIGN_DIR/dist"

echo "==> [6/9] Nginx"
NGINX_SITE="/etc/nginx/sites-available/anilax-software"
sed "s/YOUR_DOMAIN.com/${DOMAIN}/g" "$BACKEND_DIR/deploy/nginx-anilax.conf" > "$NGINX_SITE"
ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/anilax-software
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx
systemctl reload nginx

echo "==> [7/9] Firewall (optional)"
if command -v ufw >/dev/null 2>&1; then
  ufw allow OpenSSH 2>/dev/null || true
  ufw allow 'Nginx Full' 2>/dev/null || true
  ufw --force enable 2>/dev/null || true
fi

echo "==> [8/9] DNS reminder"
VPS_IP="$(curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo "    Point DNS A records @ and www → ${VPS_IP}"
echo "    Delete AAAA records for @ and www (IPv6 → wrong server)"
echo "    Wait 5–30 min, then test: curl http://${DOMAIN}/api/health"

echo "==> [9/9] SSL (Let's Encrypt)"
if [[ "${SKIP_SSL:-0}" == "1" ]]; then
  echo "    Skipped (SKIP_SSL=1). Later run:"
  echo "    certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
else
  if curl -sf "http://${DOMAIN}/api/health" >/dev/null 2>&1; then
    certbot --nginx -d "$DOMAIN" -d "www.${DOMAIN}" --non-interactive --agree-tos -m "admin@${DOMAIN}" --redirect || {
      echo "    Certbot failed — DNS may not be ready. Run later:"
      echo "    certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
    }
  else
    echo "    Skipping certbot — domain not pointing here yet."
    echo "    After DNS works: certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
  fi
fi

chmod +x "$BACKEND_DIR/deploy/vps-rebuild-site.sh"

echo ""
echo "=============================================="
echo " ✓ Setup complete"
echo "=============================================="
echo " Site:   https://${DOMAIN}  (or http://${VPS_IP} until DNS/SSL)"
echo " API:    https://${DOMAIN}/api/health"
echo " Admin:  https://${DOMAIN}/admin/login"
echo ""
echo " Redeploy after git pull:"
echo "   bash ${BACKEND_DIR}/deploy/vps-rebuild-site.sh"
echo ""
echo " Logs: pm2 logs anilax-api"
echo "=============================================="
