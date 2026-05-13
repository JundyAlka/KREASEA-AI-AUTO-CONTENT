/**
 * RATE LIMIT MIDDLEWARE — Per-user quota berdasarkan plan
 * ─────────────────────────────────────────────────────────
 * Cek sisa quota user dari Firestore.
 * Quota di-reset setiap hari (UTC midnight).
 */

const admin = require('../config/firebase-admin');

// Quota per plan per hari
const DAILY_QUOTA = {
  free: parseInt(process.env.MAX_REQUESTS_PER_HOUR_FREE || '20') * 24,
  pro: parseInt(process.env.MAX_REQUESTS_PER_HOUR_PRO || '100') * 24,
  premium: parseInt(process.env.MAX_REQUESTS_PER_HOUR_PREMIUM || '500') * 24,
};

function getTodayKey() {
  return new Date().toISOString().slice(0, 10); // 'YYYY-MM-DD'
}

async function rateLimitMiddleware(request, reply) {
  // Harus dijalankan setelah authMiddleware
  if (!request.user) return;

  const { uid, plan } = request.user;
  const today = getTodayKey();
  const docRef = admin.firestore().doc(`user_quotas/${uid}`);

  try {
    const snap = await docRef.get();
    const data = snap.exists ? snap.data() : {};

    const usedToday = data.date === today ? (data.used || 0) : 0;
    const limit = DAILY_QUOTA[plan] || DAILY_QUOTA.free;

    if (usedToday >= limit) {
      return reply.code(429).send({
        success: false,
        error: {
          code: 'QUOTA_EXCEEDED',
          message: `Kuota harian kamu sudah habis (${usedToday}/${limit} request). Kuota direset setiap tengah malam.`,
          quota: { used: usedToday, limit, plan },
        },
      });
    }

    // Increment quota (background — tidak block response)
    docRef.set(
      { uid, date: today, used: usedToday + 1, plan, updatedAt: new Date().toISOString() },
      { merge: true }
    ).catch((err) => console.error('[RateLimit] Failed to update quota:', err));

    // Attach quota info ke request untuk logging
    request.quotaInfo = { used: usedToday + 1, limit, plan };
  } catch (err) {
    // Jika Firestore error, izinkan request tetapi log error
    console.error('[RateLimit] Firestore error, allowing request:', err.message);
  }
}

module.exports = { rateLimitMiddleware };
