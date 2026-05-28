/**
 * TEXT ORCHESTRATOR — KreaSea Backend
 * ─────────────────────────────────────────────────────────
 * Mengelola pool 5 API Key Gemini untuk semua fitur text generation:
 * Caption, WA Blast, GMaps, HPP Advice, Nama Produk, dll.
 *
 * Strategi:
 * - Round-robin: distribusi merata antar key
 * - Auto-skip: jika key kena 429, cooldown 60s → pakai key berikutnya
 * - Fallback: jika semua Gemini key limit → switch ke OpenAI GPT-4o-mini
 * - Max retry: 5x sebelum return error ke client
 */

const fetch = (...args) => import('node-fetch').then(({ default: f }) => f(...args));

// ── Key Pool: baca dari environment ─────────────────────────
function loadTextKeys() {
  const keys = [];
  for (let i = 1; i <= 5; i++) {
    const k = process.env[`GEMINI_TEXT_KEY_${i}`];
    if (k && k !== `AIzaSy_your_key_${i}_here`) {
      keys.push({
        keyId: `gemini_text_${i}`,
        value: k,
        status: 'active',       // active | cooldown | exhausted
        cooldownUntil: null,    // timestamp ms, null = aktif
        requestsToday: 0,
        errorsToday: 0,
      });
    }
  }
  if (keys.length === 0) {
    throw new Error('[TextOrchestrator] FATAL: Tidak ada GEMINI_TEXT_KEY yang valid di .env');
  }
  return keys;
}

const keyPool = loadTextKeys();
let currentIndex = 0; // pointer round-robin

const GEMINI_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models';
const MODEL = process.env.GEMINI_TEXT_MODEL || 'gemini-2.5-flash';
const VISION_MODEL = process.env.GEMINI_VISION_MODEL || 'gemini-2.0-flash';
// Fallback models jika primary gagal
const MODEL_FALLBACKS = ['gemini-2.5-flash', 'gemini-2.0-flash-lite', 'gemini-1.5-flash'];

// ── Cooldown Management ──────────────────────────────────────
const COOLDOWN_429_MS = 60_000;   // 1 menit jika rate limit
const COOLDOWN_5XX_MS = 300_000;  // 5 menit jika server error

function isKeyAvailable(key) {
  if (key.status === 'exhausted') return false;
  if (key.status === 'cooldown' && key.cooldownUntil > Date.now()) return false;
  // Auto-recover setelah cooldown habis
  if (key.status === 'cooldown' && key.cooldownUntil <= Date.now()) {
    key.status = 'active';
    key.cooldownUntil = null;
  }
  return true;
}

function setCooldown(key, durationMs, reason) {
  key.status = 'cooldown';
  key.cooldownUntil = Date.now() + durationMs;
  key.errorsToday += 1;
  console.warn(`[TextOrchestrator] Key ${key.keyId} cooldown ${durationMs / 1000}s — ${reason}`);
}

function getNextAvailableKey() {
  const total = keyPool.length;
  for (let attempt = 0; attempt < total; attempt++) {
    const idx = (currentIndex + attempt) % total;
    if (isKeyAvailable(keyPool[idx])) {
      currentIndex = (idx + 1) % total; // advance pointer
      return keyPool[idx];
    }
  }
  return null; // semua key sedang cooldown/exhausted
}

// ── Status Summary (untuk endpoint admin) ───────────────────
function getPoolStatus() {
  return keyPool.map((k) => ({
    keyId: k.keyId,
    status: isKeyAvailable(k) ? 'active' : k.status,
    cooldownUntil: k.cooldownUntil,
    requestsToday: k.requestsToday,
    errorsToday: k.errorsToday,
  }));
}

// ── Fallback ke OpenAI ───────────────────────────────────────
async function callOpenAIFallback(systemPrompt, userPrompt) {
  const openaiKey = process.env.OPENAI_FALLBACK_KEY;
  if (!openaiKey || openaiKey.startsWith('sk-your')) {
    throw new Error('Fallback OpenAI key tidak dikonfigurasi');
  }

  console.log('[TextOrchestrator] Menggunakan fallback OpenAI GPT-4o-mini');

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${openaiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      max_tokens: 2048,
      temperature: 0.8,
    }),
  });

  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(`OpenAI fallback error ${response.status}: ${err.error?.message || 'unknown'}`);
  }

  const data = await response.json();
  return data.choices[0].message.content.trim();
}

