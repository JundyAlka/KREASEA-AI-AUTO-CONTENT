import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'multi_key_ai_manager.dart';
import 'prompt_engine.dart';

// ══════════════════════════════════════════════════════════════════
// GEMINI SERVICE — KreaSea
// ══════════════════════════════════════════════════════════════════
//
// Menggunakan MultiKeyAiManager (5 Gemini key + OpenAI fallback).
// Semua prompt dioptimalkan melalui PromptEngine.
// ══════════════════════════════════════════════════════════════════

class GeminiService {
  final _ai = MultiKeyAiManager();

  // ── Caption Generation ─────────────────────────────────────────

  /// Generate caption dengan multi-key rotation
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
    final systemPrompt = PromptEngine.captionSystem(
      businessName: userProfile.businessName.isNotEmpty
          ? userProfile.businessName
          : 'Bisnis UMKM',
      businessType: userProfile.businessType.isNotEmpty
          ? userProfile.businessType
          : 'Umum',
      businessDescription: userProfile.businessDescription,
      targetAudience: userProfile.targetAudience,
    );

    final userPrompt = PromptEngine.captionUser(
      purpose: purpose,
      platform: platform,
      productName: productName,
      tone: tone,
      length: length,
      useEmoji: useEmoji,
      useCTA: useCTA,
    );

    final raw = await _ai.generateText(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.85,
      maxTokens: 2500,
    );

    // Parse 3 variasi caption
    return _parseCaptionVariants(raw);
  }

  /// Parse hasil AI menjadi list caption
  List<String> _parseCaptionVariants(String raw) {
    final parts = raw.split(RegExp(r'---VARIASI \d+---', caseSensitive: false));
    if (parts.length >= 2) {
      return parts
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .take(3)
          .toList();
    }
    // Fallback: split by double newline atau numbered
    final lines = raw.split(RegExp(r'\n\n+'));
    if (lines.length >= 2) {
      return lines.where((l) => l.trim().isNotEmpty).take(3).toList();
    }
    return [raw.trim()];
  }

  // ── Image Prompt Enhancement ───────────────────────────────────

  /// Enhance prompt untuk image generation — jauh lebih detail & akurat
  Future<String> enhancePrompt({
    required String originalPrompt,
    required String purpose,
    required String mood,
    String? businessName,
    String? businessType,
    String? businessDescription,
  }) async {
    try {
      return await _ai.generateText(
        systemPrompt: PromptEngine.imageEnhanceSystem(
          businessName: businessName ?? 'Generic Business',
          businessType: businessType ?? 'General',
          mood: mood,
          purpose: purpose,
          businessDescription: businessDescription,
        ),
        userPrompt: PromptEngine.imageEnhanceUser(originalPrompt),
        temperature: 0.7,
        maxTokens: 400,
      );
    } catch (_) {
      // Fallback prompt sederhana jika AI gagal
      return '$originalPrompt. $mood style, professional photography, '
          'masterpiece, best quality, 8k, ultra-detailed, $purpose';
    }
  }

  // ── Generic Text Generation ────────────────────────────────────

  /// Generate text generik untuk fitur apapun
  Future<String> generateText({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    String feature = 'caption',
  }) async {
    return await _ai.generateText(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
    );
  }

  /// Generate JSON terstruktur
  Future<Map<String, dynamic>> generateJson({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    String feature = 'caption',
  }) async {
    return await _ai.generateJson(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
    );
  }

  // ── HPP Analysis ───────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeHPP({
    required String productName,
    required String businessType,
    required Map<String, double> costs,
    required int targetVolume,
    String? competitorPrice,
  }) async {
    return await _ai.generateJson(
      systemPrompt: PromptEngine.hppSystem(businessType),
      userPrompt: PromptEngine.hppUser(
        productName: productName,
        costs: costs,
        targetVolume: targetVolume,
        competitorPrice: competitorPrice,
      ),
      temperature: 0.3, // lebih deterministik untuk kalkulasi
    );
  }

  // ── Hashtag Research ───────────────────────────────────────────

  Future<Map<String, dynamic>> generateHashtags({
    required String productTopic,
    required String platform,
    required String businessType,
  }) async {
    return await _ai.generateJson(
      systemPrompt: PromptEngine.hashtagSystem(platform),
      userPrompt: PromptEngine.hashtagUser(
        productTopic: productTopic,
        platform: platform,
        businessType: businessType,
      ),
      temperature: 0.6,
    );
  }

  // ── Content Calendar ───────────────────────────────────────────

  Future<String> generateContentCalendar({
    required String businessName,
    required String businessType,
    required String month,
    required List<String> platforms,
  }) async {
    return await _ai.generateText(
      systemPrompt: PromptEngine.contentCalendarSystem(businessName, businessType),
      userPrompt: 'Buat content calendar untuk bulan $month. '
          'Platform: ${platforms.join(', ')}. '
          'Format yang rapi dan mudah dieksekusi tim kecil.',
      temperature: 0.7,
      maxTokens: 3000,
    );
  }

  // ── Diagnostik key status ──────────────────────────────────────
  Map<String, String> get keyStatus => _ai.keyStatus;
}

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());
