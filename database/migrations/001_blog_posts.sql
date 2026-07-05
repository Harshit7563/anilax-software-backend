-- Run once on existing databases (Supabase SQL editor)
CREATE TABLE IF NOT EXISTS blog_posts (
  slug VARCHAR(200) PRIMARY KEY,
  title VARCHAR(500) NOT NULL,
  excerpt TEXT NOT NULL,
  category VARCHAR(64) NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  read_minutes INT NOT NULL DEFAULT 5,
  author VARCHAR(200) NOT NULL DEFAULT 'Anilax Team',
  tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  sections JSONB NOT NULL DEFAULT '[]'::jsonb,
  related_slugs JSONB NOT NULL DEFAULT '[]'::jsonb,
  software_id VARCHAR(64),
  source VARCHAR(32) NOT NULL DEFAULT 'admin',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_blog_posts_date ON blog_posts (date DESC);

DROP TRIGGER IF EXISTS blog_posts_updated_at ON blog_posts;
CREATE TRIGGER blog_posts_updated_at
  BEFORE UPDATE ON blog_posts
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();
