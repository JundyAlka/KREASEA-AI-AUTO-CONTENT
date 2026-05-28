/**
 * FIREBASE ADMIN SDK — Singleton Initializer (Dev-Safe)
 * ─────────────────────────────────────────────────────────
 * Production: butuh FIREBASE_SERVICE_ACCOUNT_JSON lengkap
 * Development: bisa jalan tanpa Firebase (auth via DevSecret)
 */

const admin = require('firebase-admin');

// Cek apakah Firebase sudah diinit
if (!admin.apps.length) {
  const IS_DEV = process.env.NODE_ENV === 'development';
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

  let initialized = false;

  // 1. Coba pakai service account JSON dari env
  if (serviceAccountJson && serviceAccountJson.trim() !== '') {
    try {
      const parsed = JSON.parse(serviceAccountJson);

      // Validasi field wajib untuk service account
      const isComplete = parsed.private_key && parsed.client_email;

      if (isComplete) {
        admin.initializeApp({
          credential: admin.credential.cert(parsed),
          projectId: process.env.FIREBASE_PROJECT_ID,
        });
        console.log('[Firebase] ✅ Admin SDK initialized (service account)');
        initialized = true;
      } else {
        console.warn('[Firebase] ⚠️ FIREBASE_SERVICE_ACCOUNT_JSON tidak lengkap (missing private_key/client_email)');
      }
    } catch (e) {
      console.warn(`[Firebase] ⚠️ FIREBASE_SERVICE_ACCOUNT_JSON bukan JSON valid: ${e.message}`);
    }
  }

  // 2. Coba Application Default Credentials
  if (!initialized) {
    try {
      if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        admin.initializeApp({
          credential: admin.credential.applicationDefault(),
          projectId: process.env.FIREBASE_PROJECT_ID,
        });
        console.log('[Firebase] ✅ Admin SDK initialized (application default credentials)');
        initialized = true;
      }
    } catch (e) {
      console.warn(`[Firebase] ⚠️ Application default credentials gagal: ${e.message}`);
    }
  }

  // 3. Dev mode: init tanpa credential (auth bypass via DevSecret akan dipakai)
  if (!initialized) {
    if (IS_DEV) {
      console.warn('[Firebase] 🔧 Dev mode: Firebase Admin tidak terkonfigurasi.');
      console.warn('[Firebase] 🔧 Gunakan "Authorization: DevSecret <DEV_API_SECRET>" untuk bypass auth.');

      // Init dengan mock credential supaya admin.apps.length > 0
      // Token verification akan gagal tapi auth middleware punya dev bypass
      try {
        admin.initializeApp({
          projectId: process.env.FIREBASE_PROJECT_ID || 'kreasea-dev',
        });
      } catch (e) {
        // Sudah init? Abaikan
      }
    } else {
      throw new Error(
        '[Firebase] FATAL: Firebase Admin tidak terkonfigurasi untuk production!\n' +
        'Set FIREBASE_SERVICE_ACCOUNT_JSON atau GOOGLE_APPLICATION_CREDENTIALS di .env'
      );
    }
  }
}

module.exports = admin;
