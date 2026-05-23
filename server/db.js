import pg from "pg";

const { Pool } = pg;

let pool;

export function getPool() {
  if (!pool) {
    const connectionString =
      process.env.DATABASE_URL ??
      `postgresql://${process.env.PGUSER ?? process.env.USER}@${process.env.PGHOST ?? "localhost"}:${process.env.PGPORT ?? 5432}/${process.env.PGDATABASE ?? "anilax_software"}`;

    pool = new Pool({
      connectionString,
      max: 10,
      idleTimeoutMillis: 30_000,
    });
  }
  return pool;
}

export async function query(text, params) {
  return getPool().query(text, params);
}

export async function healthCheck() {
  const { rows } = await query("SELECT 1 AS ok");
  return rows[0]?.ok === 1;
}
