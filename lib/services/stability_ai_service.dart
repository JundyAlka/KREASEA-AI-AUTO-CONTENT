import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backend_service.dart';

/// StabilityAiService — Sekarang mendelegasikan ke BackendService.
/// API key Stability AI tidak lagi ada di Flutter — semua lewat backend.
/// Method signature dipertahankan agar kompatibel dengan fitur existing.
class StabilityAiService {
  final BackendService _backend = BackendService();

  /// Cek balance — sekarang dikembalikan dari backend status
  /// (tidak bisa cek per-key langsung dari Flutter)
  Future<double> getBalance() async {
    // Balance tidak bisa dicek dari Flutter tanpa key
    // Gunakan admin endpoint untuk monitoring
    return -1.0; // -1 = unknown
  }

  /// Generate gambar — delegate ke image orchestrator backend
  Future<String> generateImage({
    required String prompt,
    String aspectRatio = '1:1',
    String stylePreset = 'enhance',
  }) async {
    final images = await _backend.generateImage(
      prompt: prompt,
      aspectRatio: aspectRatio,
      mood: _stylePresetToMood(stylePreset),
      samples: 1,
    );

    if (images.isEmpty) throw Exception('Tidak ada gambar yang dihasilkan');
    return images.first; // return base64 string
  }

  /// Generate multiple images (untuk Logo Maker — 4 variasi)
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
    return await _backend.generateImage(
      prompt: prompt,
      aspectRatio: aspectRatio,
      mood: mood,
      samples: samples,
      enhancePrompt: enhancePrompt,
      businessName: businessName,
      businessType: businessType,
      purpose: purpose,
    );
  }

  /// Map style preset lama ke mood baru
  String _stylePresetToMood(String preset) {
    const map = {
      'enhance': 'Minimalis',
      'digital-art': 'Playful/Ceria',
      'photographic': 'Elegan/Mewah',
      'analog-film': 'Vintage',
      'neon-punk': 'Futuristic',
      '3d-model': '3D Render',
    };
    return map[preset] ?? 'Minimalis';
  }
}

final stabilityAiServiceProvider = Provider<StabilityAiService>((ref) {
  return StabilityAiService();
});
