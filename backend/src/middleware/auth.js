/**
 * AUTH MIDDLEWARE — Firebase JWT Verification + Dev Secret Bypass
 * ─────────────────────────────────────────────────────────
 * Mode 1 (Production): Verifikasi Firebase ID token via Admin SDK
 * Mode 2 (Development): Terima SEMUA request — DevSecret ATAU Bearer token
 *
 * PENTING (dev): Firebase Admin SDK tidak dikonfigurasi lengkap di dev.
 * Daripada reject, kita izinkan semua request dengan log warning.
 */

const admin = require('../config/firebase-admin');

const DEV_SECRET = process.env.DEV_API_SECRET || '';
const IS_DEV = process.env.NODE_ENV !== 'production';

async function authMiddleware(request, reply) {
  const authHeader = request.headers.authorization;

  // ── Dev Mode: terima SEMUA request tanpa ketat ───────────
  // Di development, kita tidak perlu strict auth — hindari user
  // terganggu dengan masalah konfigurasi Firebase Admin SDK.
  if (IS_DEV) {
    // ── Case 1: DevSecret header ────────────────────────────
    if (DEV_SECRET && authHeader && authHeader.startsWith('DevSecret ')) {
      const provided = authHeader.slice(10).trim();
      if (provided === DEV_SECRET) {
        request.user = {
          uid: 'dev-user-local',
          email: 'dev@kreasea.local',
          plan: 'premium',
          isDev: true,
        };
        console.log('[Auth] ✅ Dev DevSecret bypass');
        return;
      }
    }

    // ── Case 2: Bearer token (Firebase) ────────────────────
    // Di dev, coba verify dulu. Jika gagal karena APAPUN, allow saja.
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.slice(7);
      try {
        const decoded = await admin.auth().verifyIdToken(token, false);
        request.user = {
          uid: decoded.uid,
          email: decoded.email || null,
          plan: decoded.plan || 'free',
        };
        console.log(`[Auth] ✅ Firebase token verified: ${decoded.uid}`);
        return;
      } catch (err) {
        // Verify gagal di dev → allow dengan mock user (log warning saja)
        console.warn(`[Auth] ⚠️ Dev mode — Firebase verify gagal (${err.code || err.message}), allow dengan dev user`);
        request.user = {
          uid: `dev-bearer-${Date.now()}`,
          email: null,
          plan: 'free',
          isDev: true,
          isUnverified: true,
        };
        return;
      }
    }

    // ── Case 3: Tidak ada header sama sekali ───────────────
    // Di dev, masih allow dengan anonymous dev user
    if (!authHeader) {
      console.warn('[Auth] ⚠️ Dev mode — No auth header, using anonymous dev user');
      request.user = {
        uid: 'dev-anonymous',
        email: null,
        plan: 'free',
        isDev: true,
      };
      return;
    }

    // ── Case 4: Header ada tapi format tidak dikenali ──────
    // Still allow di dev
    console.warn(`[Auth] ⚠️ Dev mode — Unknown auth header format, allowing`);
    request.user = {
      uid: 'dev-unknown-format',
      email: null,
      plan: 'free',
      isDev: true,
    };
    return;
  }

  // ═══════════════════════════════════════════════════════
  // PRODUCTION MODE — strict auth
  // ═══════════════════════════════════════════════════════

  if (!authHeader) {
    return reply.code(401).send({
      success: false,
      error: {
        code: 'UNAUTHORIZED',
        message: 'Token autentikasi tidak ditemukan.',
      },
    });
  }

  if (!authHeader.startsWith('Bearer ')) {
    return reply.code(401).send({
      success: false,
      error: {
        code: 'UNAUTHORIZED',
        message: 'Format token tidak valid. Gunakan "Bearer <token>".',
      },
    });
  }

  const token = authHeader.slice(7);

  try {
    const decoded = await admin.auth().verifyIdToken(token, true);
    request.user = {
      uid: decoded.uid,
      email: decoded.email || null,
      plan: decoded.plan || 'free',
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
 * Admin-only middleware
 */
async function adminMiddleware(request, reply) {
  await authMiddleware(request, reply);
  if (reply.sent) return;

  if (request.user?.isDev) return; // dev bypass is always admin

  if (IS_DEV) return; // di dev, semua admin

  const token = request.headers.authorization?.slice(7);
  if (!token) return;

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
