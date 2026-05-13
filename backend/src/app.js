/**
 * APP ENTRY POINT — KreaSea Backend
 * ─────────────────────────────────────────────────────────
 * Fastify server dengan semua plugin, middleware, dan route
 */

require('dotenv').config();

// Inisialisasi Firebase sebelum apapun
require('./config/firebase-admin');

// Inisialisasi Redis cache (non-blocking, fallback ke in-memory jika gagal)
const { initRedis } = require('./cache/redis.client');
initRedis().catch(() => {}); // Redis failure tidak crash server

const fastify = require('fastify')({
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    transport:
      process.env.NODE_ENV !== 'production'
        ? { target: 'pino-pretty', options: { colorize: true, translateTime: 'SYS:standard' } }
        : undefined,
  },
});

// ── Plugins ──────────────────────────────────────────────────
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:8080').split(',');

fastify.register(require('@fastify/helmet'));
fastify.register(require('@fastify/cors'), {
  origin: (origin, cb) => {
    if (!origin || allowedOrigins.some((o) => origin.startsWith(o.trim()))) {
      cb(null, true);
    } else {
      cb(new Error(`CORS: Origin ${origin} tidak diizinkan`), false);
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
});
fastify.register(require('@fastify/multipart'), {
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max untuk foto produk
});

// Global rate limit (DDoS protection) — berbeda dari per-user quota
fastify.register(require('@fastify/rate-limit'), {
  max: 200,
  timeWindow: '1 minute',
  errorResponseBuilder: () => ({
    success: false,
    error: { code: 'TOO_MANY_REQUESTS', message: 'Terlalu banyak request. Coba lagi dalam 1 menit.' },
  }),
});

// ── Health Check ─────────────────────────────────────────────
fastify.get('/api/v1/health', async () => ({
  success: true,
  data: {
    status: 'ok',
    service: 'KreaSea Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    uptime_seconds: Math.floor(process.uptime()),
  },
}));

// ── API Routes v1 ─────────────────────────────────────────────
fastify.register(require('./routes/v1/content'), { prefix: '/api/v1/content' });
fastify.register(require('./routes/v1/image'), { prefix: '/api/v1/image' });
fastify.register(require('./routes/v1/hpp'), { prefix: '/api/v1/hpp' });
fastify.register(require('./routes/v1/photo-analysis'), { prefix: '/api/v1/photo-analysis' });
fastify.register(require('./routes/v1/admin'), { prefix: '/api/v1/admin' });

// ── Global Error Handler ──────────────────────────────────────
fastify.setErrorHandler((error, request, reply) => {
  fastify.log.error({ error, url: request.url, method: request.method });

  if (error.validation) {
    return reply.code(400).send({
      success: false,
      error: { code: 'VALIDATION_ERROR', message: error.message },
    });
  }

  if (error.statusCode === 429) {
    return reply.code(429).send({
      success: false,
      error: { code: 'RATE_LIMITED', message: 'Terlalu banyak request. Coba lagi nanti.' },
    });
  }

  return reply.code(error.statusCode || 500).send({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message:
        process.env.NODE_ENV === 'production'
          ? 'Terjadi kesalahan internal. Tim kami sudah diberitahu.'
          : error.message,
    },
  });
});

// ── Start Server ──────────────────────────────────────────────
const PORT = parseInt(process.env.PORT || '3001');
const HOST = '0.0.0.0';

fastify.listen({ port: PORT, host: HOST }, (err) => {
  if (err) {
    fastify.log.error(err);
    process.exit(1);
  }
  fastify.log.info(`🚀 KreaSea Backend running on http://${HOST}:${PORT}`);
  fastify.log.info(`📊 Health check: http://localhost:${PORT}/api/v1/health`);
});
