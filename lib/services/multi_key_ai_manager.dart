import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

// ══════════════════════════════════════════════════════════════════
// MULTI-KEY AI MANAGER — KreaSea (v3 — REST API, no SDK)
// ══════════════════════════════════════════════════════════════════
//
// ROOT CAUSE FIX (2026-05-17):
//  • google_generative_ai SDK gagal di Flutter Web karena CORS
//  • Solusi: gunakan Gemini REST API langsung via http package
//    (CORS diizinkan oleh Google untuk browser request ke generativelanguage.googleapis.com)
//
// Strategy:
//  1. Coba semua key valid secara round-robin
//  2. Key quota (429) → cooldown 60s lalu coba key lain
//  3. Key invalid (403/401) → skip permanen session ini
//  4. Pass 2: reset quota cooldown → retry semua key
//  5. Singleton dengan factory constructor
// ══════════════════════════════════════════════════════════════════

class MultiKeyAiManager {
  static final MultiKeyAiManager _instance = MultiKeyAiManager._internal();
  factory MultiKeyAiManager() => _instance;
  MultiKeyAiManager._internal() {
    debugPrint('[AI] MultiKeyAiManager v3 initialized (REST mode)');
  }

  // ── Model priority list (verified working 2026-05-17) ───────
  // gemini-2.0-flash = limit:0 free tier (tidak bisa dipakai)
  // gemini-2.5-flash = ✅ WORKS (free tier available)
  static const List<String> _models = [
    'gemini-2.5-flash',        // ✅ Primary - bekerja di free tier
    'gemini-2.5-flash-lite',   // ✅ Lighter version
    'gemini-flash-latest',     // ✅ Latest flash alias
    'gemini-flash-lite-latest',// ✅ Flash lite alias
    'gemini-2.0-flash-lite',   // Fallback
    'gemini-2.0-flash',        // Last resort (limit:0 saat ini)
  ];

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ── State ────────────────────────────────────────────────────
  final Map<String, DateTime> _quotaCooldown = {};
  final Set<String> _permanentSkip = {};
  int _currentIndex = 0;

  static const Duration _quotaCooldownDuration = Duration(seconds: 60);

  // ── Key selection ────────────────────────────────────────────

  String? _getAvailableKey() {
    final keys = Env.geminiKeys;
    if (keys.isEmpty) return null;
    final now = DateTime.now();

    for (int i = 0; i < keys.length; i++) {
      final idx = (_currentIndex + i) % keys.length;
      final key = keys[idx];
      if (_permanentSkip.contains(key)) continue;
      final cd = _quotaCooldown[key];
      if (cd == null || now.isAfter(cd)) {
        _currentIndex = (idx + 1) % keys.length;
        return key;
      }
    }
    return null;
  }

  void _markQuotaCooldown(String key) {
    _quotaCooldown[key] = DateTime.now().add(_quotaCooldownDuration);
    debugPrint('[AI] ⏳ ${_sk(key)} → quota cooldown ${_quotaCooldownDuration.inSeconds}s');
  }

  void _markInvalid(String key) {
    _permanentSkip.add(key);
    _quotaCooldown.remove(key);
    debugPrint('[AI] ❌ ${_sk(key)} → INVALID, permanent skip');
  }

  String _sk(String key) =>
      key.length >= 8 ? '..${key.substring(key.length - 6)}' : key;

  // ── Public controls ──────────────────────────────────────────

  void resetQuotaCooldowns() {
    _quotaCooldown.clear();
    _currentIndex = 0;
    debugPrint('[AI] 🔄 Quota cooldowns reset (${_permanentSkip.length} invalid keys kept)');
  }

  void manualResetAllCooldowns() {
    _quotaCooldown.clear();
    _permanentSkip.clear();
    _currentIndex = 0;
    debugPrint('[AI] 🔄 FULL reset — all state cleared');
  }

