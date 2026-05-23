import crypto from "crypto";

const SESSION_HOURS = 12;

function getSecret() {
  const secret = process.env.ADMIN_SECRET ?? process.env.ADMIN_PASSWORD;
  if (!secret) {
    throw new Error("ADMIN_PASSWORD or ADMIN_SECRET must be set for admin access");
  }
  return secret;
}

function b64url(buf) {
  return Buffer.from(buf)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function fromB64url(str) {
  const pad = str.length % 4 === 0 ? "" : "=".repeat(4 - (str.length % 4));
  return Buffer.from(str.replace(/-/g, "+").replace(/_/g, "/") + pad, "base64");
}

export function createAdminToken() {
  const payload = {
    role: "admin",
    exp: Date.now() + SESSION_HOURS * 60 * 60 * 1000,
  };
  const data = b64url(JSON.stringify(payload));
  const sig = crypto.createHmac("sha256", getSecret()).update(data).digest("base64url");
  return `${data}.${sig}`;
}

export function verifyAdminToken(token) {
  if (!token || typeof token !== "string") return false;
  const [data, sig] = token.split(".");
  if (!data || !sig) return false;

  const expected = crypto.createHmac("sha256", getSecret()).update(data).digest("base64url");
  if (sig.length !== expected.length) return false;
  if (!crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected))) return false;

  try {
    const payload = JSON.parse(fromB64url(data).toString("utf8"));
    if (payload.role !== "admin" || !payload.exp || payload.exp < Date.now()) return false;
    return true;
  } catch {
    return false;
  }
}

export function checkAdminPassword(password) {
  const expected = process.env.ADMIN_PASSWORD;
  if (!expected) return false;
  if (!password || typeof password !== "string") return false;
  if (password.length !== expected.length) return false;
  return crypto.timingSafeEqual(Buffer.from(password), Buffer.from(expected));
}

export function requireAdmin(req, res, next) {
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!verifyAdminToken(token)) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }
  next();
}
