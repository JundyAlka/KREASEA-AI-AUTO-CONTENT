/**
 * IMAGE ORCHESTRATOR — KreaSea Backend v10
 * ─────────────────────────────────────────────────────────
 * PRIMARY:   NVIDIA NIM FLUX.2-klein-4b (key rotation)
 * SECONDARY: X5Lab gateway (gpt-image-1 / dall-e-3) — OpenAI-compatible
 * TERTIARY:  Pollinations.ai (gratis, didownload → base64, bebas CORS)
 *
 * Flow:
 *   NVIDIA Key 1 → NVIDIA Key 2 → X5Lab (gpt-image-1 → dall-e-3) → Pollinations
 *
 * CATATAN Gemini:
 *   Gemini keys dipakai HANYA di text-orchestrator.js
 */

const fetch = (...args) => import('node-fetch').then(({ default: f }) => f(...args));

// ═══════════════════════════════════════════════════════════
//  CONSTANTS
// ═══════════════════════════════════════════════════════════

const NVIDIA_ENDPOINT    = 'https://ai.api.nvidia.com/v1/genai/black-forest-labs/flux.2-klein-4b';
const POLLINATIONS_BASE  = 'https://image.pollinations.ai/prompt';
const X5LAB_BASE_URL     = process.env.X5LAB_BASE_URL || 'https://api.x5lab.dev/v1';
const X5LAB_API_KEY      = process.env.X5LAB_API_KEY || '';
const X5LAB_IMAGE_MODELS = (process.env.X5LAB_IMAGE_MODEL || 'dall-e-3,gpt-image-1').split(',').map(s => s.trim());

const COOLDOWN_429  = 60_000;   // 1 menit — rate limited
const COOLDOWN_402  = 300_000;  // 5 menit — credits habis
const COOLDOWN_5XX  = 120_000;  // 2 menit — server error

const PLACEHOLDER_PATTERNS = [
  'your_', 'your-', 'placeholder', 'example', 'sk-your', 'nvapi-your',
];

// ═══════════════════════════════════════════════════════════
//  SMART PROMPT ENGINEERING
// ═══════════════════════════════════════════════════════════

const MOOD_STYLES = {
  // ── Styles utama untuk UMKM Indonesia ──────────────────────────
  'Minimalis': {
    style: 'clean minimalist design, pure white background, elegant simplicity, ample negative space',
    lighting: 'soft diffused lighting, subtle shadows',
    quality: 'crisp sharp edges, clean lines, professional',
  },
  'Playful/Ceria': {
    style: 'vibrant colorful playful design, cheerful energetic composition, fun dynamic elements',
    lighting: 'bright upbeat lighting, warm tones',
    quality: 'bold saturated colors, lively, joyful atmosphere',
  },
  'Elegan/Mewah': {
    style: 'luxury premium elegant design, gold accents, sophisticated composition, opulent details',
    lighting: 'dramatic studio lighting, rim light, deep shadows',
    quality: 'rich textures, premium materials, high-end fashion aesthetic',
  },
  'Photography': {
    style: 'professional product photography, DSLR quality, commercial photography style',
    lighting: 'professional studio lighting, softbox, catchlights',
    quality: 'tack sharp focus, perfect exposure, commercial grade',
  },
  'Flat Design': {
    style: 'flat design, geometric shapes, bold primary colors, vector art style, icon-like clarity',
    lighting: 'flat even lighting, no harsh shadows',
    quality: 'clean bold graphics, strong visual hierarchy, scalable design',
  },
  '3D Render': {
    style: '3D render, realistic materials, volumetric rendering, depth of field, product visualization',
    lighting: 'professional studio 3-point lighting, HDRI environment, subtle reflections',
    quality: 'photorealistic, octane render quality, subsurface scattering',
  },
  // ── Styles baru khusus UMKM Indonesia ──────────────────────────
  'Warm & Cozy': {
    style: 'warm cozy atmosphere, natural wooden textures, soft bokeh background, lifestyle photography, Indonesian tropical warmth, rattan and natural elements',
    lighting: 'warm golden hour light, soft diffused window light, candlelight ambiance',
    quality: 'inviting, comfortable, authentic, lifestyle photography, warm tones',
  },
  'Bold Promo': {
    style: 'bold graphic promotional design, high contrast commercial poster, eye-catching sale advertisement, dynamic diagonal composition, strong typography space',
    lighting: 'bright punchy studio lighting, high contrast, vivid saturated colors',
    quality: 'energetic, urgent, attention-grabbing, commercial grade promotional material',
  },
  'Clean Studio': {
    style: 'pure white seamless background, clean studio product shot, e-commerce ready photography, no distracting elements, product-centered composition',
    lighting: 'professional studio lighting, softbox, even white light, catchlights on product',
    quality: 'marketplace quality, crisp and clean, Tokopedia/Shopee ready, sharp product detail',
  },
  'Pastel Aesthetic': {
    style: 'soft pastel colors, aesthetic lifestyle photography, Korean-inspired composition, fresh and light color palette, trendy social media aesthetic',
    lighting: 'bright airy light, soft natural light, pastel color grading',
    quality: 'Instagram-ready, aesthetic, trendy, youthful, fresh and clean',
  },
  'Ramadan / Islami': {
    style: 'Islamic aesthetic design, golden crescent moon and star motif, ornate geometric patterns, lantern silhouettes, mosque architecture elements, green and gold color palette',
    lighting: 'warm golden light, festive ambiance, soft glowing lanterns',
    quality: 'elegant Islamic design, Eid Mubarak mood, warm and spiritual atmosphere',
  },
  // ── Styles niche (tetap ada untuk kebutuhan khusus) ────────────
  'Futuristic': {
    style: 'futuristic modern design, clean tech aesthetic, geometric precision, digital innovation visual',
    lighting: 'cool blue-white studio lighting, clean and precise',
    quality: 'high-tech aesthetic, modern, innovative, professional tech brand',
  },
  'Vintage': {
    style: 'vintage retro design, warm nostalgic tones, classic aesthetic, heritage brand feel',
    lighting: 'warm golden hour light, faded vignette',
    quality: 'nostalgic color palette, timeless composition, artisanal heritage feel',
  },
  'Watercolor': {
    style: 'watercolor painting, soft organic brush strokes, fluid color blending, artistic texture',
    lighting: 'soft natural light, gentle warm tones',
    quality: 'handcrafted artistic look, delicate washes, paper texture',
  },
  'Neon Glow': {
    style: 'neon glow aesthetic, dark moody background, electric luminescent colors, light trails',
    lighting: 'neon backlighting, dramatic atmospheric glow',
    quality: 'vivid electric colors, dark contrast, nightlife energy',
  },
};

