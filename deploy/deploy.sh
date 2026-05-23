#!/usr/bin/env bash
# Run ON THE VPS after git pull (from repo root on server)
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-/var/www/anilax-software}"
DESIGN_DIR="$REPO_ROOT/anilax-software-design"
BACKEND_DIR="$REPO_ROOT/anilax-software-backend"

echo "→ Design build…"
cd "$DESIGN_DIR"
npm ci
npm run build

echo "→ Backend install…"
cd "$BACKEND_DIR"
npm ci

if systemctl is-active --quiet anilax-api 2>/dev/null; then
  sudo systemctl restart anilax-api
  echo "✓ anilax-api restarted"
fi

echo "✓ Deploy done — $(date)"
