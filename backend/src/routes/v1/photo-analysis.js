/**
 * PHOTO ANALYSIS ROUTES — /api/v1/photo-analysis
 * ─────────────────────────────────────────────────────────
 * Analisis kualitas foto produk menggunakan Gemini Vision
 * Upload: multipart form-data (image file)
 */

const { generateJson } = require('../../orchestrators/text-orchestrator');
const { authMiddleware } = require('../../middleware/auth');
const { rateLimitMiddleware } = require('../../middleware/rate-limit');
const { successResponse } = require('../../utils/response');
const sharp = require('sharp');

async function photoAnalysisRoutes(fastify) {
  fastify.addHook('preHandler', authMiddleware);
  fastify.addHook('preHandler', rateLimitMiddleware);

  // ── POST /api/v1/photo-analysis ───────────────────────────
  fastify.post('/', async (request, reply) => {
    const parts = request.parts();
    let imageBuffer = null;
    let kategori = 'Produk umum';
    let platform = 'Instagram Feed';

    // Parse multipart
    for await (const part of parts) {
      if (part.type === 'file' && part.fieldname === 'image') {
        const chunks = [];
        for await (const chunk of part.file) chunks.push(chunk);
        imageBuffer = Buffer.concat(chunks);
      } else if (part.type === 'field') {
        if (part.fieldname === 'kategori') kategori = part.value;
        if (part.fieldname === 'platform') platform = part.value;
      }
    }

    if (!imageBuffer) {
      return reply.code(400).send({
        success: false,
        error: { code: 'NO_IMAGE', message: 'File gambar tidak ditemukan dalam request.' },
      });
    }

    // Resize ke max 1024x1024 untuk hemat token
    const resized = await sharp(imageBuffer)
      .resize(1024, 1024, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 85 })
      .toBuffer();

    const imageBase64 = resized.toString('base64');

    const systemPrompt = `Kamu adalah fotografer produk profesional dengan keahlian e-commerce dan social media marketing Indonesia.`;
    const userPrompt = `Analisis kualitas foto produk ${kategori} berikut untuk platform ${platform}.
Berikan penilaian dalam format JSON:
{
  "skor_keseluruhan": 7,
  "aspek": {
    "pencahayaan": {"skor": 8, "komentar": "...", "saran": "..."},
    "komposisi": {"skor": 6, "komentar": "...", "saran": "..."},
    "background": {"skor": 7, "komentar": "...", "saran": "..."},
    "ketajaman": {"skor": 9, "komentar": "...", "saran": "..."},
    "styling": {"skor": 5, "komentar": "...", "saran": "..."},
    "platform_fit": {"skor": 7, "komentar": "...", "saran": "..."}
  },
  "saran_utama": ["...", "...", "..."],
  "pujian": "...",
  "estimasi_peningkatan": "Dengan perbaikan di atas, foto ini bisa meningkat dari X/10 ke Y/10"
}`;

    try {
      const result = await generateJson(systemPrompt, userPrompt, {
        useVision: true,
        imageBase64,
        maxTokens: 1024,
      });

      return reply.send(successResponse({ analysis: result, kategori, platform }));
    } catch (err) {
      fastify.log.error({ err, uid: request.user.uid }, 'Photo analysis error');
      return reply.code(503).send({
        success: false,
        error: { code: 'ANALYSIS_FAILED', message: 'Analisis foto gagal. Coba lagi dalam beberapa menit.' },
      });
    }
  });
}

module.exports = photoAnalysisRoutes;
