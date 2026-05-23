# Hostinger VPS — poora stack (design + API + PostgreSQL)

Ek VPS par:
- **Nginx** → React site (`anilax-software-design`)
- **Node API** → Express (`anilax-software-backend`)
- **PostgreSQL** → contact leads + signups

Domain DNS: Hostinger → **A record** `@` aur `www` → **VPS IP**

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

5–10 minute baad:
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
curl -s http://127.0.0.1:3001/api/health
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
| Blank React routes | Nginx `try_files` → `index.html` |

---

## Architecture

```
https://anilaxsoftware.com
  ├── /          → /var/www/anilax-software-design/dist
  └── /api/*     → 127.0.0.1:3001 (anilax-api.service) → PostgreSQL
```
