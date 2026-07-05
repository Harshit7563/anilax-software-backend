# Fix “Could not reach API” on anilaxsoftware.com

The VPS API is healthy (`http://72.61.227.154/api/health` → `{"ok":true}`). The domain often still sends traffic to **Hostinger shared hosting** instead of the VPS.

## Cause

| Record | Current problem |
|--------|------------------|
| **A** `@` / `www` | Should be `72.61.227.154` only |
| **AAAA** `@` / `www` | Often still Hostinger (`2a02:4780:…`) — browsers prefer IPv6 → wrong server |
| **HTTPS** | Hostinger serves HTML; the form expects JSON from Node on the VPS |

## Hostinger DNS (required)

1. **Domains** → **anilaxsoftware.com** → **DNS / DNS Zone**
2. **A** records: `@` and `www` → **72.61.227.154**
3. **Delete** every **AAAA** record for `@` and `www` (unless your VPS has its own IPv6 and you point AAAA there)
4. Remove any **redirect / parking** to old shared hosting for this domain
5. Wait 5–30 minutes, then test: `https://anilaxsoftware.com/api/health` must return JSON, not an HTML error page

## VPS (after DNS)

```bash
ssh root@72.61.227.154
bash /var/www/anilax-software-backend/deploy/vps-rebuild-site.sh
certbot --nginx -d anilaxsoftware.com -d www.anilaxsoftware.com
curl -s https://anilaxsoftware.com/api/health
```

Expected: `{"ok":true,"db":true}`

## Temporary workaround

Open **http://72.61.227.154** (not `https://anilaxsoftware.com`) and submit the partner form there until DNS and SSL are fixed.
