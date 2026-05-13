/**
 * IMAGE ORCHESTRATOR — KreaSea Backend
 * ─────────────────────────────────────────────────────────
 * Mengelola pool 5 API Key Stability AI untuk image generation:
 * AI Image, Logo Maker, dll.
 *
 * Strategi:
 * - Round-robin: distribusi merata antar key
 * - Auto-skip: jika key kena 429 atau credits habis, cooldown → next key
 * - Fallback: jika semua Stability key limit → switch ke Replicate API
 * - Max retry: 5x
 */

const fetch = (...args) => import('node-fetch').then(({ default: f }) => f(...args));

// ── Key Pool: baca dari environment ─────────────────────────
function loadImageKeys() {
  const keys = [];
  for (let i = 1; i <= 5; i++) {
    const k = process.env[`STABILITY_IMAGE_KEY_${i}`];
    if (k && !k.startsWith('sk-your_stability')) {
      keys.push({
        keyId: `stability_img_${i}`,
        value: k,
        status: 'active',
        cooldownUntil: null,
        requestsToday: 0,
        errorsToday: 0,
        creditsLow: false,
      });
    }
  }
  if (keys.length === 0) {
    throw new Error('[ImageOrchestrator] FATAL: Tidak ada STABILITY_IMAGE_KEY yang valid di .env');
  }
  return keys;
}

const keyPool = loadImageKeys();
let currentIndex = 0;

const STABILITY_BASE_URL = 'https://api.stability.ai/v1/generation';
const DEFAULT_MODEL = process.env.STABILITY_IMAGE_MODEL || 'stable-diffusion-xl-1024-v1-0';

const COOLDOWN_429_MS = 60_000;
const COOLDOWN_5XX_MS = 300_000;
const COOLDOWN_LOW_CREDIT_MS = 3_600_000; // 1 jam jika credit < threshold

function isKeyAvailable(key) {
  if (key.status === 'exhausted') return false;
  if (key.status === 'cooldown' && key.cooldownUntil > Date.now()) return false;
  if (key.status === 'cooldown' && key.cooldownUntil <= Date.now()) {
    key.status = 'active';
    key.cooldownUntil = null;
    key.creditsLow = false;
  }
  return true;
}

function setCooldown(key, durationMs, reason) {
  key.status = 'cooldown';
  key.cooldownUntil = Date.now() + durationMs;
  key.errorsToday += 1;
  console.warn(`[ImageOrchestrator] Key ${key.keyId} cooldown ${durationMs / 1000}s — ${reason}`);
}

function getNextAvailableKey() {
  const total = keyPool.length;
  for (let i = 0; i < total; i++) {
    const idx = (currentIndex + i) % total;
    if (isKeyAvailable(keyPool[idx])) {
      currentIndex = (idx + 1) % total;
      return keyPool[idx];
    }
  }
  return null;
}

function getPoolStatus() {
  return keyPool.map((k) => ({
    keyId: k.keyId,
    status: isKeyAvailable(k) ? 'active' : k.status,
    cooldownUntil: k.cooldownUntil,
    requestsToday: k.requestsToday,
    errorsToday: k.errorsToday,
    creditsLow: k.creditsLow,
  }));
}

