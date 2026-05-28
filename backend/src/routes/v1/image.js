/**
 * IMAGE ROUTES — /api/v1/image
 * ─────────────────────────────────────────────────────────
 * Image generation via Multi-Provider Orchestrator
 * Provider Priority: NVIDIA FLUX → X5Lab → Pollinations
 *
 * Sistem Smart Prompt:
 *   - Default: orchestrator membangun prompt berkualitas otomatis
 *   - enhancePrompt=true: Gemini AI digunakan untuk memperkaya prompt SEBELUM
 *     dikirim ke orchestrator, menghasilkan prompt paling detail
 */

const { generateImage, normalizeMoodForPurpose } = require('../../orchestrators/image-orchestrator');
const { generateText } = require('../../orchestrators/text-orchestrator');
const { authMiddleware } = require('../../middleware/auth');
const { rateLimitMiddleware } = require('../../middleware/rate-limit');
const { successResponse } = require('../../utils/response');
const Joi = require('joi');

// ── Validasi Schema ───────────────────────────────────────

const generateSchema = Joi.object({
  prompt: Joi.string().min(3).max(2000).required(),
  negativePrompt: Joi.string().allow('').max(1000).default(''),  // allow('') penting!
  aspectRatio: Joi.string().valid('1:1', '16:9', '9:16', '4:3', '3:4', '21:9').default('1:1'),
  mood: Joi.string()
    .valid(
      // Styles utama UMKM
      'Minimalis', 'Playful/Ceria', 'Elegan/Mewah', 'Photography',
      'Flat Design', '3D Render',
      // Styles baru khusus UMKM Indonesia
      'Warm & Cozy', 'Bold Promo', 'Clean Studio', 'Pastel Aesthetic', 'Ramadan / Islami',
      // Styles niche
      'Futuristic', 'Vintage', 'Watercolor', 'Neon Glow'
    )
    .default('Minimalis'),
  samples: Joi.number().integer().min(1).max(4).default(1),
  // Konteks bisnis — mempengaruhi Smart Prompt Builder
  businessName: Joi.string().allow('').max(100).default(''),
  businessType: Joi.string().allow('').max(100).default(''),
  purpose: Joi.string().allow('').max(200).default(''),
  // Logo maker mode
  isLogoRequest: Joi.boolean().default(false),
  // Enhance prompt via Gemini AI sebelum dikirim ke image provider
  enhancePrompt: Joi.boolean().default(false),
});

// ── Gemini Prompt Enhancement ─────────────────────────────

/**
 * Gunakan Gemini untuk memperkaya prompt user menjadi deskripsi visual
 * berkualitas tinggi sebelum dikirim ke image AI provider.
 */
async function enhancePromptWithGemini({ prompt, businessName, businessType, mood, purpose, isLogoRequest }) {
  const logoInstr = isLogoRequest
    ? `This is a LOGO design request. Create a logo concept: symbolic, memorable, scalable, works in small sizes. NO text or letters in the image.`
    : '';

  const systemInstruction = `You are a world-class AI Art Director and Prompt Engineer specializing in generating images for Indonesian UMKM (small businesses).

Your job: Transform the user's simple description into a rich, detailed, professional image generation prompt in English.

Context:
- Business: ${businessName || 'Indonesian UMKM'} (${businessType || 'general business'})
- Visual Mood: ${mood}
- Purpose: ${purpose || 'social media content / marketing material'}
${logoInstr}

STRICT RULES:
1. Output ONLY the final image prompt — no explanation, no quotes, no preamble
2. Write in English
3. Be highly specific about: subject, composition, lighting, colors, textures, atmosphere
4. Include quality modifiers: masterpiece, best quality, ultra-detailed, 8k, sharp focus, professional
5. NEVER include instructions to add text, words, letters, or watermarks in the image
6. Maximum 400 words
7. Make it visually stunning and commercially appealing`;

  const userMessage = `Create an image generation prompt for: "${prompt}"`;

  const enhanced = await generateText(systemInstruction, userMessage, {
    maxTokens: 400,
    temperature: 0.75,
  });

  return enhanced.trim();
}

// ── Route Handler ─────────────────────────────────────────

