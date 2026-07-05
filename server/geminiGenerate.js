const DEFAULT_MODEL = "gemini-2.0-flash";

export async function generateGeminiText({
  apiKey,
  model = DEFAULT_MODEL,
  systemInstruction,
  contents,
  temperature = 0.65,
  maxOutputTokens = 900,
}) {
  if (!apiKey?.trim()) {
    return { ok: false, status: 503, error: "GEMINI_API_KEY not configured" };
  }

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey.trim(),
      },
      body: JSON.stringify({
        systemInstruction: systemInstruction
          ? { parts: [{ text: systemInstruction }] }
          : undefined,
        contents,
        generationConfig: { temperature, maxOutputTokens },
      }),
    },
  );

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    return {
      ok: false,
      status: res.status,
      error: data?.error?.message ?? `Gemini HTTP ${res.status}`,
    };
  }

  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
  if (!text) {
    return { ok: false, status: 502, error: "Empty Gemini response" };
  }

  return { ok: true, text };
}

export function buildShreeSystemPrompt({ lang, pathname, context }) {
  const langRule =
    lang === "en"
      ? "Reply in English only."
      : lang === "hi"
        ? "Reply ONLY in Hindi (Devanagari). Never English."
        : "Reply in natural Hinglish.";

  return `You are Shree, Anilax Software's personal guide (Jaipur). Human, warm, expert on fintech/software.
${langRule}
Intent: ${context?.intent ?? "general"}
${context?.product ? `Product: ${context.product.title} — ${context.product.desc}` : ""}
${context?.knowledge ? `Facts: ${context.knowledge.answer}` : ""}
Page: ${pathname ?? "/"}
Use **bold** for emphasis. Never say you are ChatGPT/Gemini.`;
}

export function buildShreeContents(history, query) {
  return [
    ...history.slice(-10).map((m) => ({
      role: m.role === "user" ? "user" : "model",
      parts: [{ text: m.text }],
    })),
    { role: "user", parts: [{ text: query }] },
  ];
}