// ── Fallback ke Replicate ─────────────────────────────────────
async function callReplicateFallback(prompt, negativePrompt, width, height) {
  const replicateKey = process.env.REPLICATE_FALLBACK_KEY;
  if (!replicateKey || replicateKey.startsWith('r8_your')) {
    throw new Error('Fallback Replicate key tidak dikonfigurasi');
  }

  console.log('[ImageOrchestrator] Menggunakan fallback Replicate SDXL');

  // Create prediction
  const createRes = await fetch('https://api.replicate.com/v1/predictions', {
    method: 'POST',
    headers: {
      Authorization: `Token ${replicateKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      version: '7762fd07cf82c948538e41f63f77d685e02b063e37ec1375916f7fadb4ffd2ab', // SDXL
      input: {
        prompt,
        negative_prompt: negativePrompt,
        width,
        height,
        num_outputs: 1,
        num_inference_steps: 30,
      },
    }),
  });

  if (!createRes.ok) throw new Error(`Replicate create error: ${createRes.status}`);
  const prediction = await createRes.json();

  // Poll result (max 60s)
  const pollUrl = `https://api.replicate.com/v1/predictions/${prediction.id}`;
  for (let i = 0; i < 12; i++) {
    await new Promise((r) => setTimeout(r, 5000));
    const pollRes = await fetch(pollUrl, {
      headers: { Authorization: `Token ${replicateKey}` },
    });
    const result = await pollRes.json();
    if (result.status === 'succeeded') {
      // Fetch image and convert to base64
      const imgRes = await fetch(result.output[0]);
      const buffer = await imgRes.arrayBuffer();
      return Buffer.from(buffer).toString('base64');
    }
    if (result.status === 'failed') throw new Error(`Replicate prediction failed: ${result.error}`);
  }
  throw new Error('Replicate timeout: prediction tidak selesai dalam 60 detik');
}

// ── Aspect ratio → width/height SDXL ────────────────────────
function getSDXLDimensions(aspectRatio) {
  const map = {
    '1:1': { width: 1024, height: 1024 },
    '16:9': { width: 1344, height: 768 },
    '9:16': { width: 768, height: 1344 },
    '4:3': { width: 1152, height: 896 },
    '3:4': { width: 896, height: 1152 },
  };
  return map[aspectRatio] || map['1:1'];
}

// ── Style preset mapping ─────────────────────────────────────
function mapMoodToStylePreset(mood) {
  const map = {
    Minimalis: 'enhance',
    'Playful/Ceria': 'digital-art',
    'Elegan/Mewah': 'photographic',
    Vintage: 'analog-film',
    Futuristic: 'neon-punk',
    '3D Render': '3d-model',
    Logo: 'enhance',
  };
  return map[mood] || 'enhance';
}

// ── Core: generateImage ──────────────────────────────────────
/**
 * @param {object} params
 * @param {string} params.prompt          - Prompt positif
 * @param {string} params.negativePrompt  - Prompt negatif
 * @param {string} params.aspectRatio     - '1:1' | '16:9' | '9:16' | '4:3' | '3:4'
 * @param {string} params.mood            - Gaya visual
 * @param {number} params.samples         - Jumlah gambar (default 1)
 * @returns {Promise<string[]>} Array base64 images
 */
async function generateImage({ prompt, negativePrompt, aspectRatio = '1:1', mood = '', samples = 1 }) {
  const MAX_RETRIES = 5;
  let lastError = null;
  const { width, height } = getSDXLDimensions(aspectRatio);
  const stylePreset = mapMoodToStylePreset(mood);

  const finalPrompt = `${prompt}, masterpiece, best quality, ultra-detailed, professional photography`;
  const finalNegative =
    negativePrompt ||
    'text, watermark, signature, blurry, low quality, bad anatomy, distorted, ugly, pixelated, amateur, cropped';

  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    const key = getNextAvailableKey();

    if (!key) {
      console.warn('[ImageOrchestrator] Semua Stability key tidak tersedia, mencoba fallback Replicate');
      try {
        const base64 = await callReplicateFallback(finalPrompt, finalNegative, width, height);
        return [base64];
      } catch (fallbackErr) {
        throw new Error(
          `Semua image provider tidak tersedia. Coba lagi beberapa menit. Detail: ${fallbackErr.message}`
        );
      }
    }

    try {
      const url = `${STABILITY_BASE_URL}/${DEFAULT_MODEL}/text-to-image`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          Authorization: `Bearer ${key.value}`,
        },
        body: JSON.stringify({
          text_prompts: [
            { text: finalPrompt, weight: 1 },
            { text: finalNegative, weight: -1 },
          ],
          cfg_scale: 7,
          height,
          width,
          samples: Math.min(samples, 4), // max 4 per request
          steps: 40,
          style_preset: stylePreset,
        }),
        signal: AbortSignal.timeout(60_000), // 60s timeout untuk image
      });

      key.requestsToday += 1;

      if (response.status === 429) {
        setCooldown(key, COOLDOWN_429_MS, 'Rate limit 429');
        lastError = new Error(`Key ${key.keyId} rate limited`);
        continue;
      }

      if (response.status === 402) {
        // Credits habis
        key.creditsLow = true;
        setCooldown(key, COOLDOWN_LOW_CREDIT_MS, 'Credits habis (402)');
        lastError = new Error(`Key ${key.keyId} credits habis`);
        continue;
      }

      if (response.status >= 500) {
        setCooldown(key, COOLDOWN_5XX_MS, `Server error ${response.status}`);
        lastError = new Error(`Stability server error ${response.status}`);
        continue;
      }

      if (!response.ok) {
        const errBody = await response.json().catch(() => ({}));
        throw new Error(`Stability AI error: ${errBody.message || response.status}`);
      }

      const data = await response.json();
      const images = data.artifacts?.map((a) => a.base64) || [];
      if (images.length === 0) throw new Error('Stability AI mengembalikan 0 gambar');

      return images;
    } catch (err) {
      if (err.name === 'TimeoutError' || err.name === 'AbortError') {
        setCooldown(key, COOLDOWN_429_MS, 'Request timeout');
        lastError = err;
        continue;
      }
      throw err;
    }
  }

  throw lastError || new Error('Image generation gagal setelah semua retry');
}

module.exports = { generateImage, getPoolStatus };
