# Hostinger VPS — Deploy Anilax Software

Stack on one VPS: **Nginx** (website) + **Node API** + **PostgreSQL** (contact leads).

Replace `YOUR_DOMAIN.com` with your domain (e.g. `anilaxsoftware.com`). Point DNS **A record** to your VPS IP in Hostinger panel.

---

## 1. VPS access

Hostinger → VPS → **SSH details** (IP, root password or SSH key).

```bash
ssh root@YOUR_VPS_IP
```

Recommended: Ubuntu 22.04 / 24.04.

---

## 2. Server packages

```bash
apt update && apt upgrade -y
apt install -y git nginx certbot python3-certbot-nginx curl

# Node.js 22 (LTS)
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
node -v
npm -v
```

---

## 3. PostgreSQL + database

```bash
export DB_PASSWORD='use-a-long-random-password-here'
cd /tmp
git clone https://github.com/Harshit7563/anilax-software.git anilax-software
cd anilax-software/anilax-software-backend
sudo bash deploy/setup-postgres.sh
```

Copy the printed `DATABASE_URL` for step 5.

---

## 4. App folder

```bash
mkdir -p /var/www
cd /var/www

# First time — clone your repo
git clone https://github.com/Harshit7563/anilax-software.git anilax-software
cd anilax-software/anilax-software-backend
cp deploy/env.production.example .env
# edit .env …

cd ../anilax-software-design && npm ci && npm run build
cd ../anilax-software-backend && npm ci
```

---

## 5. Environment file

```bash
cp deploy/env.production.example .env
nano .env
```

Set:

- `DATABASE_URL` — from step 3  
- `CORS_ORIGINS` — `https://YOUR_DOMAIN.com,https://www.YOUR_DOMAIN.com`  
- Do **not** set `VITE_API_URL` if API is on same domain via Nginx (`/api/...`)

```bash
chown www-data:www-data .env
chmod 600 .env
```

---

## 6. Systemd API service

```bash
cp deploy/anilax-api.service /etc/systemd/system/
chown -R www-data:www-data /var/www/anilax-software

systemctl daemon-reload
systemctl enable anilax-api
systemctl start anilax-api
systemctl status anilax-api
```

Test:

```bash
curl -s http://127.0.0.1:3001/api/health
# {"ok":true,"db":true}
```

---

## 7. Nginx

```bash
sed "s/YOUR_DOMAIN.com/anilaxsoftware.com/g" deploy/nginx-anilax.conf > /etc/nginx/sites-available/anilax-software
ln -sf /etc/nginx/sites-available/anilax-software /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
```

---

## 8. SSL (HTTPS)

```bash
certbot --nginx -d YOUR_DOMAIN.com -d www.YOUR_DOMAIN.com
```

Certbot updates Nginx for HTTPS automatically.

---

## 9. Firewall (Hostinger + UFW)

```bash
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
```

In **Hostinger VPS firewall**, allow ports **22**, **80**, **443**.

---

## 10. Updates (redeploy)

```bash
cd /var/www/anilax-software
git pull
npm ci
npm run build
systemctl restart anilax-api
```

---

## View leads on VPS

```bash
sudo -u postgres psql -d anilax_software -c \
  "SELECT name, email, industry, created_at FROM contact_leads ORDER BY created_at DESC LIMIT 20;"
```

---

## Troubleshooting

| Issue | Fix |
|--------|-----|
| Contact form error | `systemctl status anilax-api` · `journalctl -u anilax-api -n 50` |
| DB connection fail | Check `.env` `DATABASE_URL` · `systemctl status postgresql` |
| 502 on `/api` | API not running — restart `anilax-api` |
| Blank page on `/b2b` | Nginx `try_files` → `index.html` (see `deploy/nginx-anilax.conf`) |
| CORS error | Add exact `https://` URL to `CORS_ORIGINS` in `.env` |

---

## Optional: GitHub deploy key

On VPS:

```bash
ssh-keygen -t ed25519 -C "hostinger-vps" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
```

Add public key in GitHub → repo → Settings → Deploy keys.

---

## Architecture

```
Browser → https://YOUR_DOMAIN.com
            ├── /          → Nginx → /var/www/anilax-software/dist (React)
            └── /api/*     → Nginx → 127.0.0.1:3001 (Node) → PostgreSQL
```

Contact form and signup data are stored in PostgreSQL on the same VPS.
