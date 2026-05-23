-- Anilax Software — PostgreSQL schema
-- Run: npm run db:setup

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Partner / contact inquiries (Connect With Us modal)
CREATE TABLE IF NOT EXISTS contact_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  email VARCHAR(320) NOT NULL,
  industry VARCHAR(120) NOT NULL,
  requirement TEXT NOT NULL,
  api_name VARCHAR(200),
  category_id VARCHAR(64),
  category_title VARCHAR(200),
  source_page VARCHAR(500),
  status VARCHAR(32) NOT NULL DEFAULT 'new'
    CHECK (status IN ('new', 'contacted', 'qualified', 'closed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contact_leads_created_at ON contact_leads (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_contact_leads_email ON contact_leads (email);
CREATE INDEX IF NOT EXISTS idx_contact_leads_status ON contact_leads (status);

-- Signup / login intents (local auth page before payments console redirect)
CREATE TABLE IF NOT EXISTS partner_signups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mode VARCHAR(16) NOT NULL CHECK (mode IN ('signup', 'login')),
  name VARCHAR(200),
  email VARCHAR(320) NOT NULL,
  company VARCHAR(200),
  phone VARCHAR(40),
  role VARCHAR(120),
  source VARCHAR(120),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_partner_signups_created_at ON partner_signups (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_partner_signups_email ON partner_signups (email);

-- Auto-update updated_at on contact_leads
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS contact_leads_updated_at ON contact_leads;
CREATE TRIGGER contact_leads_updated_at
  BEFORE UPDATE ON contact_leads
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();
