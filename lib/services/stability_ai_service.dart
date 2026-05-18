import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'multi_key_ai_manager.dart';

// ══════════════════════════════════════════════════════════════════
// IMAGE GENERATION SERVICE — KreaSea
// ══════════════════════════════════════════════════════════════════
//
// Strategy (2026-05-18):
//   PRIMARY  : Gemini Imagen via Pollinations.ai proxy (free, no key, no CORS)
//   SECONDARY: Pollinations.ai direct (free, no key, no CORS)
//
// Pollinations.ai:
//   - 100% free, no API key required
//   - Returns image as URL (we fetch bytes → base64 for display)
//   - Web-safe (no CORS issues)
//   - URL: https://image.pollinations.ai/prompt/{encoded_prompt}?params
// ══════════════════════════════════════════════════════════════════

class StabilityAiService {
  static const String _pollinationsBase = 'https://image.pollinations.ai/prompt';
  static const Duration _timeout = Duration(seconds: 90);

  /// Generate single image, returns base64 string
  Future<String> generateImage({
    required String prompt,
    String aspectRatio = '1:1',
    String stylePreset = 'Minimalis',
  }) async {
    final enhanced = await _enhancePromptWithGemini(prompt, stylePreset);
    return _generateViaPoliinations(
      prompt: enhanced,
      aspectRatio: aspectRatio,
      mood: _stylePresetToMood(stylePreset),
    );
  }

  /// Generate multiple images (used by logo maker etc.)
  Future<List<String>> generateImages({
    required String prompt,
    String aspectRatio = '1:1',
    String mood = 'Minimalis',
    int samples = 4,
    bool enhancePrompt = false,
    String? businessName,
    String? businessType,
    String? purpose,
  }) async {
    final results = <String>[];
    final seeds = [42, 123, 777, 2025];

    for (int i = 0; i < samples; i++) {
      try {
        final result = await _generateViaPoliinations(
          prompt: prompt,
          aspectRatio: aspectRatio,
          mood: mood,
          seed: seeds[i % seeds.length] + i * 31,
        );
        results.add(result);
      } catch (e) {
        debugPrint('[ImageGen] Sample $i failed: $e');
      }
    }
    return results;
  }

  // ── Generate via Pollinations.ai ─────────────────────────────

  Future<String> _generateViaPoliinations({
    required String prompt,
    String aspectRatio = '1:1',
    String mood = 'Minimalis',
    int seed = 42,
  }) async {
    final (width, height) = _aspectToSize(aspectRatio);
    final modelName = _moodToModel(mood);

    // Build URL dengan parameter
    final encodedPrompt = Uri.encodeComponent(
      '$prompt, ${_moodToStyle(mood)}, high quality, professional, UMKM Indonesia',
    );

    final url = Uri.parse(
      '$_pollinationsBase/$encodedPrompt'
      '?width=$width&height=$height'
      '&model=$modelName'
      '&seed=$seed'
      '&nologo=true'
      '&enhance=true'
      '&safe=true',
    );

    debugPrint('[ImageGen] Requesting: ${url.toString().substring(0, 80)}...');

    final response = await http.get(url).timeout(_timeout);

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      final base64 = base64Encode(response.bodyBytes);
      debugPrint('[ImageGen] ✅ Success! ${response.bodyBytes.length} bytes');
      return base64;
    }

    throw Exception('Pollinations gagal: HTTP ${response.statusCode}');
  }

  // ── Enhance prompt menggunakan Gemini ──────────────────────

  Future<String> _enhancePromptWithGemini(String prompt, String style) async {
    try {
      final ai = MultiKeyAiManager();
      final enhanced = await ai.generateText(
        systemPrompt:
            'Kamu adalah ahli desain visual untuk UMKM Indonesia. '
            'Tugas: ubah deskripsi singkat menjadi prompt gambar yang detail dan profesional '
            'untuk AI image generation (maksimal 150 kata, bahasa Inggris). '
            'Fokus pada: komposisi visual, pencahayaan, warna, detail produk, latar belakang. '
            'Sertakan kata kunci kualitas: professional, high quality, detailed, sharp focus. '
            'Output HANYA prompt gambar, tanpa penjelasan tambahan.',
        userPrompt:
            'Buat prompt gambar untuk: "$prompt"\n'
            'Style: $style\n'
            'Tujuan: konten media sosial UMKM Indonesia',
        temperature: 0.7,
        maxTokens: 200,
      );
      debugPrint('[ImageGen] Gemini enhanced prompt: ${enhanced.substring(0, enhanced.length.clamp(0, 80))}...');
      return enhanced;
    } catch (e) {
      debugPrint('[ImageGen] Gemini enhance failed, using original: $e');
      return '$prompt, $style style, professional photography, high quality, Indonesian UMKM business';
    }
  }

  // ── Helpers ─────────────────────────────────────────────────

  (int, int) _aspectToSize(String ratio) {
    return switch (ratio) {
      '16:9' => (1280, 720),
      '9:16' => (720, 1280),
      '3:4'  => (768, 1024),
      '4:3'  => (1024, 768),
      '21:9' => (1280, 549),
      _      => (1024, 1024), // 1:1 default
    };
  }

  String _moodToModel(String mood) {
    return switch (mood) {
      'Elegan/Mewah'  => 'flux-pro',
      'Futuristic'    => 'flux',
      '3D Render'     => 'flux-3d',
      'Photography'   => 'flux-realism',
      'Flat Design'   => 'flux',
      _               => 'flux',
    };
  }

  String _moodToStyle(String mood) {
    return switch (mood) {
      'Minimalis'     => 'clean minimalist design, white background, elegant',
      'Playful/Ceria' => 'colorful, playful, vibrant colors, cheerful',
      'Elegan/Mewah'  => 'luxury, elegant, gold accents, premium quality',
      'Vintage'       => 'vintage style, retro, warm tones, nostalgic',
      'Futuristic'    => 'futuristic, neon lights, tech aesthetic, modern',
      '3D Render'     => '3D render, realistic materials, studio lighting',
      'Flat Design'   => 'flat design, vector art, geometric shapes',
      'Neon Glow'     => 'neon glow, dark background, vivid colors',
      'Watercolor'    => 'watercolor painting, soft edges, artistic',
      'Photography'   => 'professional photography, studio lighting, DSLR quality',
      _               => 'professional design',
    };
  }

  String _stylePresetToMood(String preset) {
    const map = {
      'enhance':      'Minimalis',
      'digital-art':  'Playful/Ceria',
      'photographic': 'Photography',
      'analog-film':  'Vintage',
      'neon-punk':    'Neon Glow',
      '3d-model':     '3D Render',
    };
    return map[preset] ?? preset;
  }

  Future<double> getBalance() async => -1.0;
}

final stabilityAiServiceProvider = Provider<StabilityAiService>(
  (ref) => StabilityAiService(),
);
