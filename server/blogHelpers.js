export function slugify(title) {
  return String(title)
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function bodyToSections(body) {
  return String(body)
    .split(/\n\s*\n/)
    .map((block) => block.trim())
    .filter(Boolean)
    .map((text) => ({ type: "p", text }));
}

export function estimateReadMinutes(sections) {
  const words = sections
    .flatMap((s) => (s.type === "ul" ? s.items ?? [] : [s.text ?? ""]))
    .join(" ")
    .split(/\s+/)
    .filter(Boolean).length;
  return Math.max(3, Math.min(20, Math.ceil(words / 180)));
}

export function normalizeBlogPost(input, existingSlug) {
  const title = String(input.title ?? "").trim();
  const excerpt = String(input.excerpt ?? "").trim();
  if (!title || !excerpt) {
    throw new Error("Title and excerpt are required");
  }

  const sections =
    Array.isArray(input.sections) && input.sections.length
      ? input.sections
      : bodyToSections(input.body ?? excerpt);

  const slug = existingSlug || slugify(input.slug || title);
  if (!slug) throw new Error("Could not generate slug");

  return {
    slug,
    title,
    excerpt,
    category: String(input.category ?? "Product").trim(),
    date: String(input.date ?? new Date().toISOString().slice(0, 10)),
    readMinutes: Number(input.readMinutes) || estimateReadMinutes(sections),
    author: String(input.author ?? "Anilax Team").trim(),
    tags: Array.isArray(input.tags)
      ? input.tags.map((t) => String(t).trim()).filter(Boolean)
      : String(input.tags ?? "")
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean),
    sections,
    relatedSlugs: Array.isArray(input.relatedSlugs) ? input.relatedSlugs : [],
    softwareId: input.softwareId || null,
    source: input.source || "admin",
  };
}

export function mapBlogRow(row) {
  if (!row) return null;
  const date =
    row.date instanceof Date
      ? row.date.toISOString().slice(0, 10)
      : String(row.date).slice(0, 10);
  return {
    slug: row.slug,
    title: row.title,
    excerpt: row.excerpt,
    category: row.category,
    date,
    readMinutes: row.read_minutes,
    author: row.author,
    tags: row.tags ?? [],
    sections: row.sections ?? [],
    relatedSlugs: row.related_slugs ?? [],
    softwareId: row.software_id ?? undefined,
    source: row.source,
  };
}
