# PostgreSQL — Anilax Software

## Prerequisites

PostgreSQL is installed (Homebrew example):

```bash
brew install postgresql@18
brew services start postgresql@18
```

## One-time setup

```bash
npm install
npm run db:setup
cp .env.example .env
```

## Tables

| Table | Purpose |
|-------|---------|
| `contact_leads` | Connect With Us form (name, email, industry, requirement, API context) |
| `partner_signups` | Signup / login page before redirect to payments console |

## Admin panel

Set `ADMIN_PASSWORD` in `.env`, start API, then open **http://localhost:5173/admin**

## Run locally

Terminal 1 — API:

```bash
npm run server
```

Terminal 2 — website:

```bash
npm run dev
```

Health check: http://localhost:3001/api/health

## View leads

```bash
psql -d anilax_software -c "SELECT id, name, email, industry, created_at FROM contact_leads ORDER BY created_at DESC LIMIT 20;"
```

```bash
psql -d anilax_software -c "SELECT mode, email, company, created_at FROM partner_signups ORDER BY created_at DESC LIMIT 20;"
```