// ── Core: generateText ───────────────────────────────────────
/**
 * @param {string} systemPrompt
 * @param {string} userPrompt
 * @param {object} options - { useVision, imageBase64, maxTokens }
 * @returns {Promise<string>} teks hasil generate
 */
async function generateText(systemPrompt, userPrompt, options = {}) {
  const MAX_RETRIES = 5;
  let lastError = null;

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    const key = getNextAvailableKey();

    // Semua Gemini key tidak tersedia → fallback ke OpenAI
    if (!key) {
      console.warn('[TextOrchestrator] Semua Gemini key tidak tersedia, mencoba fallback OpenAI');
      try {
        return await callOpenAIFallback(systemPrompt, userPrompt);
      } catch (fallbackErr) {
        throw new Error(
          `Semua AI provider tidak tersedia. Coba lagi beberapa menit. Detail: ${fallbackErr.message}`
        );
      }
    }

    try {
      const useModel = options.useVision ? VISION_MODEL : MODEL;
      const endpoint = `${GEMINI_BASE_URL}/${useModel}:generateContent?key=${key.value}`;

      // Build request body
      const parts = [];
      if (options.useVision && options.imageBase64) {
        parts.push({
          inline_data: { mime_type: 'image/jpeg', data: options.imageBase64 },
        });
      }
      parts.push({ text: userPrompt });

      const body = {
        system_instruction: { parts: [{ text: systemPrompt }] },
        contents: [{ parts }],
        generationConfig: {
          maxOutputTokens: options.maxTokens || 2048,
          temperature: options.temperature || 0.8,
        },
      };

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(30_000), // 30s timeout
      });

      key.requestsToday += 1;

      // ── Handle berbagai status code ──────────────────────
      if (response.status === 429) {
        setCooldown(key, COOLDOWN_429_MS, 'Rate limit 429');
        lastError = new Error(`Key ${key.keyId} rate limited`);
        continue; // retry dengan key lain
      }

      if (response.status >= 500) {
        setCooldown(key, COOLDOWN_5XX_MS, `Server error ${response.status}`);
        lastError = new Error(`Gemini server error ${response.status}`);
        continue;
      }

      if (!response.ok) {
        const errBody = await response.json().catch(() => ({}));
        const msg = errBody.error?.message || `HTTP ${response.status}`;
        // Error 400 (bad request) → jangan retry, langsung throw
        throw new Error(`Gemini API error: ${msg}`);
      }

      const data = await response.json();
      const candidates = data?.candidates;
      if (!candidates || candidates.length === 0) {
        throw new Error('Gemini mengembalikan response kosong');
      }

      const text = candidates[0]?.content?.parts?.[0]?.text;
      if (!text) throw new Error('Format response Gemini tidak valid');

      return text.trim();
    } catch (err) {
      // Timeout atau network error → cooldown singkat
      if (err.name === 'TimeoutError' || err.name === 'AbortError') {
        setCooldown(key, COOLDOWN_429_MS, 'Request timeout');
        lastError = err;
        continue;
      }
      // Error non-retriable (400, dll) → langsung throw
      throw err;
    }
  }

  // Semua retry habis
  throw lastError || new Error('Text generation gagal setelah semua retry');
}

// ── generateJson: wrapper untuk output JSON ──────────────────
async function generateJson(systemPrompt, userPrompt, options = {}) {
  const raw = await generateText(systemPrompt, userPrompt, options);
  try {
    let cleaned = raw;
    if (cleaned.includes('```json')) {
      cleaned = cleaned.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();
    } else if (cleaned.includes('```')) {
      cleaned = cleaned.replace(/```\s*/g, '').trim();
    }
    return JSON.parse(cleaned);
  } catch {
    return { _raw: raw, _parseError: true };
  }
}

module.exports = { generateText, generateJson, getPoolStatus };
