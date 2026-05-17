import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

// ══════════════════════════════════════════════════════════════════
// MULTI-KEY AI MANAGER — KreaSea
// ══════════════════════════════════════════════════════════════════
//
// Diagnosa (2026-05-15):
//  • Key 1-4 : API_KEY_INVALID (sudah di-revoke di Google Cloud)
//  • Key 5   : VALID — gemini-2.0-flash ✅, gemini-1.5-flash ❌ (404)
//
// Strategy:
//  1. Model PRIMARY: gemini-2.0-flash (bekerja di key 5)
//  2. Model FALLBACK: gemini-2.0-flash-lite (lebih ringan)
//  3. Key invalid → permanent skip (tidak direset di Pass 2)
//  4. Key quota   → reset di Pass 2 & retry
// ══════════════════════════════════════════════════════════════════

class MultiKeyAiManager {
  static final MultiKeyAiManager _instance = MultiKeyAiManager._internal();
  factory MultiKeyAiManager() => _instance;
  MultiKeyAiManager._internal();

  // Model yang bekerja dengan Key 5 (satu-satunya key valid saat ini)
  static const String _modelPrimary  = 'gemini-2.0-flash';
  static const String _modelFallback = 'gemini-2.0-flash-lite';
  static const String _modelLegacy   = 'gemini-1.5-flash'; // fallback terakhir

  // Cooldown tracking — pisahkan quota vs invalid
  final Map<String, DateTime> _quotaCooldown   = {};
  final Set<String>           _permanentSkip   = {}; // key invalid permanen
  int _currentIndex = 0;

  static const Duration _quotaCooldownDuration = Duration(seconds: 60);

  // ── Ambil key yang ready ─────────────────────────────────────
  String? _getAvailableKey({bool includeInvalid = false}) {
    final keys = Env.geminiKeys;
    if (keys.isEmpty) return null;
    final now = DateTime.now();
    for (int i = 0; i < keys.length; i++) {
      final idx = (_currentIndex + i) % keys.length;
      final key = keys[idx];
      if (!includeInvalid && _permanentSkip.contains(key)) continue;
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
    debugPrint('[AI] ⏳ key ..${_sk(key)} → quota cooldown ${_quotaCooldownDuration.inSeconds}s');
  }

  void _markInvalid(String key) {
    _permanentSkip.add(key);
    _quotaCooldown.remove(key); // tidak perlu quota cooldown jika invalid
    debugPrint('[AI] ❌ key ..${_sk(key)} → INVALID, skip permanen');
  }

  String _sk(String key) =>
      key.length >= 8 ? '..${key.substring(key.length - 6)}' : key;

  /// Reset HANYA quota cooldown (bukan invalid key)
  void resetQuotaCooldowns() {
    _quotaCooldown.clear();
    _currentIndex = 0;
    debugPrint('[AI] 🔄 Quota cooldown direset (${_permanentSkip.length} invalid key tetap di-skip)');
  }

  /// Reset semua termasuk invalid — pakai hanya jika key baru sudah diisi
  void manualResetAllCooldowns() {
    _quotaCooldown.clear();
    _permanentSkip.clear();
    _currentIndex = 0;
    debugPrint('[AI] 🔄 FULL reset — semua cooldown & invalid flag direset');
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

  Map<String, String> get keyStatus {
    final keys = Env.geminiKeys;
    final now  = DateTime.now();
    final result = <String, String>{};
    for (int i = 0; i < keys.length; i++) {
      final k = keys[i];
      if (_permanentSkip.contains(k)) {
        result['Key ${i+1}'] = '❌ Invalid (perlu diganti)';
      } else {
        final cd = _quotaCooldown[k];
        if (cd != null && now.isBefore(cd)) {
          result['Key ${i+1}'] = '⏳ ${cd.difference(now).inSeconds}s';
        } else {
          result['Key ${i+1}'] = '✅ Ready';
        }
      }
    }
    if (Env.openAiKey.isNotEmpty) {
      result['OpenAI'] = kIsWeb ? '⚠️ CORS (web)' : '✅ Fallback';
    }
    return result;
  }

  String get currentModel => _modelPrimary;

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
        'Tidak ada Gemini API key.\n'
        'Tambahkan GEMINI_KEY_1 s/d GEMINI_KEY_5 di file .env',
      );
    }

