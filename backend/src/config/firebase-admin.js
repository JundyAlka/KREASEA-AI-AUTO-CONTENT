/**
 * FIREBASE ADMIN SDK — Singleton Initializer
 */

const admin = require('firebase-admin');

if (!admin.apps.length) {
  let credential;

  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      credential = admin.credential.cert(serviceAccount);
    } catch {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON tidak valid JSON');
    }
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    credential = admin.credential.applicationDefault();
  } else {
    throw new Error(
      'Firebase credential tidak ditemukan. Set FIREBASE_SERVICE_ACCOUNT_JSON atau GOOGLE_APPLICATION_CREDENTIALS'
    );
  }

  admin.initializeApp({
    credential,
    projectId: process.env.FIREBASE_PROJECT_ID,
  });

  console.log('[Firebase] Admin SDK initialized — project:', process.env.FIREBASE_PROJECT_ID);
}

module.exports = admin;
