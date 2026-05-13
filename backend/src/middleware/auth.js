/**
 * AUTH MIDDLEWARE — Firebase JWT Verification
 * ─────────────────────────────────────────────────────────
 * Verifikasi token Firebase ID yang dikirim Flutter via header:
 * Authorization: Bearer <firebase_id_token>
 */

const admin = require('../config/firebase-admin');

async function authMiddleware(request, reply) {
  const authHeader = request.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return reply.code(401).send({
      success: false,
      error: {
        code: 'UNAUTHORIZED',
        message: 'Token autentikasi tidak ditemukan. Silakan login kembali.',
      },
    });
  }

  const token = authHeader.slice(7); // hapus "Bearer "

  try {
    const decoded = await admin.auth().verifyIdToken(token, true); // checkRevoked = true
    request.user = {
      uid: decoded.uid,
      email: decoded.email || null,
      plan: decoded.plan || 'free', // custom claim dari Firebase
    };
  } catch (err) {
    const expired = err.code === 'auth/id-token-expired';
    return reply.code(401).send({
      success: false,
      error: {
        code: expired ? 'TOKEN_EXPIRED' : 'INVALID_TOKEN',
        message: expired
          ? 'Sesi kamu sudah berakhir. Silakan login kembali.'
          : 'Token tidak valid. Silakan login kembali.',
      },
    });
  }
}

/**
 * Admin-only middleware — cek custom claim 'admin: true' di Firebase token
 */
async function adminMiddleware(request, reply) {
  await authMiddleware(request, reply);
  if (reply.sent) return; // auth sudah gagal

  // Verifikasi ulang dengan full decode untuk cek admin claim
  const token = request.headers.authorization.slice(7);
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    if (!decoded.admin) {
      return reply.code(403).send({
        success: false,
        error: {
          code: 'FORBIDDEN',
          message: 'Akses ditolak. Hanya admin yang dapat mengakses endpoint ini.',
        },
      });
    }
    request.user.isAdmin = true;
  } catch {
    return reply.code(403).send({ success: false, error: { code: 'FORBIDDEN', message: 'Forbidden' } });
  }
}

module.exports = { authMiddleware, adminMiddleware };
