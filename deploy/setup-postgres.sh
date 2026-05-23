#!/usr/bin/env bash
# Run on VPS as root: export DB_PASSWORD='...' && sudo bash deploy/setup-postgres.sh
set -euo pipefail

DB_NAME="${DB_NAME:-anilax_software}"
DB_USER="${DB_USER:-anilax_app}"

if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo "Set a password first: export DB_PASSWORD='your-strong-password'"
  exit 1
fi

apt-get update -qq
apt-get install -y postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASSWORD}';
  ELSE
    ALTER ROLE ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
  END IF;
END
\$\$;
SQL

if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1; then
  sudo -u postgres createdb -O "$DB_USER" "$DB_NAME"
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
sudo -u postgres psql -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/database/schema.sql"

sudo -u postgres psql -d "$DB_NAME" -v ON_ERROR_STOP=1 <<SQL
GRANT ALL ON SCHEMA public TO ${DB_USER};
GRANT ALL ON ALL TABLES IN SCHEMA public TO ${DB_USER};
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
SQL

echo ""
echo "✓ PostgreSQL ready on this VPS"
echo "DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:5432/${DB_NAME}"
