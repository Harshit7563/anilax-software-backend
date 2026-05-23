#!/usr/bin/env bash
# Mac se VPS par pehli baar deploy — usage:
#   export VPS_IP=123.45.67.89
#   export DB_PASSWORD='your-db-pass'
#   export ADMIN_PASSWORD='your-admin-pass'
#   bash deploy/vps-deploy-from-mac.sh
set -euo pipefail

VPS_IP="${VPS_IP:-}"
DOMAIN="${DOMAIN:-anilaxsoftware.com}"
DB_PASSWORD="${DB_PASSWORD:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

if [[ -z "$VPS_IP" ]]; then
  echo "Set VPS IP: export VPS_IP=YOUR.VPS.IP.ADDRESS"
  exit 1
fi
if [[ -z "$DB_PASSWORD" || -z "$ADMIN_PASSWORD" ]]; then
  echo "Set: export DB_PASSWORD='...' ADMIN_PASSWORD='...'"
  exit 1
fi

echo "→ Deploying to root@${VPS_IP} (${DOMAIN})…"
ssh -o StrictHostKeyChecking=accept-new "root@${VPS_IP}" bash -s <<REMOTE
set -euo pipefail
export DOMAIN='${DOMAIN}'
export DB_PASSWORD='${DB_PASSWORD}'
export ADMIN_PASSWORD='${ADMIN_PASSWORD}'
apt-get update -qq
apt-get install -y -qq git
if [[ ! -f /tmp/anilax-bootstrap/deploy/vps-bootstrap.sh ]]; then
  rm -rf /tmp/anilax-bootstrap
  git clone https://github.com/Harshit7563/anilax-software-backend.git /tmp/anilax-bootstrap
fi
cd /tmp/anilax-bootstrap && git pull origin main
bash deploy/vps-bootstrap.sh
REMOTE

echo ""
echo "Done. Open: https://${DOMAIN}"
echo "Admin:  https://${DOMAIN}/admin"
echo "Health: https://${DOMAIN}/api/health"
