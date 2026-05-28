import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Env — Single source of truth untuk semua konfigurasi KreaSea
///
/// Strategy: baca dari .env file → fallback ke string kosong jika tidak ada.
/// Semua API key WAJIB diisi di file .env (tidak boleh hardcode di sini).
///
/// Untuk mendapatkan Gemini API key gratis:
///   https://aistudio.google.com/app/apikey
class Env {
  // ── Backend ──────────────────────────────────────────────────
  static String get backendUrl => _get('BACKEND_URL', 'http://localhost:3001');
  static String get devApiSecret => _get('DEV_API_SECRET', '');

  // ── Gemini API Keys ──────────────────────────────────────────
  // ⚠️ SECURITY: Isi key di file .env — JANGAN hardcode di sini!
  static String get geminiKey1 => _get('GEMINI_KEY_1', '');
  static String get geminiKey2 => _get('GEMINI_KEY_2', '');
  static String get geminiKey3 => _get('GEMINI_KEY_3', '');
  static String get geminiKey4 => _get('GEMINI_KEY_4', '');
  static String get geminiKey5 => _get('GEMINI_KEY_5', '');
  static String get geminiKey6 => _get('GEMINI_KEY_6', '');

  /// Semua Gemini key yang tidak kosong, siap dipakai
  static List<String> get geminiKeys => [
        geminiKey1,
        geminiKey2,
        geminiKey3,
        geminiKey4,
        geminiKey5,
        geminiKey6,
      ].where((k) => k.isNotEmpty).toList();

  // ── OpenAI Fallback ──────────────────────────────────────────
  static String get openAiKey => _get('OPENAI_API_KEY', '');

  // ── Stability AI ─────────────────────────────────────────────
  static String get stabilityApiKey => _get('STABILITY_API_KEY', '');

  // ── Pollinations AI (Image Generation) ──────────────────────
  /// Token untuk authenticated Pollinations requests (bypass payment gate)
  /// Daftar gratis di https://auth.pollinations.ai
  static String get pollinationsApiKey => _get('POLLINATIONS_API_KEY', '');

  // ── NVIDIA NIM ───────────────────────────────────────────────
  /// Untuk self-hosted NIM atau NVIDIA cloud endpoints
  static String get nvidiaApiKey => _get('NVIDIA_API_KEY', '');

  // ── Firebase ─────────────────────────────────────────────────
  static String get firebaseApiKey => _get('FIREBASE_API_KEY', '');
  static String get firebaseProjectId => _get('FIREBASE_PROJECT_ID', '');

  // ── Helper ───────────────────────────────────────────────────
  static String _get(String key, String fallback) {
    try {
      final v = dotenv.env[key];
      return (v == null || v.trim().isEmpty) ? fallback : v.trim();
    } catch (_) {
      return fallback;
    }
  }

  @Deprecated('Gunakan geminiKeys list.')
  static String get geminiApiKey => geminiKey1;

  @Deprecated('Gunakan stabilityApiKey.')
  static String get aiImageApiKey => stabilityApiKey;
}