function getDimensions(aspectRatio) {
  const map = {
    '1:1':  { width: 1024, height: 1024, composition: 'square centered composition' },
    '16:9': { width: 1344, height: 768,  composition: 'wide cinematic composition, landscape orientation' },
    '9:16': { width: 768,  height: 1344, composition: 'vertical portrait composition, social media story format' },
    '4:3':  { width: 1152, height: 896,  composition: 'standard landscape composition' },
    '3:4':  { width: 896,  height: 1152, composition: 'portrait composition, editorial format' },
    '21:9': { width: 1344, height: 576,  composition: 'ultra-wide cinematic panoramic composition' },
  };
  return map[aspectRatio] || map['1:1'];
}

// ═══════════════════════════════════════════════════════════
//  PURPOSE RECIPES — Setiap tujuan visual punya DNA visual sendiri
//  Ini yang memastikan "Promo Diskon" tidak tampil seperti "Vintage"
// ═══════════════════════════════════════════════════════════

const PURPOSE_RECIPES = {
  // ── Promosi / Diskon ────────────────────────────────────
  'promo': {
    visualDna: 'bold promotional graphic, eye-catching sale announcement, vibrant commercial advertisement',
    subject:   'prominent product or offer in the center, large discount badge or percentage visible',
    atmosphere:'energetic, urgent, exciting commercial energy, high contrast, attention-grabbing',
    colors:    'bright vivid colors, high saturation, strong contrast between elements',
    forbidden: ['vintage', 'aged', 'nostalgic', 'sepia', 'film grain', 'retro', 'muted colors'],
  },
  'diskon': {
    visualDna: 'bold promotional graphic, eye-catching sale announcement, vibrant commercial advertisement',
    subject:   'prominent product or offer in the center, large discount badge or percentage visible',
    atmosphere:'energetic, urgent, exciting commercial energy, high contrast, attention-grabbing',
    colors:    'bright vivid colors, high saturation, strong contrast between elements',
    forbidden: ['vintage', 'aged', 'nostalgic', 'sepia', 'film grain', 'retro', 'muted colors'],
  },
  // ── Produk Showcase ─────────────────────────────────────
  'produk': {
    visualDna: 'professional product photography, commercial product showcase, e-commerce hero image',
    subject:   'product as the clear hero, centered and well-lit, showing details and quality',
    atmosphere:'clean, premium, trustworthy, studio quality',
    colors:    'clean neutral backgrounds that let product shine, professional color grading',
    forbidden: ['cluttered background', 'busy pattern', 'distracting elements'],
  },
  'product': {
    visualDna: 'professional product photography, commercial product showcase, e-commerce hero image',
    subject:   'product as the clear hero, centered and well-lit, showing details and quality',
    atmosphere:'clean, premium, trustworthy, studio quality',
    colors:    'clean neutral backgrounds that let product shine, professional color grading',
    forbidden: [],
  },
  // ── Pengumuman ───────────────────────────────────────────
  'pengumuman': {
    visualDna: 'clear announcement visual, important message graphic, bold announcement design',
    subject:   'strong central visual element communicating the announcement, clear hierarchy',
    atmosphere:'professional, trustworthy, clear and direct communication',
    colors:    'authoritative colors: deep blue, corporate tones, or brand-appropriate palette',
    forbidden: [],
  },
  // ── Testimoni ────────────────────────────────────────────
  'testimoni': {
    visualDna: 'customer testimonial graphic, trust-building social proof visual, authentic review design',
    subject:   'warm and inviting composition suggesting real customer satisfaction and trust',
    atmosphere:'warm, authentic, trustworthy, approachable and genuine',
    colors:    'warm friendly colors, soft and inviting palette',
    forbidden: [],
  },
  // ── Quotes ───────────────────────────────────────────────
  'quotes': {
    visualDna: 'inspirational quote graphic, motivational visual, typography-friendly background',
    subject:   'beautiful atmospheric background that complements text overlay, space for quote',
    atmosphere:'inspirational, thoughtful, aesthetic and mood-evoking',
    colors:    'harmonious palette that supports readability of overlay text',
    forbidden: [],
  },
  // ── Menu / Katalog ───────────────────────────────────────
  'menu': {
    visualDna: 'food menu photography, appetizing culinary visual, restaurant menu style',
    subject:   'beautifully presented food or drinks, appetizing close-up, making viewer hungry',
    atmosphere:'warm inviting restaurant ambiance, delicious and appetizing',
    colors:    'warm appetizing tones, rich food photography colors',
    forbidden: [],
  },
  'katalog': {
    visualDna: 'product catalog layout visual, organized product display, clean catalog photography',
    subject:   'clean organized product arrangement, professional catalog-style composition',
    atmosphere:'clean, professional, organized and trustworthy',
    colors:    'neutral professional palette with brand accent colors',
    forbidden: [],
  },
  // ── Event / Undangan ────────────────────────────────────
  'event': {
    visualDna: 'event promotional graphic, party invitation visual, celebration announcement design',
    subject:   'festive celebratory visual communicating event theme and excitement',
    atmosphere:'festive, exciting, celebratory, creating anticipation and FOMO',
    colors:    'vibrant festive colors matching event theme, energetic and celebratory palette',
    forbidden: [],
  },
  'undangan': {
    visualDna: 'elegant invitation design, formal event announcement, celebration visual',
    subject:   'elegant decorative composition suggesting celebration and special occasion',
    atmosphere:'elegant, special, celebratory and memorable',
    colors:    'sophisticated palette: gold, cream, or event theme colors',
    forbidden: [],
  },
  // ── Thumbnail Video ──────────────────────────────────────
  'thumbnail': {
    visualDna: 'YouTube thumbnail design, video thumbnail graphic, click-worthy thumbnail',
    subject:   'bold eye-catching central element, high contrast, designed to stand out in feed',
    atmosphere:'high energy, dramatic, curiosity-inducing, must-click visual',
    colors:    'bold high-contrast colors, yellow/red accents for urgency, vibrant and loud',
    forbidden: ['muted', 'subtle', 'calm', 'soft', 'quiet'],
  },
  // ── Cover Highlight ──────────────────────────────────────
  'cover': {
    visualDna: 'Instagram highlight cover, social media story cover, clean branded cover design',
    subject:   'clean iconic visual with strong brand identity, simple and recognizable',
    atmosphere:'branded, clean, consistent and aesthetically pleasing',
    colors:    'brand-consistent color palette, clean and minimal',
    forbidden: [],
  },
  // ── Default fallback ────────────────────────────────────
  'default': {
    visualDna: 'professional commercial visual content',
    subject:   'clear focal point, well-composed',
    atmosphere:'professional, high quality, polished',
    colors:    'appropriate professional color palette',
    forbidden: [],
  },
};
const PURPOSE_MOOD_RULES = {
  promo: ['Bold Promo', 'Playful/Ceria', 'Flat Design', '3D Render', 'Clean Studio'],
  diskon: ['Bold Promo', 'Playful/Ceria', 'Flat Design', '3D Render', 'Clean Studio'],
  produk: ['Clean Studio', 'Photography', 'Minimalis', 'Elegan/Mewah', '3D Render'],
  product: ['Clean Studio', 'Photography', 'Minimalis', 'Elegan/Mewah', '3D Render'],
  pengumuman: ['Minimalis', 'Flat Design', 'Bold Promo', 'Clean Studio'],
  testimoni: ['Warm & Cozy', 'Photography', 'Pastel Aesthetic', 'Minimalis'],
  quotes: ['Minimalis', 'Pastel Aesthetic', 'Watercolor', 'Elegan/Mewah'],
  menu: ['Warm & Cozy', 'Photography', 'Clean Studio', 'Elegan/Mewah'],
  katalog: ['Clean Studio', 'Photography', 'Minimalis', '3D Render'],
  event: ['Playful/Ceria', 'Elegan/Mewah', 'Ramadan / Islami', 'Bold Promo'],
  undangan: ['Elegan/Mewah', 'Ramadan / Islami', 'Pastel Aesthetic', 'Minimalis'],
  thumbnail: ['Bold Promo', 'Playful/Ceria', 'Futuristic', '3D Render'],
  cover: ['Minimalis', 'Pastel Aesthetic', 'Flat Design', 'Elegan/Mewah'],
  default: ['Minimalis', 'Photography', 'Clean Studio', 'Bold Promo', 'Playful/Ceria'],
};

