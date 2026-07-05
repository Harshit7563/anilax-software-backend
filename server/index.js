import "dotenv/config";
import express from "express";
import cors from "cors";
import { healthCheck, query } from "./db.js";
import { adminRouter } from "./routes/admin.js";
import { blogRouter } from "./routes/blog.js";
import shreeChatRouter from "./shree-chat.route.js";

const app = express();
// Hostinger sets PORT; local dev uses API_PORT
const PORT = Number(process.env.PORT ?? process.env.API_PORT ?? 3001);
const HOST =
  process.env.API_HOST ?? (process.env.NODE_ENV === "production" ? "0.0.0.0" : "127.0.0.1");
const isProd = process.env.NODE_ENV === "production";

const allowedOrigins = new Set(
  (process.env.CORS_ORIGINS ?? "http://localhost:5173,http://localhost:5175")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean),
);

// Always allow same-site production hosts when DOMAIN is set
const domain = process.env.DOMAIN?.trim();
if (domain) {
  for (const proto of ["https", "http"]) {
    allowedOrigins.add(`${proto}://${domain}`);
    allowedOrigins.add(`${proto}://www.${domain}`);
  }
  allowedOrigins.add(`http://72.61.227.154`);
}

for (const o of [
  "https://localhost",
  "http://localhost",
  "capacitor://localhost",
  "ionic://localhost",
]) {
  allowedOrigins.add(o);
}

app.use(
  cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.has(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error("Not allowed by CORS"));
    },
  }),
);

app.set("trust proxy", 1);
app.use(express.json({ limit: "32kb" }));

app.get("/api/health", async (_req, res) => {
  try {
    const db = await healthCheck();
    res.json({ ok: true, db });
  } catch (err) {
    res.status(503).json({ ok: false, db: false, error: err.message });
  }
});

app.post("/api/contact-leads", async (req, res) => {
  try {
    const { name, email, industry, requirement, apiName, categoryId, categoryTitle, sourcePage } =
      req.body ?? {};

    if (!name?.trim() || !email?.trim() || !industry?.trim() || !requirement?.trim()) {
      res.status(400).json({ error: "name, email, industry, and requirement are required" });
      return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email).trim())) {
      res.status(400).json({ error: "Invalid email" });
      return;
    }

    const { rows } = await query(
      `INSERT INTO contact_leads (
        name, email, industry, requirement,
        api_name, category_id, category_title, source_page
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id, created_at`,
      [
        String(name).trim().slice(0, 200),
        String(email).trim().toLowerCase().slice(0, 320),
        String(industry).trim().slice(0, 120),
        String(requirement).trim().slice(0, 8000),
        apiName ? String(apiName).trim().slice(0, 200) : null,
        categoryId ? String(categoryId).trim().slice(0, 64) : null,
        categoryTitle ? String(categoryTitle).trim().slice(0, 200) : null,
        sourcePage ? String(sourcePage).trim().slice(0, 500) : null,
      ],
    );

    res.status(201).json({ ok: true, id: rows[0].id, createdAt: rows[0].created_at });
  } catch (err) {
    console.error("contact-leads error:", err);
    res.status(500).json({ error: "Could not save your request. Please try again or call us." });
  }
});

app.use("/api/admin", adminRouter);
app.use("/api/blog", blogRouter);
app.use("/api/shree", shreeChatRouter);

app.post("/api/partner-signups", async (req, res) => {
  try {
    const { mode, name, email, company, phone, role, source } = req.body ?? {};

    if (!email?.trim() || !mode) {
      res.status(400).json({ error: "email and mode are required" });
      return;
    }

    if (!["signup", "login"].includes(mode)) {
      res.status(400).json({ error: "Invalid mode" });
      return;
    }

    const { rows } = await query(
      `INSERT INTO partner_signups (mode, name, email, company, phone, role, source)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, created_at`,
      [
        mode,
        name ? String(name).trim().slice(0, 200) : null,
        String(email).trim().toLowerCase().slice(0, 320),
        company ? String(company).trim().slice(0, 200) : null,
        phone ? String(phone).trim().slice(0, 40) : null,
        role ? String(role).trim().slice(0, 120) : null,
        source ? String(source).trim().slice(0, 120) : null,
      ],
    );

    res.status(201).json({ ok: true, id: rows[0].id });
  } catch (err) {
    console.error("partner-signups error:", err);
    res.status(500).json({ error: "Could not record signup" });
  }
});

app.listen(PORT, HOST, () => {
  console.log(`Anilax API → http://${HOST}:${PORT} (${process.env.NODE_ENV ?? "development"})`);
  console.log(`  Health: http://${HOST}:${PORT}/api/health`);
});
