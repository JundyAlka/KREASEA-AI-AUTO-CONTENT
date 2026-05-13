import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Env — Single source of truth untuk semua konfigurasi
class Env {
  // ── Backend URL ─────────────────────────────────────────
  static String get backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:3001';

  // ── Gemini API Keys (5 keys untuk multi-key rotation) ───
  static String get geminiKey1 =>
      dotenv.env['GEMINI_KEY_1'] ?? '';
  static String get geminiKey2 =>
      dotenv.env['GEMINI_KEY_2'] ?? '';
  static String get geminiKey3 =>
      dotenv.env['GEMINI_KEY_3'] ?? '';
  static String get geminiKey4 =>
      dotenv.env['GEMINI_KEY_4'] ?? '';
  static String get geminiKey5 =>
      dotenv.env['GEMINI_KEY_5'] ?? '';

  /// Semua Gemini key yang aktif (tidak kosong)
  static List<String> get geminiKeys => [
    geminiKey1, geminiKey2, geminiKey3, geminiKey4, geminiKey5,
  ].where((k) => k.isNotEmpty).toList();

  // ── OpenAI Fallback ──────────────────────────────────────
  static String get openAiKey =>
      dotenv.env['OPENAI_API_KEY'] ?? '';

  // ── Stability AI ─────────────────────────────────────────
  static String get stabilityApiKey =>
      dotenv.env['STABILITY_API_KEY'] ?? '';

  // ── Firebase ─────────────────────────────────────────────
  static String get firebaseApiKey =>
      dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyD9bchOiEyGpmb8wn0ov5jNOrRG25zHeJE';

  // ── Legacy (deprecated tapi aman) ───────────────────────
  @Deprecated('Gunakan geminiKeys list. Key 1-5 tersedia.')
  static String get geminiApiKey => geminiKey1;

  @Deprecated('Gunakan stabilityApiKey.')
  static String get aiImageApiKey => stabilityApiKey;
}
