#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-anilax_software}"
DB_USER="${DB_USER:-$USER}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "→ Checking PostgreSQL…"
if ! command -v psql >/dev/null 2>&1; then
  echo "PostgreSQL not found. Install: brew install postgresql@18"
  exit 1
fi

if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1; then
  echo "PostgreSQL is not running. Start: brew services start postgresql@18"
  exit 1
fi

echo "→ Creating database '$DB_NAME' (if missing)…"
createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" 2>/dev/null || true

echo "→ Applying schema…"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/schema.sql"

echo "✓ Database ready: postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
echo "  Add to .env: DATABASE_URL=postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
