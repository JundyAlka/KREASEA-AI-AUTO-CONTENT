/**
 * ADMIN ROUTES — /api/v1/admin
 * ─────────────────────────────────────────────────────────
 * Monitoring status key orchestrator (tanpa menampilkan nilai key)
 * Hanya accessible oleh user dengan custom claim admin=true di Firebase
 */

const textOrchestrator = require('../../orchestrators/text-orchestrator');
const imageOrchestrator = require('../../orchestrators/image-orchestrator');
const { adminMiddleware } = require('../../middleware/auth');
const { successResponse } = require('../../utils/response');

async function adminRoutes(fastify) {
  fastify.addHook('preHandler', adminMiddleware);

  // ── GET /api/v1/admin/key-status ──────────────────────────
  fastify.get('/key-status', async (request, reply) => {
    return reply.send(
      successResponse({
        text_orchestrator: {
          provider: 'gemini',
          model: process.env.GEMINI_TEXT_MODEL || 'gemini-2.0-flash-exp',
          keys: textOrchestrator.getPoolStatus(),
        },
        image_orchestrator: {
          provider: 'stability_ai',
          model: process.env.STABILITY_IMAGE_MODEL || 'stable-diffusion-xl-1024-v1-0',
          keys: imageOrchestrator.getPoolStatus(),
        },
        fallback: {
          text: process.env.OPENAI_FALLBACK_KEY ? 'openai (configured)' : 'not configured',
          image: process.env.REPLICATE_FALLBACK_KEY ? 'replicate (configured)' : 'not configured',
        },
      })
    );
  });

  // ── POST /api/v1/admin/key-rotate ─────────────────────────
  // Force reset cooldown semua key (misal setelah isi kuota baru)
  fastify.post('/key-rotate', async (request, reply) => {
    // Re-import orchestrators dan reset internal state tidak mudah tanpa refactor
    // Workaround: return pesan bahwa ini perlu restart server atau implementasi Redis-based state
    return reply.send(
      successResponse({
        message: 'Untuk production: gunakan Redis-based key state agar bisa reset tanpa restart. Saat ini, restart server untuk reset semua cooldown.',
        recommendation: 'Upgrade ke Redis state management di Phase 3.',
      })
    );
  });

  // ── GET /api/v1/admin/health-detail ───────────────────────
  fastify.get('/health-detail', async (request, reply) => {
    const textKeys = textOrchestrator.getPoolStatus();
    const imageKeys = imageOrchestrator.getPoolStatus();

    return reply.send(
      successResponse({
        text_keys_active: textKeys.filter((k) => k.status === 'active').length,
        text_keys_total: textKeys.length,
        image_keys_active: imageKeys.filter((k) => k.status === 'active').length,
        image_keys_total: imageKeys.length,
        text_requests_today: textKeys.reduce((sum, k) => sum + k.requestsToday, 0),
        image_requests_today: imageKeys.reduce((sum, k) => sum + k.requestsToday, 0),
        server_uptime_seconds: Math.floor(process.uptime()),
        memory_mb: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      })
    );
  });
}

module.exports = adminRoutes;