function isUsableSecret(value) {
  if (!value || !value.trim()) return false;
  const lower = value.trim().toLowerCase();
  return !PLACEHOLDER_PATTERNS.some(pattern => lower.includes(pattern));
}

function getPurposeKey(purpose) {
  if (!purpose) return 'default';
  const lower = purpose.toLowerCase();
  for (const key of Object.keys(PURPOSE_RECIPES)) {
    if (key !== 'default' && lower.includes(key)) return key;
  }
  return 'default';
}

/**
 * Cari recipe yang paling cocok untuk purpose yang diberikan
 */
function getPurposeRecipe(purpose) {
  return PURPOSE_RECIPES[getPurposeKey(purpose)] || PURPOSE_RECIPES.default;
}

function normalizeMoodForPurpose(purpose, mood) {
  const purposeKey = getPurposeKey(purpose);
  const allowed = PURPOSE_MOOD_RULES[purposeKey] || PURPOSE_MOOD_RULES.default;
  if (allowed.includes(mood)) return { mood, changed: false, allowed, purposeKey };

  const fallbackMood = allowed[0] || 'Minimalis';
  console.log(`[PromptBuilder] Mood "${mood}" tidak cocok untuk purpose "${purpose}" - diganti ke "${fallbackMood}"`);
  return { mood: fallbackMood, changed: true, allowed, purposeKey };
}