  int get readyKeyCount {
    final now = DateTime.now();
    return Env.geminiKeys.where((k) {
      if (_permanentSkip.contains(k)) return false;
      final cd = _quotaCooldown[k];
      return cd == null || now.isAfter(cd);
    }).length;
  }

  int get validKeyCount =>
      Env.geminiKeys.where((k) => !_permanentSkip.contains(k)).length;

  String get currentModel => _models.first;

  Map<String, String> get keyStatus {
    final keys = Env.geminiKeys;
    final now = DateTime.now();
    final result = <String, String>{};
    for (int i = 0; i < keys.length; i++) {
      final k = keys[i];
      if (_permanentSkip.contains(k)) {
        result['Key ${i + 1}'] = '❌ Invalid';
      } else {
        final cd = _quotaCooldown[k];
        if (cd != null && now.isBefore(cd)) {
          result['Key ${i + 1}'] = '⏳ ${cd.difference(now).inSeconds}s';
        } else {
          result['Key ${i + 1}'] = '✅ Ready';
        }
      }
    }
    return result;
  }

  // ══════════════════════════════════════════════════════════════
  // GENERATE TEXT — main entry point
  // ══════════════════════════════════════════════════════════════

  Future<String> generateText({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    int maxTokens = 2048,
  }) async {
    final keys = Env.geminiKeys;

    if (keys.isEmpty) {
      throw Exception(
        '❌ Tidak ada Gemini API key yang dikonfigurasi.\n\n'
        'Tambahkan GEMINI_KEY_1 di file .env\n'
        'Dapatkan key gratis: aistudio.google.com/app/apikey',
      );
    }

    debugPrint('[AI] generateText — ${keys.length} key(s), ready: $readyKeyCount');

    // ── Pass 1: Coba semua key yang available ─────────────────
    String? result = await _tryAllKeys(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    if (result != null) return result;

    // ── Pass 2: Reset quota cooldown → retry ─────────────────
    if (validKeyCount > 0) {
      debugPrint('[AI] Pass 2: reset quota cooldowns & retry...');
      resetQuotaCooldowns();
      result = await _tryAllKeys(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      if (result != null) return result;
    }

    // ── Gagal total ───────────────────────────────────────────
    final invalid = _permanentSkip.length;
    final total = keys.length;

    if (invalid >= total) {
      throw Exception(
        '⚠️ Semua $total API key tidak valid atau sudah expired.\n\n'
        'Silakan:\n'
        '1. Buka aistudio.google.com/app/apikey\n'
        '2. Buat API key baru (GRATIS)\n'
        '3. Update GEMINI_KEY_1 di file .env\n'
        '4. Restart aplikasi',
      );
    }

    throw Exception(
      'AI tidak dapat merespons saat ini.\n\n'
      'Key valid: ${total - invalid}/$total\n'
      'Semua key sedang cooldown. Coba lagi dalam 60 detik.',
    );
  }

  // ══════════════════════════════════════════════════════════════
  // GENERATE JSON
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> generateJson({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
    final raw = await generateText(
      systemPrompt: '$systemPrompt\n\nOutput HANYA valid JSON. Tanpa markdown, tanpa ```.',
      userPrompt: userPrompt,
      temperature: temperature,
      maxTokens: 2048,
    );

    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'```(?:json)?\s*'), '')
        .replaceAll('```', '')
        .trim();

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': raw, 'error': 'JSON parse failed'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Internal: try all keys with model fallback
  // ══════════════════════════════════════════════════════════════

  Future<String?> _tryAllKeys({
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final keys = Env.geminiKeys;

    for (int attempt = 0; attempt < keys.length; attempt++) {
      final key = _getAvailableKey();
      if (key == null) {
        debugPrint('[AI] No available key for attempt $attempt');
        break;
      }

      debugPrint('[AI] Attempt ${attempt + 1}/${keys.length} with ${_sk(key)}');

      for (final model in _models) {
        try {
          final text = await _callGeminiRest(
            apiKey: key,
            model: model,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
          );
          debugPrint('[AI] ✅ Success! key=${_sk(key)} model=$model');
          return text;

        } on _GeminiException catch (e) {
          debugPrint('[AI] GeminiException key=${_sk(key)} model=$model status=${e.statusCode}: ${e.message}');

          if (e.isQuota) {
            _markQuotaCooldown(key);
            break; // try next key
          }
          if (e.isInvalid) {
            _markInvalid(key);
            break; // try next key
          }
          if (e.isModelMissing) {
            continue; // try next model
          }
          // Other error (safety, bad prompt) — log and try next model
          debugPrint('[AI] Non-key error, trying next model...');
          continue;

        } catch (e) {
          debugPrint('[AI] Raw error key=${_sk(key)} model=$model: $e');
          final msg = e.toString().toLowerCase();
          if (msg.contains('timeout') || msg.contains('timed out')) {
            break; // timeout → try next key
          }
          continue;
        }
      }
    }

    return null;
  }

  // ══════════════════════════════════════════════════════════════
  // Gemini REST API call (replaces SDK — fixes CORS on Web)
  // ══════════════════════════════════════════════════════════════

  Future<String> _callGeminiRest({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    int maxTokens = 2048,
  }) async {
    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey');

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': systemPrompt}]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': userPrompt}]
        }
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
        'topP': 0.95,
        'topK': 40,
      },
      'safetySettings': [
        const {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_ONLY_HIGH'},
        const {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_ONLY_HIGH'},
        const {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_ONLY_HIGH'},
        const {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_ONLY_HIGH'},
      ],
    });

    late http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw Exception('Request timeout setelah 45s'),
          );
    } catch (e) {
      if (e.toString().contains('timeout')) rethrow;
      throw Exception('Network error: $e');
    }

