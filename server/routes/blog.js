import { Router } from "express";
import { query } from "../db.js";
import { mapBlogRow } from "../blogHelpers.js";

export const blogRouter = Router();

blogRouter.get("/posts", async (_req, res) => {
  try {
    const { rows } = await query(
      `SELECT slug, title, excerpt, category, date, read_minutes, author,
              tags, sections, related_slugs, software_id, source
       FROM blog_posts
       ORDER BY date DESC, created_at DESC`,
    );
    const items = rows.map(mapBlogRow);
    res.json({ items, total: items.length });
  } catch (err) {
    console.error("blog posts:", err);
    res.status(500).json({ error: "Failed to load blog posts" });
  }
});

blogRouter.get("/posts/:slug", async (req, res) => {
  try {
    const { rows } = await query(
      `SELECT slug, title, excerpt, category, date, read_minutes, author,
              tags, sections, related_slugs, software_id, source
       FROM blog_posts
       WHERE slug = $1`,
      [req.params.slug],
    );
    if (!rows.length) {
      res.status(404).json({ error: "Post not found" });
      return;
    }
    res.json(mapBlogRow(rows[0]));
  } catch (err) {
    console.error("blog post:", err);
    res.status(500).json({ error: "Failed to load post" });
  }
});