    // ── Pass 1: Coba semua key valid yang belum cooldown ────────
    debugPrint('[AI] Pass 1: ${readyKeyCount} key ready, ${validKeyCount} valid');
    var result = await _tryAllKeys(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    if (result != null) return result;

    // ── Pass 2: Reset quota cooldown & retry ────────────────────
    // (Hanya reset quota, key invalid tetap di-skip)
    final hasValidKeys = validKeyCount > 0;
    if (hasValidKeys) {
      debugPrint('[AI] Pass 2: reset quota cooldown & retry...');
      resetQuotaCooldowns();
      result = await _tryAllKeys(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      if (result != null) return result;
    }

    // ── Pass 3: OpenAI fallback (non-web) ─────────────────────
    if (!kIsWeb && Env.openAiKey.isNotEmpty) {
      debugPrint('[AI] Pass 3: OpenAI fallback...');
      try {
        return await _callOpenAI(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } catch (e) {
        debugPrint('[AI] OpenAI gagal: $e');
      }
    }

    // ── Gagal total — berikan pesan yang actionable ─────────────
    final invalid = _permanentSkip.length;
    final total   = keys.length;
    final valid   = total - invalid;

    if (invalid == total) {
      throw Exception(
        '⚠️ Semua $total Gemini API key sudah tidak valid.\n\n'
        'Segera ganti API key:\n'
        '1. Buka https://aistudio.google.com/app/apikey\n'
        '2. Buat API key baru (gratis)\n'
        '3. Update GEMINI_KEY_1 s/d GEMINI_KEY_5 di file .env\n'
        '4. Restart aplikasi',
      );
    }

    throw Exception(
      'AI tidak dapat merespons saat ini.\n\n'
      'Key valid: $valid/$total | Key invalid: $invalid/$total\n'
      'Coba lagi dalam 60 detik, atau tap ⚡ → Reset API Key.',
    );
  }

  Future<String?> _tryAllKeys({
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final keys = Env.geminiKeys;
    final models = [_modelPrimary, _modelFallback, _modelLegacy];

    for (int attempt = 0; attempt < keys.length; attempt++) {
      final key = _getAvailableKey();
      if (key == null) {
        debugPrint('[AI] Tidak ada key available');
        return null;
      }

      final sk = _sk(key);

      for (final model in models) {
        try {
          final text = await _callGemini(
            apiKey: key,
            model: model,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
          );
          debugPrint('[AI] ✅ Success ($sk, $model)');
          return text;

        } on GenerativeAIException catch (e) {
          final msg = e.message.toLowerCase();
          debugPrint('[AI] GAIException $sk $model: ${e.message}');

          if (_isQuota(msg)) {
            _markQuotaCooldown(key);
            break; // coba key lain
          }
          if (_isInvalidKey(msg)) {
            _markInvalid(key);
            break; // key ini invalid, coba key lain
          }
          if (_isModelMissing(msg)) {
            debugPrint('[AI] Model $model tidak tersedia di $sk, coba model lain');
            continue; // coba model berikutnya
          }
          // Error lain (content policy, bad prompt) → tidak penalti key
          debugPrint('[AI] Non-key error: ${e.message}');
          continue;

        } catch (e) {
          final msg = e.toString().toLowerCase();
          debugPrint('[AI] Raw error $sk $model: $e');

          if (_isQuota(msg)) {
            _markQuotaCooldown(key);
            break;
          }
          if (_isInvalidKey(msg)) {
            _markInvalid(key);
            break;
          }
          if (_isModelMissing(msg)) {
            continue;
          }
          if (msg.contains('timeout') || msg.contains('timed out')) {
            break; // timeout → coba key lain
          }
          continue;
        }
      }
    }

    return null;
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

    var cleaned = raw.trim()
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
  // Error classifiers
  // ══════════════════════════════════════════════════════════════

  bool _isQuota(String msg) =>
      msg.contains('429') ||
      msg.contains('quota') ||
      msg.contains('rate_limit') ||
      msg.contains('rate limit') ||
      msg.contains('resource_exhausted') ||
      msg.contains('too many requests') ||
      msg.contains('quota exceeded');

  bool _isInvalidKey(String msg) =>
      msg.contains('api_key_invalid') ||
      msg.contains('api key not valid') ||
      msg.contains('provide a valid api key') ||
      msg.contains('invalid api key') ||
      msg.contains('pass a valid api key') ||
      (msg.contains('permission_denied') && msg.contains('key')) ||
      (msg.contains('unauthenticated') && !msg.contains('user'));

  bool _isModelMissing(String msg) =>
      msg.contains('not_found') ||
      msg.contains('model not found') ||
      msg.contains('does not exist') ||
      (msg.contains('not found for api version'));

  // ══════════════════════════════════════════════════════════════
  // Call Gemini
  // ══════════════════════════════════════════════════════════════

  Future<String> _callGemini({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    int maxTokens = 2048,
  }) async {
    final m = GenerativeModel(
      model: model,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxTokens,
      ),
      systemInstruction: Content.system(systemPrompt),
    );

    final response = await m
        .generateContent([Content.text(userPrompt)]).timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw Exception('Timeout setelah 45s'),
    );

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw GenerativeAIException('Respons Gemini kosong');
    }
    return text.trim();
  }

  // ══════════════════════════════════════════════════════════════
  // Call OpenAI fallback
  // ══════════════════════════════════════════════════════════════

  Future<String> _callOpenAI({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    int maxTokens = 2048,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Env.openAiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    }
    if (response.statusCode == 401) throw Exception('OpenAI key tidak valid.');
    if (response.statusCode == 429) throw Exception('OpenAI quota habis.');
    throw Exception('OpenAI error ${response.statusCode}');
  }
}