/**
 * Bangun prompt yang purpose-aware
 * Mood/style MENAMBAH ke purpose, TIDAK mengoverride-nya
 * Jika mood bertentangan dengan purpose, mood akan dikurangi kekuatannya
 */
function buildSmartPrompt({ prompt, negativePrompt = '', mood, aspectRatio, purpose, businessName, businessType }) {
  const recipe = getPurposeRecipe(purpose);
  const moodData = MOOD_STYLES[mood] || {
    style: 'professional design high quality',
    lighting: 'balanced professional lighting',
    quality: 'high quality, detailed',
  };
  const { composition } = getDimensions(aspectRatio);

  // Cek apakah mood bertentangan dengan purpose
  const forbidden = recipe.forbidden || [];
  const moodStyleLower = moodData.style.toLowerCase();
  const moodConflicts = forbidden.some(f => moodStyleLower.includes(f));

  // Tentukan style modifier berdasarkan conflict check
  let styleModifier;
  if (moodConflicts) {
    // Mood bertentangan — pakai lighting + quality dari mood, tapi skip style-nya
    // Contoh: "Promo Diskon" + "Vintage" → pakai vintage lighting tapi gaya tetap promotional
    styleModifier = `${moodData.lighting}, ${moodData.quality}`;
    console.log(`[PromptBuilder] ⚠️ Mood "${mood}" bertentangan dengan purpose "${purpose}" — style override dinonaktifkan`);
  } else {
    // Mood cocok — gunakan penuh
    styleModifier = `${moodData.style}, ${moodData.lighting}, ${moodData.quality}`;
  }

  let businessCtx = '';
  if (businessName || businessType) {
    businessCtx = `for ${businessName || 'a business'}${businessType ? ` (${businessType})` : ''}`;
  }

  // ── BUILD PROMPT (urutan prioritas: subject → purpose DNA → business → style → quality) ──
  const positivePrompt = [
    // 1. Subject user (PALING penting — jangan pernah terkubur)
    prompt.trim(),
    // 2. Context bisnis
    businessCtx,
    // 3. Visual DNA berdasarkan PURPOSE (paling menentukan karakter gambar)
    recipe.visualDna,
    // 4. Subject guidance dari purpose
    recipe.subject,
    // 5. Atmosphere dari purpose
    recipe.atmosphere,
    // 6. Color dari purpose
    recipe.colors,
    // 7. Style dari mood (SETELAH purpose agar tidak override)
    styleModifier,
    // 8. Komposisi berdasarkan aspect ratio
    composition,
    // 9. Quality boosters universal
    'masterpiece, best quality, ultra-detailed, sharp focus, professional photography, commercial grade',
  ].filter(Boolean).join(', ');

  // Negative prompt: gabungkan forbidden dari recipe + user negative + base
  const recipeNegative = forbidden.length > 0
    ? `${forbidden.join(', ')}, ` : '';

  const baseNegative = [
    `${recipeNegative}blurry, out of focus, low quality, pixelated, grainy, noisy`,
    'ugly, deformed, distorted, bad anatomy',
    'text overlay, watermark, logo, signature',
    'overexposed, underexposed, bad lighting, harsh shadows',
    negativePrompt || '',
  ].filter(Boolean).join(', ');

  console.log(`[PromptBuilder] Purpose: "${purpose}" | Mood: "${mood}" | Conflict: ${moodConflicts}`);
  console.log(`[PromptBuilder] Positive (${positivePrompt.length}c): ${positivePrompt.substring(0, 150)}...`);

  return { positive: positivePrompt, negative: baseNegative };
}