    debugPrint('[AI] HTTP ${response.statusCode} for model=$model');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for blocked response
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        final feedback = data['promptFeedback'];
        final blockReason = feedback?['blockReason'];
        if (blockReason != null) {
          throw _GeminiException(
            'Konten diblokir oleh safety filter: $blockReason',
            statusCode: 200,
          );
        }
        throw _GeminiException('Respons kosong dari Gemini', statusCode: 200);
      }

      final candidate = candidates.first as Map<String, dynamic>;
      final finishReason = candidate['finishReason'] as String?;

      if (finishReason == 'SAFETY') {
        throw _GeminiException('Diblokir safety filter', statusCode: 200);
      }

      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      final text = parts?.first?['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        throw _GeminiException('Teks respons kosong', statusCode: 200);
      }

      return text.trim();
    }

    // ── Error responses ────────────────────────────────────────
    String errorMsg = 'HTTP ${response.statusCode}';
    try {
      final errData = jsonDecode(response.body);
      errorMsg = errData['error']?['message'] ?? errorMsg;
    } catch (_) {}

    throw _GeminiException(
      errorMsg,
      statusCode: response.statusCode,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Custom exception with status code classification
// ══════════════════════════════════════════════════════════════════

class _GeminiException implements Exception {
  final String message;
  final int statusCode;

  const _GeminiException(this.message, {required this.statusCode});

  bool get isQuota =>
      statusCode == 429 ||
      message.toLowerCase().contains('quota') ||
      message.toLowerCase().contains('resource_exhausted') ||
      message.toLowerCase().contains('rate limit') ||
      message.toLowerCase().contains('too many requests');

  bool get isInvalid =>
      statusCode == 401 ||
      statusCode == 403 ||
      message.toLowerCase().contains('api_key_invalid') ||
      message.toLowerCase().contains('api key not valid') ||
      message.toLowerCase().contains('invalid api key') ||
      message.toLowerCase().contains('permission_denied') ||
      message.toLowerCase().contains('unauthenticated');

  bool get isModelMissing =>
      statusCode == 404 ||
      message.toLowerCase().contains('not found') ||
      message.toLowerCase().contains('does not exist') ||
      message.toLowerCase().contains('model not found');

  @override
  String toString() => '_GeminiException($statusCode): $message';
}
