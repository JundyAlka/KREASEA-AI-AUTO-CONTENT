/**
 * IMAGE ROUTES — /api/v1/image
 * ─────────────────────────────────────────────────────────
 * Image generation (AI Image, Logo Maker) via Stability AI Orchestrator
 */

const { generateImage } = require('../../orchestrators/image-orchestrator');
const { generateText } = require('../../orchestrators/text-orchestrator');
const { authMiddleware } = require('../../middleware/auth');
const { rateLimitMiddleware } = require('../../middleware/rate-limit');
const { successResponse } = require('../../utils/response');
const Joi = require('joi');

const generateSchema = Joi.object({
  prompt: Joi.string().max(2000).required(),
  negativePrompt: Joi.string().max(1000).default(''),
  aspectRatio: Joi.string().valid('1:1', '16:9', '9:16', '4:3', '3:4').default('1:1'),
  mood: Joi.string().default('Minimalis'),
  samples: Joi.number().integer().min(1).max(4).default(1),
  // Logo Maker extras
  isLogoRequest: Joi.boolean().default(false),
  businessName: Joi.string().max(100).optional(),
  businessType: Joi.string().max(100).optional(),
  // Enhance prompt via Gemini before sending to Stability
  enhancePrompt: Joi.boolean().default(false),
  purpose: Joi.string().max(200).optional(),
});

async function imageRoutes(fastify) {
  fastify.addHook('preHandler', authMiddleware);
  fastify.addHook('preHandler', rateLimitMiddleware);

  // ── POST /api/v1/image/generate ───────────────────────────
  fastify.post('/generate', async (request, reply) => {
    const { error, value } = generateSchema.validate(request.body);
    if (error) {
      return reply.code(400).send({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: error.details[0].message },
      });
    }

    let {
      prompt, negativePrompt, aspectRatio, mood,
      samples, enhancePrompt, purpose, businessName, businessType,
    } = value;

    const startTime = Date.now();

    try {
      // Optional: Enhance prompt via Gemini sebelum kirim ke Stability AI
      if (enhancePrompt) {
        const systemInstr = `You are an elite AI Art Director and Prompt Engineer for Stable Diffusion XL.
Transform the user request into a detailed, professional image prompt.
Business: ${businessName || 'Generic UMKM'} — ${businessType || 'general'}
Mood: ${mood}. Purpose: ${purpose || 'social media content'}.
Rules: VISUALS ONLY (no text in image), include quality boosters (masterpiece, best quality, 8k, ultra-detailed, cinematic lighting).
Return ONLY the final English prompt string.`;

        try {
          const enhanced = await generateText(systemInstr, prompt, { maxTokens: 300, temperature: 0.7 });
          prompt = enhanced;
          fastify.log.info({ uid: request.user.uid }, 'Prompt enhanced via Gemini');
        } catch {
          // Jika enhance gagal, lanjutkan dengan prompt original
          fastify.log.warn('Prompt enhancement failed, using original');
        }
      }

      const images = await generateImage({ prompt, negativePrompt, aspectRatio, mood, samples });
      const duration = Date.now() - startTime;

      return reply.send(
        successResponse(
          {
            images,           // array of base64 strings
            count: images.length,
            prompt,           // final prompt yang dipakai (mungkin sudah enhanced)
          },
          { duration_ms: duration, uid: request.user.uid }
        )
      );
    } catch (err) {
      fastify.log.error({ err, uid: request.user.uid }, 'Image generate error');
      return reply.code(503).send({
        success: false,
        error: {
          code: 'IMAGE_GENERATION_FAILED',
          message: err.message || 'Gagal generate gambar. Coba lagi dalam beberapa menit.',
        },
      });
    }
  });
}

module.exports = imageRoutes;
