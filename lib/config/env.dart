import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Env — Single source of truth untuk semua konfigurasi
///
/// Strategy: baca .env → fallback hardcoded jika kosong (Flutter Web).
///
/// STATUS KEY (2026-05-15):
///   KEY_1 = AIzaSyA4sX... → ✅ VALID  (gemini-2.0-flash bekerja)
///   KEY_2 = AIzaSyAAXo... → ❌ INVALID (revoked)
///   KEY_3 = AIzaSyA3n8... → ❌ INVALID (revoked)
///   KEY_4 = AIzaSyAvP1... → ❌ INVALID (revoked)
///   KEY_5 = AIzaSyA73q... → ❌ INVALID (revoked)
///
/// Untuk menambah key baru: https://aistudio.google.com/app/apikey
class Env {
  // ── Backend ─────────────────────────────────────────────────
  static String get backendUrl => _get('BACKEND_URL', 'http://localhost:3001');

  // ── Gemini API Keys ──────────────────────────────────────────
  // Key 1 = satu-satunya yang valid saat ini (AIzaSyA4sX...)
  // ⚠️ SECURITY: Semua API key HARUS diisi via file .env (lihat .env.example)
  // Jangan pernah hardcode key di sini!
  static String get geminiKey1 => _get('GEMINI_KEY_1', '');
  static String get geminiKey2 => _get('GEMINI_KEY_2', '');
  static String get geminiKey3 => _get('GEMINI_KEY_3', '');
  static String get geminiKey4 => _get('GEMINI_KEY_4', '');
  static String get geminiKey5 => _get('GEMINI_KEY_5', '');
  // Key 6: hanya dari .env jika user sudah isi key baru
  static String get geminiKey6 => _get('GEMINI_KEY_6', '');

  /// Semua Gemini key yang tidak kosong
  static List<String> get geminiKeys => [
        geminiKey1,
        geminiKey2,
        geminiKey3,
        geminiKey4,
        geminiKey5,
        geminiKey6,
      ].where((k) => k.isNotEmpty).toList();

  // ── OpenAI Fallback ──────────────────────────────────────────
  // ⚠️ SECURITY: Isi OPENAI_API_KEY di file .env (jangan hardcode!)
  static String get openAiKey => _get('OPENAI_API_KEY', '');

  // ── Stability AI ─────────────────────────────────────────────
  // ⚠️ SECURITY: Isi STABILITY_API_KEY di file .env (jangan hardcode!)
  static String get stabilityApiKey => _get('STABILITY_API_KEY', '');

  // ── Firebase ─────────────────────────────────────────────────
  // ⚠️ SECURITY: Isi FIREBASE_API_KEY di file .env (jangan hardcode!)
  static String get firebaseApiKey =>
      _get('FIREBASE_API_KEY', '');

  // ── Helper ───────────────────────────────────────────────────
  static String _get(String key, String fallback) {
    final v = dotenv.env[key];
    return (v == null || v.isEmpty) ? fallback : v;
  }

  @Deprecated('Gunakan geminiKeys list.')
  static String get geminiApiKey => geminiKey1;

  @Deprecated('Gunakan stabilityApiKey.')
  static String get aiImageApiKey => stabilityApiKey;
}
