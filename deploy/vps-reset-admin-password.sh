#!/usr/bin/env bash
# Reset the admin login password on the VPS and verify the login endpoint.
set -euo pipefail

BACKEND_DIR="${BACKEND_DIR:-/var/www/anilax-software-backend}"
API_PORT="${API_PORT:-3002}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo ADMIN_PASSWORD='new-password' bash $0"
  exit 1
fi

if [[ -z "$ADMIN_PASSWORD" ]]; then
  echo "Set a new password first:"
  echo "  ADMIN_PASSWORD='new-strong-password' bash $0"
  exit 1
fi

if [[ ! -f "$BACKEND_DIR/.env" ]]; then
  echo "Missing $BACKEND_DIR/.env"
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

echo "==> Updating ADMIN_PASSWORD in $BACKEND_DIR/.env"
set_env "ADMIN_PASSWORD" "$ADMIN_PASSWORD"
chmod 600 "$BACKEND_DIR/.env"
chown www-data:www-data "$BACKEND_DIR/.env"

echo "==> Restarting anilax-api"
systemctl restart anilax-api
sleep 2

echo "==> Health check"
curl -fsS "http://127.0.0.1:${API_PORT}/api/health"
echo ""

echo "==> Login check"
response="$(
  curl -fsS \
    -X POST "http://127.0.0.1:${API_PORT}/api/admin/login" \
    -H "Content-Type: application/json" \
    --data "$(node -e 'process.stdout.write(JSON.stringify({ password: process.env.ADMIN_PASSWORD }))')"
)"
echo "$response" | node -e 'let body="";process.stdin.on("data",d=>body+=d);process.stdin.on("end",()=>{const json=JSON.parse(body); if (!json.ok || !json.token) process.exit(1); console.log("{\"ok\":true}")})'

echo "Done. Use the new ADMIN_PASSWORD on /admin/login."