// ═══════════════════════════════════════════════════════════
//  NVIDIA FLUX — PRIMARY PROVIDER
// ═══════════════════════════════════════════════════════════

function loadNvidiaKeys() {
  const keys = [];
  const seen = new Set();

  const addKey = (id, value) => {
    const trimmed = value?.trim();
    if (!isUsableSecret(trimmed) || seen.has(trimmed)) return;
    seen.add(trimmed);
    keys.push({ id, value: trimmed, status: 'active', cooldownUntil: null, requests: 0, errors: 0 });
  };

  for (let i = 1; i <= 20; i++) {
    addKey(`nvidia_key_${i}`, process.env[`NVIDIA_API_KEY_${i}`]);
  }

  (process.env.NVIDIA_API_KEYS || '')
    .split(/[\n,;]/)
    .map(k => k.trim())
    .filter(Boolean)
    .forEach((k, idx) => addKey(`nvidia_key_list_${idx + 1}`, k));

  addKey('nvidia_key_legacy', process.env.NVIDIA_API_KEY);

  if (keys.length === 0) {
    console.warn('[ImageOrchestrator] Tidak ada NVIDIA_API_KEY valid - akan pakai fallback provider');
  } else {
    console.log(`[ImageOrchestrator] ${keys.length} NVIDIA key(s): ${keys.map(k => k.id).join(', ')}`);
  }
  return keys;
}
const nvidiaKeyPool = loadNvidiaKeys();
let nvidiaPoolIndex = 0;

function isKeyAvailable(key) {
  if (key.status === 'exhausted') return false;
  if (key.status === 'cooldown') {
    if (key.cooldownUntil <= Date.now()) {
      key.status = 'active';
      key.cooldownUntil = null;
      console.log(`[ImageOrchestrator] Key ${key.id} cooldown selesai → aktif kembali`);
    } else return false;
  }
  return true;
}

function setCooldown(key, ms, reason) {
  key.status = 'cooldown';
  key.cooldownUntil = Date.now() + ms;
  key.errors += 1;
  console.warn(`[ImageOrchestrator] 🕐 ${key.id} cooldown ${ms/1000}s — ${reason}`);
}

