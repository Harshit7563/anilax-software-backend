#!/usr/bin/env bash
# Push backend repo to GitHub.
# First time: create empty repo at https://github.com/new → name: anilax-software-backend
# Or: gh auth login && this script can create the repo for you.
set -euo pipefail
REPO="Harshit7563/anilax-software-backend"
REPO_URL="${1:-https://github.com/${REPO}.git}"
cd "$(dirname "$0")"

git init -b main 2>/dev/null || true
git add -A
git diff --cached --quiet || git commit -m "Update: Anilax Software backend (API + PostgreSQL)"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  if ! gh repo view "$REPO" >/dev/null 2>&1; then
    echo "Creating GitHub repo $REPO …"
    gh repo create "$REPO" --private --source=. --remote=origin --push
    echo "✓ https://github.com/$REPO"
    exit 0
  fi
fi

git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"
git push -u origin main
echo "✓ Pushed to $REPO_URL"
