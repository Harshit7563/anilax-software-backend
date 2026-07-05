# Anilax Software — Backend (API)

Express + PostgreSQL: contact queries, partner signups, admin panel, blog CRUD, Shree AI (Gemini).

**GitHub:** https://github.com/Harshit7563/anilax-software-backend

## Setup

```bash
npm install
cp .env.example .env
npm run db:setup
npm run dev
```

Health: http://localhost:3001/api/health  
Admin API: `/api/admin/*` (website `/admin`)  
Blog API: `/api/blog/posts`  
Shree AI: `POST /api/shree/chat`

## Admin login

| Field | Env variable |
|-------|----------------|
| Username | `ADMIN_USERNAME` (default `Bawji`) |
| Password | `ADMIN_PASSWORD` |

1. `npm run dev` in this folder  
2. `npm run dev` in `anilax-software-design`  
3. Open **http://localhost:5173/admin/login**

## Database migration (existing DB)

If tables already exist, run in Supabase SQL editor:

```sql
-- See database/schema.sql blog_posts section
```

Or re-run full `database/schema.sql` (uses `IF NOT EXISTS`).

## Production

```bash
npm start
```

Set on Hostinger / VPS:

```env
DATABASE_URL=postgresql://...
ADMIN_USERNAME=Bawji
ADMIN_PASSWORD=your-strong-password
GEMINI_API_KEY=your-gemini-key
CORS_ORIGINS=https://anilaxsoftware.com,https://www.anilaxsoftware.com
DOMAIN=anilaxsoftware.com
```

See **`HOSTINGER.md`** for deploy steps.
