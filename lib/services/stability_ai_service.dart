import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

// ══════════════════════════════════════════════════════════════════
// IMAGE GENERATION SERVICE — KreaSea v6 (via Backend Proxy)
// ══════════════════════════════════════════════════════════════════
//
// KENAPA VIA BACKEND?
//   Flutter Web tidak bisa call NVIDIA API langsung — CORS block.
//   Backend (localhost:3001) diizinkan via CORS config di backend.
//   Backend yang call NVIDIA (server-to-server, bebas CORS).
//
// AUTH STRATEGY (dev mode):
//   1. Coba Firebase ID token dulu
//   2. Jika Firebase tidak tersedia → pakai DEV_API_SECRET dari .env
//
// RESULT TYPE:
//   - 'base64' → NVIDIA FLUX berhasil → return ImageResult.base64
//   - 'url'    → Pollinations fallback → return ImageResult.networkUrl
// ══════════════════════════════════════════════════════════════════

class StabilityAiService {
  final String _baseUrl = Env.backendUrl;

  // ── Ambil authorization header ───────────────────────────
  Future<String> _getAuthHeader() async {
    // 1. Coba Firebase token (force refresh untuk pastikan tidak expired)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // forceRefresh=false — pakai cache dulu, jika gagal baru force refresh
        String? token = await user.getIdToken(false);
        if (token != null && token.isNotEmpty) {
          debugPrint('[ImageService] Auth: Firebase token (cached)');
          return 'Bearer $token';
        }
      }
    } catch (e) {
      debugPrint('[ImageService] Firebase token gagal: $e');
    }

    // 2. Dev mode fallback — gunakan DevSecret dari .env jika tersedia.
    if (Env.devApiSecret.isNotEmpty) {
      debugPrint('[ImageService] Auth: DevSecret (dev mode fallback)');
      return 'DevSecret ${Env.devApiSecret}';
    }

    debugPrint('[ImageService] Auth: no token available');
    return '';
  }

  // ── Generate single image ──────────────────────────────────
  Future<ImageResult> generateImageResult({
    required String prompt,
    String aspectRatio = '1:1',
    String stylePreset = 'Minimalis',
    String purpose = '', // ← Tujuan visual (Promo Diskon, dll)
    String businessName = '', // ← Nama bisnis untuk konteks prompt
    String businessType = '', // ← Jenis bisnis untuk konteks prompt
    bool enhancePrompt = true,
  }) async {
    final authHeader = await _getAuthHeader();

    debugPrint(
        '[ImageService] POST $aspectRatio/$stylePreset purpose=$purpose → $_baseUrl/api/v1/image/generate');

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1/image/generate'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': authHeader,
            },
            body: jsonEncode({
              'prompt': prompt,
              'negativePrompt': '',
              'aspectRatio': aspectRatio,
              'mood': stylePreset,
              'samples': 1,
              'enhancePrompt': enhancePrompt,
              'purpose': purpose,
              'businessName': businessName,
              'businessType': businessType,
            }),
          )
          .timeout(const Duration(seconds: 160));
    } catch (e) {
      throw Exception(
        '🛑 Backend tidak dapat dihubungi.\n'
        'Jalankan backend dulu:\n'
        '  cd backend && npm start\n\n'
        'Detail: $e',
      );
    }

    debugPrint('[ImageService] Response: ${response.statusCode}');

    // Parse response
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Backend response tidak valid (${response.statusCode}). '
        'Pastikan backend berjalan di $_baseUrl',
      );
    }

    if (response.statusCode == 401 && Env.devApiSecret.isNotEmpty) {
      // 401: token tidak valid atau DevSecret salah
      // Coba sekali lagi dengan DevSecret sebagai fallback
      debugPrint('[ImageService] 401 received — retrying with DevSecret');
      http.Response retryResponse;
      try {
        retryResponse = await http
            .post(
              Uri.parse('$_baseUrl/api/v1/image/generate'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'DevSecret ${Env.devApiSecret}',
              },
              body: jsonEncode({
                'prompt': prompt,
                'negativePrompt': '',
                'aspectRatio': aspectRatio,
                'mood': stylePreset,
                'samples': 1,
                'enhancePrompt': enhancePrompt,
                'purpose': purpose,
                'businessName': businessName,
                'businessType': businessType,
              }),
            )
            .timeout(const Duration(seconds: 120));

        if (retryResponse.statusCode == 200) {
          // DevSecret retry sukses — update response & re-parse body
          response = retryResponse;
          try {
            body = jsonDecode(response.body) as Map<String, dynamic>;
          } catch (_) {
            throw Exception('Backend response tidak valid setelah retry.');
          }
        } else {
          throw Exception(
            'Auth gagal (401). DevSecret retry juga gagal (${retryResponse.statusCode}).\n'
            'Pastikan backend berjalan dan DEV_API_SECRET sama.',
          );
        }
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception(
            'Auth gagal (401). Backend tidak dapat dihubungi saat retry.');
      }
    }

    if (response.statusCode == 503) {
      final error = body['error'] as Map<String, dynamic>?;
      throw Exception(error?['message'] ?? 'Semua provider image gagal (503)');
    }

    if (response.statusCode != 200 || body['success'] != true) {
      final error = body['error'] as Map<String, dynamic>?;
      throw Exception(error?['message'] ??
          'Gagal generate gambar (${response.statusCode})');
    }

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Data response kosong dari backend');

    final images = data['images'] as List<dynamic>?;
    final imageType = data['imageType']?.toString() ?? 'url';
    final provider = data['provider']?.toString() ?? 'unknown';
    final promptSource = data['promptSource']?.toString() ?? '';
    final promptUsed = data['promptUsed']?.toString() ?? prompt;

    debugPrint(
        '[ImageService] Provider: $provider | Type: $imageType | Source: $promptSource | Count: ${images?.length}');

    if (images == null || images.isEmpty) {
      throw Exception(
          'Backend tidak mengembalikan gambar (provider: $provider)');
    }

    final rawImage = images.first.toString();

    if (imageType == 'base64') {
      // NVIDIA FLUX berhasil — return data URI
      final dataUri = rawImage.startsWith('data:image')
          ? rawImage
          : 'data:image/png;base64,$rawImage';
      return ImageResult(
        url: dataUri,
        type: ImageResultType.base64,
        provider: provider,
        promptUsed: promptUsed,
      );
    } else {
      // Pollinations fallback — return URL
      return ImageResult(
        url: rawImage,
        type: ImageResultType.networkUrl,
        provider: provider,
        promptUsed: promptUsed,
      );
    }
  }

  /// Backward-compatible: return URL string saja
  Future<String> generateImage({
    required String prompt,
    String aspectRatio = '1:1',
    String stylePreset = 'Minimalis',
  }) async {
    final result = await generateImageResult(
      prompt: prompt,
      aspectRatio: aspectRatio,
      stylePreset: stylePreset,
    );
    return result.url;
  }

  /// Generate multiple URLs (untuk logo maker — Pollinations)
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
    // Logo maker pakai Pollinations langsung (multi-seed, no backend needed)
    final seeds = [42, 123, 777, 2025, 314, 618, 999, 1337];
    final (w, h) = _aspectToSize(aspectRatio);
    final styleHint = _moodToStyle(mood);
    final fullPrompt = '$prompt, $styleHint, high quality, professional';
    final encoded = Uri.encodeComponent(fullPrompt);
    final pollinKey = Env.pollinationsApiKey;
    final keyParam = pollinKey.isNotEmpty ? '&token=$pollinKey' : '';

    return List.generate(
      samples.clamp(1, 8),
      (i) {
        final seed = seeds[i % seeds.length];
        return 'https://image.pollinations.ai/prompt/$encoded'
            '?width=$w&height=$h&model=flux&seed=$seed&nologo=true&safe=true$keyParam';
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  (int, int) _aspectToSize(String ratio) {
    return switch (ratio) {
      '16:9' => (1280, 720),
      '9:16' => (720, 1280),
      '3:4' => (768, 1024),
      '4:3' => (1024, 768),
      '21:9' => (1280, 549),
      _ => (1024, 1024),
    };
  }

  String _moodToStyle(String mood) {
    return switch (mood) {
      // Styles utama UMKM
      'Minimalis' =>
        'clean minimalist design, white background, elegant simplicity',
      'Playful/Ceria' => 'colorful vibrant playful cheerful energetic',
      'Elegan/Mewah' => 'luxury elegant gold premium sophisticated',
      'Photography' =>
        'professional photography studio lighting sharp realistic',
      'Flat Design' => 'flat design vector geometric clean bold',
      '3D Render' => '3D render realistic studio lighting volumetric',
      // Styles baru UMKM Indonesia
      'Warm & Cozy' =>
        'warm cozy atmosphere wooden textures soft bokeh golden light',
      'Bold Promo' =>
        'bold promotional high contrast commercial eye-catching vivid',
      'Clean Studio' =>
        'pure white background studio product shot e-commerce clean',
      'Pastel Aesthetic' =>
        'soft pastel aesthetic Korean-inspired fresh trendy Instagram',
      'Ramadan / Islami' =>
        'Islamic aesthetic crescent moon lantern gold green ornate pattern',
      // Styles niche
      'Futuristic' => 'futuristic modern tech aesthetic geometric precision',
      'Vintage' => 'vintage retro warm nostalgic heritage classic',
      'Neon Glow' => 'neon glow dark background vivid electric nightlife',
      'Watercolor' => 'watercolor painting soft artistic brush strokes',
      _ => 'professional design high quality commercial',
    };
  }

  Future<double> getBalance() async => -1.0;
}

// ── Data classes ────────────────────────────────────────────

enum ImageResultType { base64, networkUrl }

class ImageResult {
  final String url;
  final ImageResultType type;
  final String provider;
  final String promptUsed;

  const ImageResult({
    required this.url,
    required this.type,
    required this.provider,
    this.promptUsed = '',
  });

  bool get isBase64 => type == ImageResultType.base64;

  /// Extract bytes dari data URI (untuk Image.memory)
  Uint8List? get imageBytes {
    if (!isBase64) return null;
    try {
      final commaIdx = url.indexOf(',');
      if (commaIdx == -1) return null;
      return base64Decode(url.substring(commaIdx + 1));
    } catch (_) {
      return null;
    }
  }
}

// ── Provider ───────────────────────────────────────────────

final stabilityAiServiceProvider = Provider<StabilityAiService>(
  (ref) => StabilityAiService(),
);
