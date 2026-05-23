# Hostinger par upload (ek command)

Mujhe tumhara **VPS IP** chahiye. Hostinger panel → VPS → SSH access.

## Step 1 — Mac par (project folder)

```bash
cd "/Users/harshit/Anilax Software"

export VPS_HOST=root@TUMHARA_VPS_IP
export DOMAIN=anilaxsoftware.com

bash anilax-software-backend/deploy/upload-to-hostinger.sh
```

Script kya karega:
1. Saari files VPS par upload (`rsync`)
2. Node, PostgreSQL, Nginx install
3. Database + tables
4. Website build
5. API service start
6. SSL (agar `DOMAIN` set ho)

End par **admin password** terminal mein print hoga — save kar lena.

Admin: `https://anilaxsoftware.com/admin`

---

## Step 2 — DNS (Hostinger)

Domain → DNS → **A record**

| Type | Name | Value |
|------|------|--------|
| A | @ | VPS IP |
| A | www | VPS IP |

5–30 min wait, phir site open hogi.

---

## Baad mein update

Code change ke baad dubara:

```bash
export VPS_HOST=root@TUMHARA_VPS_IP
export DOMAIN=anilaxsoftware.com
bash deploy/upload-to-hostinger.sh
```

---

## Manual SSH (agar script fail ho)

Poora guide: [HOSTINGER-VPS.md](./HOSTINGER-VPS.md)
