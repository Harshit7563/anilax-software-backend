import { Router } from "express";
import { query } from "../db.js";
import { checkAdminPassword, createAdminToken, requireAdmin, verifyAdminToken } from "../adminAuth.js";

export const adminRouter = Router();

adminRouter.post("/login", (req, res) => {
  try {
    const { password } = req.body ?? {};
    if (!process.env.ADMIN_PASSWORD) {
      res.status(503).json({ error: "Admin is not configured on this server" });
      return;
    }
    if (!checkAdminPassword(password)) {
      res.status(401).json({ error: "Invalid password" });
      return;
    }
    res.json({ ok: true, token: createAdminToken() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

adminRouter.get("/session", (req, res) => {
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  res.json({ ok: verifyAdminToken(token) });
});

adminRouter.use(requireAdmin);

adminRouter.get("/stats", async (_req, res) => {
  try {
    const { rows } = await query(`
      SELECT
        (SELECT COUNT(*)::int FROM contact_leads) AS contact_total,
        (SELECT COUNT(*)::int FROM contact_leads WHERE status = 'new') AS contact_new,
        (SELECT COUNT(*)::int FROM partner_signups) AS signup_total,
        (SELECT COUNT(*)::int FROM partner_signups WHERE created_at > NOW() - INTERVAL '7 days') AS signup_week
    `);
    res.json(rows[0]);
  } catch (err) {
    console.error("admin stats:", err);
    res.status(500).json({ error: "Failed to load stats" });
  }
});

adminRouter.get("/contact-leads", async (req, res) => {
  try {
    const status = req.query.status;
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const offset = Math.max(Number(req.query.offset) || 0, 0);

    const params = [];
    let where = "";
    if (status && status !== "all") {
      params.push(status);
      where = `WHERE status = $${params.length}`;
    }
    params.push(limit, offset);

    const { rows } = await query(
      `SELECT id, name, email, industry, requirement, api_name, category_id, category_title,
              source_page, status, created_at, updated_at
       FROM contact_leads
       ${where}
       ORDER BY created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params,
    );

    const countParams = status && status !== "all" ? [status] : [];
    const countWhere = status && status !== "all" ? "WHERE status = $1" : "";
    const { rows: countRows } = await query(
      `SELECT COUNT(*)::int AS total FROM contact_leads ${countWhere}`,
      countParams,
    );

    res.json({ items: rows, total: countRows[0].total, limit, offset });
  } catch (err) {
    console.error("admin contact-leads:", err);
    res.status(500).json({ error: "Failed to load leads" });
  }
});

adminRouter.patch("/contact-leads/:id", async (req, res) => {
  try {
    const { status } = req.body ?? {};
    const allowed = ["new", "contacted", "qualified", "closed"];
    if (!allowed.includes(status)) {
      res.status(400).json({ error: "Invalid status" });
      return;
    }

    const { rows } = await query(
      `UPDATE contact_leads SET status = $1 WHERE id = $2
       RETURNING id, status, updated_at`,
      [status, req.params.id],
    );

    if (!rows.length) {
      res.status(404).json({ error: "Lead not found" });
      return;
    }
    res.json({ ok: true, lead: rows[0] });
  } catch (err) {
    console.error("admin patch lead:", err);
    res.status(500).json({ error: "Failed to update lead" });
  }
});

adminRouter.get("/partner-signups", async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const offset = Math.max(Number(req.query.offset) || 0, 0);

    const { rows } = await query(
      `SELECT id, mode, name, email, company, phone, role, source, created_at
       FROM partner_signups
       ORDER BY created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset],
    );

    const { rows: countRows } = await query(`SELECT COUNT(*)::int AS total FROM partner_signups`);

    res.json({ items: rows, total: countRows[0].total, limit, offset });
  } catch (err) {
    console.error("admin partner-signups:", err);
    res.status(500).json({ error: "Failed to load signups" });
  }
});
