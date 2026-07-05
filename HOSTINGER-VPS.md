# Hostinger VPS — Step by step (Anilax Software)

Ek VPS par **website + API + admin + Shree AI** — domain: **anilaxsoftware.com**

---

## Pehle yeh ready rakho

| Item | Kahan se |
|------|-----------|
| Hostinger VPS (Ubuntu) | hPanel → VPS |
| Domain `anilaxsoftware.com` | Hostinger Domains |
| Supabase project + `DATABASE_URL` | https://supabase.com |
| Gemini API key | https://aistudio.google.com/apikey |
| GitHub repos pushed | `anilax-software-design`, `anilax-software-backend` |

Supabase SQL Editor mein **ek baar** run karo:

1. `database/schema.sql` (poori file)
2. Agar purani DB ho to `database/migrations/001_blog_posts.sql`

---

## Step 1 — VPS par login

hPanel → VPS → **SSH access** (IP + root password)

```bash
ssh root@YOUR_VPS_IP
```

---

## Step 2 — Env file taiyar karo (recommended)

VPS par pehle backend clone karke secrets file banao:

```bash
mkdir -p /var/www
cd /var/www
git clone https://github.com/Harshit7563/anilax-software-backend.git
cd anilax-software-backend
cp deploy/env.vps.example deploy/env.vps
nano deploy/env.vps
```

`deploy/env.vps` mein fill karo:

```env
DATABASE_URL=postgresql://postgres.xxxx:PASSWORD@....supabase.com:6543/postgres
ADMIN_USERNAME=Bawji
ADMIN_PASSWORD=075630
GEMINI_API_KEY=your-gemini-key
```

(Yeh file git mein nahi jati — sirf VPS par rehti hai.)

---

## Step 3 — Auto setup script chalao

```bash
cd /var/www/anilax-software-backend
export DOMAIN=anilaxsoftware.com
export SKIP_SSL=1
bash deploy/vps-setup.sh
```

Script yeh karega:

1. Node 22, Nginx, PM2, Certbot install  
2. Dono repos clone (`anilax-software-backend` + `anilax-software-design`)  
3. Backend `.env` from `deploy/env.vps`  
4. PM2 se API start (`anilax-api`)  
5. Frontend build (`VITE_API_URL=https://anilaxsoftware.com`)  
6. Nginx config (static + `/api` proxy)

`SKIP_SSL=1` isliye kyunki DNS pehle set karna padta hai.

---

## Step 4 — DNS (Hostinger hPanel)

**Domains → anilaxsoftware.com → DNS Zone**

| Type | Name | Points to |
|------|------|-----------|
| **A** | `@` | VPS IP (e.g. `72.61.227.154`) |
| **A** | `www` | Same VPS IP |

**Delete** all **AAAA** records for `@` and `www` (warna site galat server par jati hai).

5–30 minute wait, phir test:

```bash
curl http://anilaxsoftware.com/api/health
```

Expected: `{"ok":true,"db":true}`

---

## Step 5 — SSL (HTTPS)

```bash
certbot --nginx -d anilaxsoftware.com -d www.anilaxsoftware.com
```

Test:

```bash
curl https://anilaxsoftware.com/api/health
```

---

## Step 6 — Live checklist

| Check | URL |
|-------|-----|
| Home | https://anilaxsoftware.com |
| Admin | https://anilaxsoftware.com/admin/login |
| Health | https://anilaxsoftware.com/api/health |
| Contact form | Submit → Admin → Customer queries |
| Shree AI | Hindi product question |
| Blog | Admin → Blog → add/delete |

---

## Updates (git pull ke baad)

```bash
cd /var/www/anilax-software-backend
git pull
cd /var/www/anilax-software-design
git pull
cd /var/www/anilax-software-backend
bash deploy/vps-rebuild-site.sh
```

---

## Troubleshooting

```bash
pm2 status
pm2 logs anilax-api
nginx -t
systemctl status nginx
curl http://127.0.0.1:3001/api/health
```

| Problem | Fix |
|---------|-----|
| Form “Could not reach API” | DNS A → VPS IP, AAAA delete, `/api/health` JSON? |
| `db: false` | `DATABASE_URL` in `.env`, Supabase schema run |
| Admin login fail | `ADMIN_USERNAME` / `ADMIN_PASSWORD` in `.env`, `pm2 restart anilax-api` |
| Shree no Gemini | `GEMINI_API_KEY` in backend `.env` only |
| 404 on `/admin` | Nginx `try_files` → `index.html` (script sets this) |

DNS detail: `deploy/DNS-FIX.md`

---

## One-liner (advanced — env vars inline)

```bash
curl -fsSL https://raw.githubusercontent.com/Harshit7563/anilax-software-backend/main/deploy/vps-setup.sh | \
  DOMAIN=anilaxsoftware.com \
  DATABASE_URL='postgresql://...' \
  ADMIN_USERNAME=Bawji \
  ADMIN_PASSWORD='your-pass' \
  GEMINI_API_KEY='your-key' \
  SKIP_SSL=1 \
  bash
```

Pehle Supabase schema run karna mat bhoolna.
