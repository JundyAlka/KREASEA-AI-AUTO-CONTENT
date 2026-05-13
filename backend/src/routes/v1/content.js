/**
 * CONTENT ROUTES — /api/v1/content
 * ─────────────────────────────────────────────────────────
 * Semua fitur text generation: Caption, WA Blast, GMaps,
 * HPP Advice, Nama Produk, Testimoni, Balasan DM, Content Calendar
 */

const { generateText, generateJson } = require('../../orchestrators/text-orchestrator');
const { authMiddleware } = require('../../middleware/auth');
const { rateLimitMiddleware } = require('../../middleware/rate-limit');
const { successResponse } = require('../../utils/response');
const { getCache, setCache, makeCacheKey } = require('../../cache/redis.client');
const Joi = require('joi');

// TTL cache per fitur (detik) — 0 = tidak cache
const CACHE_TTL = {
  caption: 300,          // 5 menit
  wa_blast: 300,
  gmaps: 600,            // 10 menit — output GMaps jarang berubah
  nama_produk: 600,
  testimoni: 300,
  balasan_dm: 0,         // DM replies — selalu fresh
  content_calendar: 900, // 15 menit
  hpp_advice: 600,
};

// ── Validation Schemas ───────────────────────────────────────
const generateSchema = Joi.object({
  feature: Joi.string()
    .valid(
      'caption', 'wa_blast', 'gmaps', 'nama_produk',
      'testimoni', 'balasan_dm', 'content_calendar', 'hpp_advice'
    )
    .required(),
  systemPrompt: Joi.string().max(5000).required(),
  userPrompt: Joi.string().max(5000).required(),
  outputFormat: Joi.string().valid('text', 'json').default('text'),
  temperature: Joi.number().min(0).max(1).default(0.8),
  maxTokens: Joi.number().integer().min(100).max(4096).default(2048),
});

async function contentRoutes(fastify) {
  // ── Hook: auth + rate limit untuk semua route content ─────
  fastify.addHook('preHandler', authMiddleware);
  fastify.addHook('preHandler', rateLimitMiddleware);

  // ── POST /api/v1/content/generate ─────────────────────────
  fastify.post('/generate', async (request, reply) => {
    const { error, value } = generateSchema.validate(request.body);
    if (error) {
      return reply.code(400).send({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: error.details[0].message },
      });
    }

    const { feature, systemPrompt, userPrompt, outputFormat, temperature, maxTokens } = value;
    const startTime = Date.now();
    const ttl = CACHE_TTL[feature] || 0;

    // ── Cache lookup (hanya jika TTL > 0) ─────────────────
    const cacheKey = ttl > 0
      ? makeCacheKey(`c:${feature}`, { systemPrompt, userPrompt, outputFormat })
      : null;

    if (cacheKey) {
      const cached = await getCache(cacheKey);
      if (cached) {
        fastify.log.info({ feature, uid: request.user.uid }, 'Cache HIT');
        return reply.send(
          successResponse(cached, { from_cache: true, feature, uid: request.user.uid })
        );
      }
    }

    try {
      let result;
      if (outputFormat === 'json') {
        result = await generateJson(systemPrompt, userPrompt, { temperature, maxTokens });
      } else {
        result = await generateText(systemPrompt, userPrompt, { temperature, maxTokens });
      }

      const payload = { result, outputFormat };

      // Simpan ke cache di background
      if (cacheKey) setCache(cacheKey, payload, ttl).catch(() => {});

      return reply.send(
        successResponse(payload, {
          duration_ms: Date.now() - startTime,
          from_cache: false,
          feature,
          uid: request.user.uid,
        })
      );
    } catch (err) {
      fastify.log.error({ err, uid: request.user.uid, feature }, 'Content generate error');
      return reply.code(503).send({
        success: false,
        error: {
          code: 'AI_UNAVAILABLE',
          message: err.message || 'AI sedang tidak tersedia. Coba lagi dalam beberapa menit.',
        },
      });
    }
  });

  // ── GET /api/v1/content/quota ──────────────────────────────
  fastify.get('/quota', async (request, reply) => {
    return reply.send(
      successResponse({
        plan: request.user.plan,
        ...(request.quotaInfo || {}),
      })
    );
  });
}

module.exports = contentRoutes;
