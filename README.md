# Anilax Software — Backend (API)

Express + PostgreSQL: contact leads, partner signups, admin API.

**GitHub:** https://github.com/Harshit7563/anilax-software-backend

## Setup

```bash
npm install
cp .env.example .env
npm run db:setup
npm run dev
```

Health: http://localhost:3001/api/health  
Admin API: `/api/admin/*` (used by design app at `/admin`)

## Admin login (local)

1. Keep `npm run dev` running here.
2. In `anilax-software-design`: `cp .env.example .env.local` then `npm run dev`.
3. Open **http://localhost:5177/admin/login** (your Vite URL + `/admin/login`).
4. Password = value of `ADMIN_PASSWORD` in `.env`.

## Production

```bash
npm start
```

**Production (VPS):** `deploy/HOSTINGER-VPS.md` — one-command bootstrap on Hostinger VPS.