function getNextNvidiaKey() {
  const total = nvidiaKeyPool.length;
  if (total === 0) return null;
  for (let i = 0; i < total; i++) {
    const idx = (nvidiaPoolIndex + i) % total;
    if (isKeyAvailable(nvidiaKeyPool[idx])) {
      nvidiaPoolIndex = (idx + 1) % total;
      return nvidiaKeyPool[idx];
    }
  }
  return null;
}

async function callNvidiaFlux(key, prompt, width, height) {
  console.log(`[ImageOrchestrator] → NVIDIA ${key.id}: ${width}x${height}`);

  const response = await fetch(NVIDIA_ENDPOINT, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': `Bearer ${key.value}`,
    },
    body: JSON.stringify({
      prompt,
      width,
      height,
      seed: Math.floor(Math.random() * 2147483647),
    }),
    signal: AbortSignal.timeout(150_000), // 150 detik — NVIDIA bisa lambat
  });

  key.requests += 1;
  console.log(`[ImageOrchestrator] NVIDIA response: ${response.status}`);

  if (response.status === 401) { key.status = 'exhausted'; throw new Error(`${key.id} tidak valid (401)`); }
  if (response.status === 402) { setCooldown(key, COOLDOWN_402, 'Credits habis'); throw new Error(`${key.id} credits habis`); }
  if (response.status === 429) {
    const retryAfter = parseInt(response.headers.get('retry-after') || '60', 10) * 1000;
    setCooldown(key, Math.max(retryAfter, COOLDOWN_429), 'Rate limited');
    throw new Error(`${key.id} rate limited`);
  }
  if (response.status === 422) {
    const body = await response.json().catch(() => ({}));
    throw new Error(`NVIDIA payload error: ${JSON.stringify(body.detail || body)}`);
  }
  if (response.status >= 500) {
    setCooldown(key, COOLDOWN_5XX, `Server error ${response.status}`);
    throw new Error(`NVIDIA server error ${response.status}`);
  }
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new Error(`NVIDIA error ${response.status}: ${body.detail || body.message || 'unknown'}`);
  }

  const data = await response.json();
  const artifacts = data.artifacts || data.images || [];
  if (artifacts.length === 0) throw new Error('NVIDIA returned 0 images');

  const first = artifacts[0];
  const base64 = typeof first === 'string' ? first : (first.base64 || first.image || '');
  if (!base64) throw new Error('NVIDIA base64 kosong');

  console.log(`[ImageOrchestrator] ✅ NVIDIA sukses ${key.id} — ${base64.length} chars`);
  return base64;
}

// ═══════════════════════════════════════════════════════════
//  POLLINATIONS — SECONDARY/FALLBACK
//  Backend men-download gambar → kirim sebagai base64
//  Ini menghindari CORS dan URL-too-long issues di Flutter Web
// ═══════════════════════════════════════════════════════════

/**
 * Build Pollinations URL dengan prompt yang sudah dipangkas aman
 */
function buildPollinationsUrl(prompt, width, height) {
  // Truncate prompt agar URL tidak terlalu panjang
  const maxPromptLen = 300;
  const safePrompt = prompt.length > maxPromptLen
    ? prompt.substring(0, maxPromptLen)
    : prompt;

  const seed = Math.floor(Math.random() * 9999999);
  const encoded = encodeURIComponent(safePrompt);
  const pollinKey = process.env.POLLINATIONS_API_KEY || '';
  const keyParam = pollinKey ? `&token=${pollinKey}` : '';

  return `${POLLINATIONS_BASE}/${encoded}?width=${width}&height=${height}&model=flux&seed=${seed}&nologo=true&safe=true${keyParam}`;
}

/**
 * Panggil Pollinations dan download gambar → return base64
 * Dengan ini Flutter tidak perlu akses URL Pollinations langsung
 * (menghindari CORS + masalah URL panjang)
 */
async function callPollinationsAsBase64(prompt, width, height) {
  const url = buildPollinationsUrl(prompt, width, height);
  console.log(`[ImageOrchestrator] → Pollinations (download→base64): ${url.substring(0, 80)}...`);

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'Accept': 'image/*',
      'User-Agent': 'KreaSea-Backend/1.0',
    },
    signal: AbortSignal.timeout(120_000), // 120 detik timeout (naik dari 90s)
  });

  if (!response.ok) {
    throw new Error(`Pollinations HTTP ${response.status}`);
  }

  const contentType = response.headers.get('content-type') || 'image/jpeg';
  const arrayBuffer = await response.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  const base64 = buffer.toString('base64');

  if (!base64 || base64.length < 1000) {
    throw new Error('Pollinations returned empty or too-small image');
  }

  console.log(`[ImageOrchestrator] ✅ Pollinations sukses — ${base64.length} chars (${contentType})`);

  // Return as data URI jika dibutuhkan oleh caller
  return {
    base64,
    contentType,
    dataUri: `data:${contentType};base64,${base64}`,
  };
}

