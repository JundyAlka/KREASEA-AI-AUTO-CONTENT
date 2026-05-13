import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

// ══════════════════════════════════════════════════════════════════
// MULTI-KEY AI MANAGER — KreaSea
// ══════════════════════════════════════════════════════════════════
//
// Fitur:
//  • 5 Gemini API key dengan round-robin rotation
//  • Auto-skip key yang sedang kena quota (429)
//  • OpenAI GPT-4o-mini sebagai fallback jika semua Gemini habis
//  • Cooldown 1 menit per key saat kena 429
//  • Singleton — shared di seluruh app
// ══════════════════════════════════════════════════════════════════

class MultiKeyAiManager {
  // Singleton
  static final MultiKeyAiManager _instance = MultiKeyAiManager._internal();
  factory MultiKeyAiManager() => _instance;
  MultiKeyAiManager._internal();

  // State per key: kapan cooldown-nya selesai (null = siap dipakai)
  final Map<String, DateTime> _keyCooldown = {};
  int _currentIndex = 0;

  // ── Ambil key yang siap dipakai ─────────────────────────────────
  String? _getAvailableKey() {
    final keys = Env.geminiKeys;
    if (keys.isEmpty) return null;

    final now = DateTime.now();
    for (int attempt = 0; attempt < keys.length; attempt++) {
      final idx = (_currentIndex + attempt) % keys.length;
      final key = keys[idx];
      final cooldown = _keyCooldown[key];
      if (cooldown == null || now.isAfter(cooldown)) {
        _currentIndex = (idx + 1) % keys.length; // advance untuk next call
        return key;
      }
    }
    return null; // semua key sedang cooldown
  }

  // ── Set cooldown saat key kena 429 ──────────────────────────────
  void _setCooldown(String key) {
    _keyCooldown[key] = DateTime.now().add(const Duration(minutes: 1));
    debugPrint('[MultiKeyAI] Key ...${key.substring(key.length - 6)} cooldown 60s');
  }

  // ══════════════════════════════════════════════════════════════
  // GENERATE TEXT — Gemini dengan fallback OpenAI
  // ══════════════════════════════════════════════════════════════

  /// Generate text dengan multi-key rotation + OpenAI fallback
  Future<String> generateText({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    int maxTokens = 2048,
  }) async {
    // ── Coba semua Gemini key ──────────────────────────────────
    final keys = Env.geminiKeys;
    for (int attempt = 0; attempt < keys.length; attempt++) {
      final key = _getAvailableKey();
      if (key == null) break; // semua cooldown, langsung fallback

      try {
        final result = await _callGemini(
          apiKey: key,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
        debugPrint('[MultiKeyAI] Gemini success (key ...${key.substring(key.length - 6)})');
        return result;
      } on GenerativeAIException catch (e) {
        if (e.message.contains('429') || e.message.toLowerCase().contains('quota') || e.message.toLowerCase().contains('rate')) {
          debugPrint('[MultiKeyAI] 429 on key ...${key.substring(key.length - 6)}, trying next');
          _setCooldown(key);
          continue; // coba key berikutnya
        }
        debugPrint('[MultiKeyAI] Gemini error: ${e.message}');
        rethrow;
      } catch (e) {
        debugPrint('[MultiKeyAI] Unexpected Gemini error: $e');
        if (e.toString().contains('429') || e.toString().contains('quota')) {
          _setCooldown(key);
          continue;
        }
        // Error lain: langsung fallback
        break;
      }
    }

    // ── Fallback: OpenAI GPT-4o-mini ──────────────────────────
    if (Env.openAiKey.isNotEmpty) {
      debugPrint('[MultiKeyAI] All Gemini keys exhausted, trying OpenAI fallback');
      try {
        return await _callOpenAI(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } catch (e) {
        debugPrint('[MultiKeyAI] OpenAI fallback also failed: $e');
      }
    }

    throw Exception('Semua AI provider sedang tidak tersedia. Coba lagi dalam beberapa menit.');
  }

  // ══════════════════════════════════════════════════════════════
  // GENERATE JSON — output terstruktur
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> generateJson({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
    final raw = await generateText(
      systemPrompt: '$systemPrompt\n\nIMPORTANT: Respond with valid JSON only. No markdown, no code blocks.',
      userPrompt: userPrompt,
      temperature: temperature,
      maxTokens: 2048,
    );

    // Bersihkan respons jika ada markdown
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```(?:json)?\n?'), '').trim();
    }

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[MultiKeyAI] JSON parse error, returning raw: $e');
      return {'raw': raw, 'error': 'JSON parse failed'};
    }
  }

  // ══════════════════════════════════════════════════════════════
  // INTERNAL: Call Gemini API
  // ══════════════════════════════════════════════════════════════

  Future<String> _callGemini({
    required String apiKey,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    int maxTokens = 2048,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxTokens,
      ),
      systemInstruction: Content.system(systemPrompt),
    );

    final response = await model.generateContent([
      Content.text(userPrompt),
    ]);

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned empty response');
    }
    return text.trim();
  }

  // ══════════════════════════════════════════════════════════════
  // INTERNAL: Call OpenAI API (fallback)
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

    throw Exception('OpenAI error ${response.statusCode}: ${response.body}');
  }

  // ── Diagnostik: status semua key ───────────────────────────────
  Map<String, String> get keyStatus {
    final keys = Env.geminiKeys;
    final now = DateTime.now();
    final Map<String, String> status = {};
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final cooldown = _keyCooldown[key];
      if (cooldown != null && now.isBefore(cooldown)) {
        final remaining = cooldown.difference(now).inSeconds;
        status['Key ${i + 1}'] = '⏳ Cooldown ${remaining}s';
      } else {
        status['Key ${i + 1}'] = '✅ Ready';
      }
    }
    if (Env.openAiKey.isNotEmpty) {
      status['OpenAI'] = '✅ Fallback Ready';
    }
    return status;
  }
}