async function imageRoutes(fastify) {
  fastify.addHook('preHandler', authMiddleware);
  fastify.addHook('preHandler', rateLimitMiddleware);

  /**
   * POST /api/v1/image/generate
   *
   * Body:
   *   prompt          - Deskripsi gambar yang diinginkan
   *   negativePrompt  - Elemen yang tidak diinginkan
   *   aspectRatio     - Rasio: '1:1' | '16:9' | '9:16' | '4:3' | '3:4' | '21:9'
   *   mood            - Gaya visual (lihat valid values di schema)
   *   samples         - Jumlah gambar (1-4)
   *   businessName    - Nama bisnis (untuk konteks)
   *   businessType    - Jenis bisnis (untuk konteks)
   *   purpose         - Tujuan gambar (social_media, product, logo, dll)
   *   isLogoRequest   - Mode logo maker
   *   enhancePrompt   - Gunakan Gemini untuk memperkaya prompt
   *
   * Response:
   *   images[]        - Array string: base64 data atau URL gambar
   *   imageType       - 'base64' | 'url'
   *   provider        - Provider yang digunakan
   *   promptUsed      - Prompt final yang dikirim ke AI
   */
  fastify.post('/generate', async (request, reply) => {
    const { error, value } = generateSchema.validate(request.body);
    if (error) {
      return reply.code(400).send({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: error.details[0].message },
      });
    }

    let {
      prompt, negativePrompt, aspectRatio, mood, samples,
      enhancePrompt, purpose, businessName, businessType, isLogoRequest,
    } = value;

    const startTime = Date.now();
    let promptSource = 'user_direct';
    const moodSelection = normalizeMoodForPurpose(purpose, mood);
    mood = moodSelection.mood;

    try {
      // ── Step 1: Opsional — Perkaya prompt via Gemini AI ──
      if (enhancePrompt) {
        try {
          fastify.log.info({ uid: request.user.uid, prompt }, 'Enhancing prompt via Gemini...');
          const geminiEnhanced = await enhancePromptWithGemini({
            prompt, businessName, businessType, mood, purpose, isLogoRequest,
          });

          if (geminiEnhanced && geminiEnhanced.length > 10) {
            prompt = geminiEnhanced;
            promptSource = 'gemini_enhanced';
            fastify.log.info({ uid: request.user.uid, enhancedLength: prompt.length }, 'Prompt enhanced');
          } else {
            fastify.log.warn('Gemini returned empty/short result, using original prompt');
          }
        } catch (geminiErr) {
          fastify.log.warn({ err: geminiErr.message }, 'Prompt enhancement failed — using original');
          // Lanjut dengan prompt original — tidak fatal
        }
      }

      // Jika logo request dan belum di-enhance, tambahkan logo context ke prompt
      if (isLogoRequest && promptSource !== 'gemini_enhanced') {
        prompt = `${prompt}, logo design concept, brand identity symbol, iconic and memorable`;
      }

      // ── Step 2: Generate gambar via orchestrator ──────────
      // Orchestrator akan membangun "Smart Prompt" secara otomatis
      // kecuali prompt sudah di-enhance Gemini (skipSmartPrompt=true agar tidak double-wrap)
      const result = await generateImage({
        prompt,
        negativePrompt,
        aspectRatio,
        mood,
        samples,
        purpose,
        businessName,
        businessType,
        skipSmartPrompt: promptSource === 'gemini_enhanced', // Gemini prompt sudah cukup detail
      });

      const duration = Date.now() - startTime;

      fastify.log.info({
        uid: request.user.uid,
        provider: result.provider,
        type: result.type,
        duration_ms: duration,
        promptSource,
      }, 'Image generated successfully');

      return reply.send(
        successResponse(
          {
            images: result.images,        // array of base64 OR url
            imageType: result.type,       // 'base64' | 'url' — PENTING untuk Flutter client
            count: result.images.length,
            provider: result.provider,
            styleUsed: result.styleUsed || mood,
            promptSource,                 // Untuk debugging di client
            promptUsed: prompt,           // Prompt yang benar-benar dikirim ke AI
          },
          { duration_ms: duration, uid: request.user.uid }
        )
      );
    } catch (err) {
      const duration = Date.now() - startTime;
      fastify.log.error({ err: err.message, uid: request.user.uid, duration_ms: duration }, 'Image generate error');

      return reply.code(503).send({
        success: false,
        error: {
          code: 'IMAGE_GENERATION_FAILED',
          message: err.message || 'Gagal generate gambar. Semua provider tidak tersedia, coba lagi nanti.',
        },
      });
    }
  });
}

module.exports = imageRoutes;
