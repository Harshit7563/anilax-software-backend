#!/usr/bin/env bash
# Create empty repo on GitHub first: anilax-software-backend (no README)
# Usage: bash deploy-connect-github.sh
set -euo pipefail
REPO_URL="${1:-https://github.com/Harshit7563/anilax-software-backend.git}"
cd "$(dirname "$0")"
git init -b main 2>/dev/null || true
git add -A
git commit -m "Initial commit: Anilax Software backend (API + PostgreSQL)" 2>/dev/null || true
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"
git push -u origin main --force
echo "✓ Pushed to $REPO_URL"