// ═══════════════════════════════════════════════════════════
//  X5LAB — SECONDARY PROVIDER (OpenAI-compatible image API)
// ═══════════════════════════════════════════════════════════

let x5labAvailable = X5LAB_API_KEY && X5LAB_API_KEY.length > 10;

function getOpenAiCompatibleSize(model, width, height) {
  const ratio = width / height;
  const isSquare = Math.abs(ratio - 1) < 0.12;
  const isLandscape = width > height;

  if (model === 'dall-e-3') {
    if (isSquare) return '1024x1024';
    return isLandscape ? '1792x1024' : '1024x1792';
  }

  if (model === 'gpt-image-1') {
    if (isSquare) return '1024x1024';
    return isLandscape ? '1536x1024' : '1024x1536';
  }

  if (isSquare) return '1024x1024';
  return isLandscape ? '1536x1024' : '1024x1536';
}

async function callX5LabImage(prompt, width, height) {
  if (!x5labAvailable) throw new Error('X5Lab key tidak dikonfigurasi');

  const endpoint = `${X5LAB_BASE_URL}/images/generations`;
  const modelList = X5LAB_IMAGE_MODELS;

  for (const model of modelList) {
    const size = getOpenAiCompatibleSize(model, width, height);
    console.log(`[ImageOrchestrator] → X5Lab model=${model}: requested ${width}x${height}, using ${size}`);
    try {
      const body = {
        model,
        prompt,
        n: 1,
        size,
        response_format: 'url',
      };
      // gpt-image-1 tidak support response_format
      if (model === 'gpt-image-1') delete body.response_format;

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${X5LAB_API_KEY}`,
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(90_000),
      });

      console.log(`[ImageOrchestrator] X5Lab ${model} response: ${response.status}`);

      if (response.status === 404) {
        console.warn(`[ImageOrchestrator] X5Lab model ${model} tidak tersedia, coba model berikutnya`);
        continue;
      }
      if (!response.ok) {
        const err = await response.json().catch(() => ({}));
        throw new Error(`X5Lab ${model} error ${response.status}: ${err.error?.message || 'unknown'}`);
      }

      const data = await response.json();
      const imageUrl = data?.data?.[0]?.url || data?.data?.[0]?.b64_json;
      if (!imageUrl) throw new Error(`X5Lab ${model} tidak mengembalikan image URL`);

      // Jika base64 langsung
      if (data?.data?.[0]?.b64_json) {
        console.log(`[ImageOrchestrator] ✅ X5Lab ${model} sukses (base64)`);
        return { base64: data.data[0].b64_json, type: 'base64' };
      }

      // Download URL → base64 agar Flutter tidak kena CORS
      console.log(`[ImageOrchestrator] X5Lab ${model} mengembalikan URL, download...`);
      const imgResponse = await fetch(imageUrl, {
        signal: AbortSignal.timeout(60_000),
      });
      if (!imgResponse.ok) throw new Error(`Gagal download X5Lab image: ${imgResponse.status}`);
      const buffer = Buffer.from(await imgResponse.arrayBuffer());
      const base64 = buffer.toString('base64');
      console.log(`[ImageOrchestrator] ✅ X5Lab ${model} sukses — ${base64.length} chars`);
      return { base64, type: 'base64' };

    } catch (err) {
      console.warn(`[ImageOrchestrator] X5Lab ${model} gagal: ${err.message}`);
      if (model === modelList[modelList.length - 1]) throw err;
    }
  }
  throw new Error('Semua X5Lab models gagal');
}

// ═══════════════════════════════════════════════════════════
//  POOL STATUS
// ═══════════════════════════════════════════════════════════

function getPoolStatus() {
  return {
    nvidia: nvidiaKeyPool.map(k => ({
      id: k.id,
      status: isKeyAvailable(k) ? 'active' : k.status,
      cooldownUntil: k.cooldownUntil,
      requests: k.requests,
      errors: k.errors,
    })),
    x5lab: {
      status: x5labAvailable ? 'configured' : 'not_configured',
      models: X5LAB_IMAGE_MODELS,
      keyPrefix: X5LAB_API_KEY ? X5LAB_API_KEY.substring(0, 8) + '...' : 'none',
    },
    pollinations: { status: 'always_available', strategy: 'backend-download-as-base64' },
  };
}

// ═══════════════════════════════════════════════════════════
//  MAIN: generateImage
//  Flow: NVIDIA (key rotation) → Pollinations (download→base64)
// ═══════════════════════════════════════════════════════════

/**
 * @param {object} params
 * @param {string} params.prompt
 * @param {string} [params.negativePrompt]
 * @param {string} [params.aspectRatio]
 * @param {string} [params.mood]
 * @param {number} [params.samples]
 * @param {string} [params.purpose]
 * @param {string} [params.businessName]
 * @param {string} [params.businessType]
 * @param {boolean} [params.skipSmartPrompt]
 * @returns {Promise<{images: string[], type: 'base64'|'url', provider: string}>}
 */
async function generateImage({
  prompt,
  negativePrompt = '',
  aspectRatio = '1:1',
  mood = 'Minimalis',
  samples = 1,
  purpose = '',
  businessName = '',
  businessType = '',
  skipSmartPrompt = false,
}) {
  const { width, height } = getDimensions(aspectRatio);
  const moodSelection = normalizeMoodForPurpose(purpose, mood);
  const selectedMood = moodSelection.mood;

  // ── Build prompt ────────────────────────────────────────
  let finalPrompt = prompt;
  if (!skipSmartPrompt) {
    const built = buildSmartPrompt({ prompt, negativePrompt, mood: selectedMood, aspectRatio, purpose, businessName, businessType });
    finalPrompt = built.positive;
  }

  // ── STEP 1: NVIDIA FLUX (PRIMARY) ────────────────────────
  if (nvidiaKeyPool.length > 0) {
    console.log('[ImageOrchestrator] 🚀 Mencoba NVIDIA FLUX...');
    const maxAttempts = Math.min(nvidiaKeyPool.length + 1, 3);
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const key = getNextNvidiaKey();
      if (!key) {
        console.warn('[ImageOrchestrator] Semua NVIDIA key dalam cooldown');
        break;
      }
      try {
        const base64 = await callNvidiaFlux(key, finalPrompt, width, height);
        return {
          images: [base64],
          type: 'base64',
          provider: `NVIDIA FLUX (${key.id})`,
          styleUsed: selectedMood,
        };
      } catch (err) {
        console.warn(`[ImageOrchestrator] ${key.id} gagal: ${err.message}`);
      }
    }
    console.warn('[ImageOrchestrator] Semua NVIDIA key gagal → X5Lab');
  }

  // ── STEP 2: X5Lab (SECONDARY) — gpt-image-1 / dall-e-3 ──
  if (x5labAvailable) {
    console.log('[ImageOrchestrator] 🔄 Mencoba X5Lab (gpt-image-1 / dall-e-3)...');
    try {
      const result = await callX5LabImage(finalPrompt, width, height);
      return {
        images: [result.base64],
        type: 'base64',
        provider: 'X5Lab (DALL-E)',
        styleUsed: selectedMood,
      };
    } catch (x5Err) {
      console.warn(`[ImageOrchestrator] X5Lab gagal: ${x5Err.message} → Pollinations`);
    }
  }

  // ── STEP 3: Pollinations (TERTIARY — download→base64) ────
  // Backend download → base64 sehingga Flutter tidak kena CORS
  console.log('[ImageOrchestrator] 🔄 Mencoba Pollinations (server-side download)...');
  try {
    const result = await callPollinationsAsBase64(finalPrompt, width, height);
    return {
      images: [result.base64],
      type: 'base64', // selalu base64 sekarang!
      provider: 'Pollinations FLUX (via backend)',
      styleUsed: selectedMood,
    };
  } catch (polErr) {
    console.error(`[ImageOrchestrator] Pollinations gagal: ${polErr.message}`);
  }

  // ── LAST RESORT: Pollinations URL (jika download gagal) ──
  // Ini mungkin tidak tampil di Flutter Web karena CORS, tapi lebih baik daripada error
  console.warn('[ImageOrchestrator] ⚠️ Pollinations download gagal → URL fallback terakhir');
  const urls = Array.from({ length: Math.min(samples, 2) }, () =>
    buildPollinationsUrl(finalPrompt, width, height)
  );
  return {
    images: urls,
    type: 'url',
    provider: 'Pollinations FLUX (URL, mungkin perlu VPN)',
    styleUsed: selectedMood,
  };
}

module.exports = { generateImage, getPoolStatus, buildSmartPrompt, getDimensions, normalizeMoodForPurpose };
