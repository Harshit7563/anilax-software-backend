#!/usr/bin/env bash
# First-time VPS setup — run as root on Ubuntu 22/24
set -euo pipefail

DOMAIN="${DOMAIN:-anilaxsoftware.com}"
DESIGN_DIR="/var/www/anilax-software-design"
BACKEND_DIR="/var/www/anilax-software-backend"
GITHUB_DESIGN="${GITHUB_DESIGN:-https://github.com/Harshit7563/anilax-software-design.git}"
GITHUB_BACKEND="${GITHUB_BACKEND:-https://github.com/Harshit7563/anilax-software-backend.git}"

# Optional: export GITHUB_TOKEN=ghp_xxx for private repos
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  GITHUB_DESIGN="https://${GITHUB_TOKEN}@github.com/Harshit7563/anilax-software-design.git"
  GITHUB_BACKEND="https://${GITHUB_TOKEN}@github.com/Harshit7563/anilax-software-backend.git"
fi

git_clone_public() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    echo "  skip (exists): $dest"
    return 0
  fi
  rm -rf "$dest"
  GIT_TERMINAL_PROMPT=0 git -c credential.helper= clone --depth 1 "$url" "$dest"
}

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

echo "→ Clone repositories (public HTTPS, no login)…"
mkdir -p /var/www
git_clone_public "$GITHUB_BACKEND" "$BACKEND_DIR"
git_clone_public "$GITHUB_DESIGN" "$DESIGN_DIR"

chown -R www-data:www-data /var/www/anilax-software-design /var/www/anilax-software-backend

export DOMAIN DESIGN_DIR BACKEND_DIR
bash "$BACKEND_DIR/deploy/vps-first-install.sh"

echo ""
echo "════════════════════════════════════════"
echo "  Site:  https://${DOMAIN}"
echo "  Admin: https://${DOMAIN}/admin"
echo "  API:   https://${DOMAIN}/api/health"
echo "  Redeploy: bash ${BACKEND_DIR}/deploy/deploy.sh"
echo "════════════════════════════════════════"
