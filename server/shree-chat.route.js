import { Router } from "express";
import {
  buildShreeContents,
  buildShreeSystemPrompt,
  generateGeminiText,
} from "./geminiGenerate.js";

const router = Router();

router.post("/chat", async (req, res) => {
  const key = process.env.GEMINI_API_KEY;
  const { query, lang, pathname, history = [], context = {} } = req.body ?? {};

  if (!query?.trim()) {
    return res.status(400).json({ error: "query required" });
  }

  const result = await generateGeminiText({
    apiKey: key,
    model: process.env.GEMINI_MODEL ?? "gemini-2.0-flash",
    systemInstruction: buildShreeSystemPrompt({ lang, pathname, context }),
    contents: buildShreeContents(history, query),
  });

  if (!result.ok) {
    return res.status(result.status || 502).json({ error: result.error });
  }

  return res.json({ text: result.text });
});

export default router;
