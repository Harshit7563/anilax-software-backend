# Hostinger — Backend API deploy

Frontend = repo **`anilax-software-design`** on `anilaxsoftware.com`  
Backend = repo **`anilax-software-backend`** on subdomain **`api.anilaxsoftware.com`**

PostgreSQL: Hostinger Node par local Postgres nahi hota — **Supabase** (free) use karo.

---

## Step 1 — Subdomain

hPanel → **Domains** → `anilaxsoftware.com` → **Subdomains**  
Add: **`api`** → `api.anilaxsoftware.com`

---

## Step 2 — Supabase database (5 min)

1. https://supabase.com → New project  
2. **Settings** → **Database** → **Connection string** → **URI** copy karo  
   Example: `postgresql://postgres.xxxx:PASSWORD@aws-0-xxx.pooler.supabase.com:6543/postgres`
3. Supabase **SQL Editor** mein `database/schema.sql` ka content paste karke **Run** karo (tables ban jayengi)

---

## Step 3 — Naya Node.js website (API)

1. hPanel → **Websites** → **Add Website** → **Node.js Apps**  
2. **Import Git Repository** → **`anilax-software-backend`**  
3. Branch: **`main`**  
4. Domain: **`api.anilaxsoftware.com`**

### Build settings

| Field | Value |
|-------|--------|
| Framework | **Express.js** (ya Other) |
| Node | **22.x** |
| Root | `./` |
| Install | `npm ci` |
| Build | `npm run build` |
| Start | `npm start` |
| Entry file | `server/index.js` |

---

## Step 4 — Environment variables (Hostinger)

| Name | Value |
|------|--------|
| `NODE_ENV` | `production` |
| `DATABASE_URL` | Supabase URI (step 2) |
| `CORS_ORIGINS` | `https://anilaxsoftware.com,https://www.anilaxsoftware.com` |
| `DOMAIN` | `anilaxsoftware.com` |
| `ADMIN_USERNAME` | `Bawji` |
| `ADMIN_PASSWORD` | Strong secret (admin login) |
| `GEMINI_API_KEY` | Google AI Studio key (Shree AI) |
| `GEMINI_MODEL` | `gemini-2.0-flash` (optional) |

`PORT` Hostinger khud set karta hai — mat likho.

**Deploy** → logs mein `Anilax API` aur health check pass hona chahiye.

Test: https://api.anilaxsoftware.com/api/health → `{"ok":true,"db":true}`

---

## Step 5 — Frontend ko API se jodo

Design site (`anilax-software-design`) → Hostinger **Environment variables**:

```env
VITE_API_URL=https://api.anilaxsoftware.com
```

Phir design site par **Redeploy** (env build time par lagti hai).

---

## VPS (optional)

Full stack ek server par: `deploy/HOSTINGER-VPS.md` (Nginx + Postgres on VPS).
