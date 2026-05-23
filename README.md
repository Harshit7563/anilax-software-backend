# Anilax Software — Backend (API)

Express + PostgreSQL: contact leads, partner signups, admin API.

## Setup

```bash
npm install
cp .env.example .env
npm run db:setup
npm run dev
```

Health: http://localhost:3001/api/health  
Admin API: `/api/admin/*` (used by design app at `/admin`)

## Production

```bash
npm start
```

See `deploy/HOSTINGER-VPS.md` for VPS deploy.
