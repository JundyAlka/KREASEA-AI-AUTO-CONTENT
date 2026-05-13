import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'gemini_service.dart';

// ══════════════════════════════════════════════════════════════════
// AI TEXT SERVICE — delegasi ke GeminiService (MultiKey)
// ══════════════════════════════════════════════════════════════════

abstract class AiTextService {
  Future<List<String>> generateCaptions({
    required UserProfile userProfile,
    required String purpose,
    required String platform,
    required String productName,
    required String tone,
    required String length,
    bool useEmoji = true,
    bool useCTA = true,
  });
}

/// Implementasi real — pakai GeminiService dengan 5 key rotation
class GeminiAiTextService implements AiTextService {
  final GeminiService _gemini;
  GeminiAiTextService(this._gemini);

  @override
  Future<List<String>> generateCaptions({
    required UserProfile userProfile,
    required String purpose,
    required String platform,
    required String productName,
    required String tone,
    required String length,
    bool useEmoji = true,
    bool useCTA = true,
  }) async {
    return _gemini.generateCaptions(
      userProfile: userProfile,
      purpose: purpose,
      platform: platform,
      productName: productName,
      tone: tone,
      length: length,
      useEmoji: useEmoji,
      useCTA: useCTA,
    );
  }
}

/// Provider — pakai GeminiAiTextService (real AI, bukan stub)
final aiTextServiceProvider = Provider<AiTextService>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return GeminiAiTextService(gemini);
});
