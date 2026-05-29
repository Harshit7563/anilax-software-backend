# Hostinger VPS — poora stack (design + API + PostgreSQL)

Ek VPS par:
- **Nginx** → React site (`anilax-software-design`)
- **Node API** → Express (`anilax-software-backend`)
- **PostgreSQL** → contact leads + signups

Domain DNS: Hostinger → **A record** `@` aur `www` → **VPS IP**.
Agar old **AAAA** record kisi aur server par point kar raha hai, usko delete karo ya same VPS IPv6 par point karo; warna HTTPS certificate wrong server se aa sakta hai.

---

## Tez install (recommended)

VPS par SSH:

```bash
ssh root@YOUR_VPS_IP
```

Ek command (password apne choose karo):

```bash
export DOMAIN=anilaxsoftware.com
export DB_PASSWORD='StrongDbPass123!'
export ADMIN_PASSWORD='StrongAdminPass123!'

apt update && apt install -y git
git clone https://github.com/Harshit7563/anilax-software-backend.git /tmp/anilax-bootstrap
bash /tmp/anilax-bootstrap/deploy/vps-bootstrap.sh
```

5-10 minute baad:
- https://anilaxsoftware.com — site
- https://anilaxsoftware.com/admin — admin (password = `ADMIN_PASSWORD`)
- https://anilaxsoftware.com/api/health — `{"ok":true,"db":true}`

**Admin password** script end par print hota hai — save kar lo.

---

## Manual steps (agar bootstrap fail ho)

### 1. Packages

```bash
apt update && apt upgrade -y
apt install -y git nginx certbot python3-certbot-nginx curl
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
```

### 2. Clone dono repos

```bash
mkdir -p /var/www
cd /var/www
git clone https://github.com/Harshit7563/anilax-software-design.git
git clone https://github.com/Harshit7563/anilax-software-backend.git
chown -R www-data:www-data /var/www/anilax-software-design /var/www/anilax-software-backend
```

### 3. Database

```bash
export DB_PASSWORD='your-strong-db-password'
cd /var/www/anilax-software-backend
bash deploy/setup-postgres.sh
```

Jo `DATABASE_URL` print ho, copy karo.

### 4. Backend `.env`

```bash
cp deploy/env.production.example .env
nano .env
```

Set:
- `DATABASE_URL` — step 3 se
- `DOMAIN` — `anilaxsoftware.com`
- `CORS_ORIGINS` — `https://anilaxsoftware.com,https://www.anilaxsoftware.com`
- `ADMIN_PASSWORD` — admin login ke liye

```bash
chmod 600 .env
cd /var/www/anilax-software-backend && npm ci
```

### 5. Design build

```bash
cd /var/www/anilax-software-design
npm ci && npm run build
```

`VITE_API_URL` **mat** set karo — same domain par `/api` Nginx proxy karega.

### 6. Systemd API

```bash
cp /var/www/anilax-software-backend/deploy/anilax-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable anilax-api
systemctl start anilax-api
curl -s http://127.0.0.1:3002/api/health
```

### 7. Nginx

```bash
sed -e 's/YOUR_DOMAIN.com/anilaxsoftware.com/g' \
  /var/www/anilax-software-backend/deploy/nginx-anilax.conf \
  > /etc/nginx/sites-available/anilax-software
ln -sf /etc/nginx/sites-available/anilax-software /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

### 8. SSL

```bash
certbot --nginx -d anilaxsoftware.com -d www.anilaxsoftware.com
```

### 9. Firewall

```bash
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
```

Hostinger VPS panel → firewall: ports **22, 80, 443** open.

---

## Updates (git push ke baad)

```bash
bash /var/www/anilax-software-backend/deploy/deploy.sh
```

---

## Live domain / Connect With Us API fix

Agar form submit par ye error aaye:

```text
Could not reach API. If you use anilaxsoftware.com, point DNS to the VPS (72.61.227.154) or open the site at http://72.61.227.154
```

To usually HTTPS/DNS issue hota hai. VPS par run karo:

```bash
cd /var/www/anilax-software-backend
git pull origin main
DOMAIN=anilaxsoftware.com VPS_IP=72.61.227.154 bash deploy/vps-fix-live-domain.sh
```

Script ye cheezein set karega:
- Backend `.env`: `DOMAIN`, `API_PORT=3002`, exact `CORS_ORIGINS`
- Frontend build: `VITE_API_URL=` so browser same-origin `/api` call kare
- Nginx: `anilaxsoftware.com`, `www.anilaxsoftware.com`, aur VPS IP same site par serve hon
- Let's Encrypt: valid SSL cert for `anilaxsoftware.com` and `www.anilaxsoftware.com`

Run karne se pehle DNS check:
- `@` A record → `72.61.227.154`
- `www` A record → `72.61.227.154`
- old/wrong `AAAA` record remove karo, jab tak VPS ka IPv6 use nahi kar rahe

---

## Hostinger Node.js site band karo

Agar pehle `anilaxsoftware.com` Node hosting par tha:
1. hPanel → website **delete** (sirf Node app, domain mat hatao)
2. DNS **A record** VPS IP par point karo
3. Upar wala VPS bootstrap chalao

---

## Troubleshooting

| Issue | Fix |
|--------|-----|
| 502 Bad Gateway | `systemctl status anilax-api` · `journalctl -u anilax-api -n 50` |
| DB error | `.env` `DATABASE_URL` · `systemctl status postgresql` |
| CORS | `CORS_ORIGINS` mein exact `https://` URL |
| SSL name mismatch / browser API unreachable | DNS `@`/`www` ko VPS par point karo, wrong `AAAA` remove karo, phir `deploy/vps-fix-live-domain.sh` run karo |
| Blank React routes | Nginx `try_files` → `index.html` |

---

## Architecture

```
https://anilaxsoftware.com
  ├── /          → /var/www/anilax-software-design/dist
  └── /api/*     → 127.0.0.1:3002 (anilax-api.service) → PostgreSQL
```
