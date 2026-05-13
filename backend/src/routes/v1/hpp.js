/**
 * HPP ROUTES — /api/v1/hpp
 * ─────────────────────────────────────────────────────────
 * Kalkulator Harga Pokok Produksi (pure logic, tidak butuh AI)
 * + AI Advice via Text Orchestrator
 */

const { generateText } = require('../../orchestrators/text-orchestrator');
const { authMiddleware } = require('../../middleware/auth');
const { successResponse } = require('../../utils/response');
const Joi = require('joi');

const calculateSchema = Joi.object({
  bahan_baku: Joi.array().items(
    Joi.object({
      nama: Joi.string().required(),
      qty: Joi.number().positive().required(),
      satuan: Joi.string().required(),
      harga_satuan: Joi.number().min(0).required(),
    })
  ).min(1).required(),
  tenaga_kerja: Joi.array().items(
    Joi.object({
      deskripsi: Joi.string().required(),
      jam: Joi.number().min(0).required(),
      upah_per_jam: Joi.number().min(0).required(),
    })
  ).default([]),
  overhead: Joi.array().items(
    Joi.object({
      nama: Joi.string().required(),
      biaya: Joi.number().min(0).required(),
    })
  ).default([]),
  jumlah_produksi: Joi.number().positive().required(),
});

const adviceSchema = Joi.object({
  hpp_per_unit: Joi.number().positive().required(),
  harga_jual: Joi.number().positive().required(),
  kategori_produk: Joi.string().required(),
  lokasi: Joi.string().required(),
});

async function hppRoutes(fastify) {
  fastify.addHook('preHandler', authMiddleware);

  // ── POST /api/v1/hpp/calculate ────────────────────────────
  fastify.post('/calculate', async (request, reply) => {
    const { error, value } = calculateSchema.validate(request.body);
    if (error) {
      return reply.code(400).send({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: error.details[0].message },
      });
    }

    const { bahan_baku, tenaga_kerja, overhead, jumlah_produksi } = value;

    // ── Pure math calculation ──────────────────────────────
    const total_bb = bahan_baku.reduce((sum, item) => sum + item.qty * item.harga_satuan, 0);
    const total_tk = tenaga_kerja.reduce((sum, item) => sum + item.jam * item.upah_per_jam, 0);
    const total_oh = overhead.reduce((sum, item) => sum + item.biaya, 0);
    const hpp_total = total_bb + total_tk + total_oh;
    const hpp_per_unit = hpp_total / jumlah_produksi;

    return reply.send(
      successResponse({
        hpp_total_batch: Math.round(hpp_total),
        hpp_per_unit: Math.round(hpp_per_unit),
        breakdown: {
          bahan_baku: Math.round(total_bb),
          tenaga_kerja: Math.round(total_tk),
          overhead: Math.round(total_oh),
        },
        rekomendasi_harga: {
          margin_10: Math.round(hpp_per_unit * 1.1),
          margin_20: Math.round(hpp_per_unit * 1.2),
          margin_30: Math.round(hpp_per_unit * 1.3),
          margin_40: Math.round(hpp_per_unit * 1.4),
        },
      })
    );
  });

  // ── POST /api/v1/hpp/ai-advice ────────────────────────────
  fastify.post('/ai-advice', async (request, reply) => {
    const { error, value } = adviceSchema.validate(request.body);
    if (error) {
      return reply.code(400).send({
        success: false,
        error: { code: 'VALIDATION_ERROR', message: error.details[0].message },
      });
    }

    const { hpp_per_unit, harga_jual, kategori_produk, lokasi } = value;
    const margin = (((harga_jual - hpp_per_unit) / hpp_per_unit) * 100).toFixed(1);

    const systemPrompt = `Kamu adalah konsultan bisnis UMKM Indonesia yang ahli dalam strategi penetapan harga. Gunakan bahasa Indonesia yang ramah dan mudah dipahami.`;
    const userPrompt = `HPP produk saya adalah Rp ${hpp_per_unit.toLocaleString('id-ID')}/unit.
Saya berencana menjualnya seharga Rp ${harga_jual.toLocaleString('id-ID')}/unit (margin ${margin}%).
Kategori: ${kategori_produk}. Lokasi usaha: ${lokasi}.

Berikan:
1. Analisis apakah harga tersebut kompetitif (2-3 kalimat)
2. Risiko jika harga terlalu rendah atau terlalu tinggi
3. Saran harga psikologis yang lebih menarik (misal Rp 14.900 vs Rp 15.000)
4. Tips meningkatkan perceived value agar bisa jual lebih mahal
Format: poin-poin singkat, maksimal 150 kata total.`;

    try {
      const advice = await generateText(systemPrompt, userPrompt, { maxTokens: 512 });
      return reply.send(successResponse({ advice, margin_pct: parseFloat(margin) }));
    } catch (err) {
      return reply.code(503).send({
        success: false,
        error: { code: 'AI_UNAVAILABLE', message: 'AI advice tidak tersedia saat ini. Coba lagi nanti.' },
      });
    }
  });
}

module.exports = hppRoutes;
