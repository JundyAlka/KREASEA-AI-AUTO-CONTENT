import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';

class GeminiService {
  final String _apiKey = Env.geminiApiKey;
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  Future<String> enhancePrompt({
    required String originalPrompt,
    required String purpose,
    required String mood,
    String? businessName,
    String? businessType,
    String? businessDescription,
  }) async {
    final systemInstruction = """
    You are an elite AI Art Director and Prompt Engineer for Stable Diffusion XL.
    Your goal is to transform a simple user request into a PROMPT for a highly aesthetic, professional image.

    **User Request**: "$originalPrompt"
    **Context**:
    - **Business Goal**: $purpose
    - **Business Name**: ${businessName ?? 'Generic Brand'}
    - **Business Type**: ${businessType ?? 'General'}
    - **Description**: ${businessDescription ?? ''}
    - **Target Mood**: $mood

    **Critical Instructions**:
    1.  **VISUALS FIRST**: Describe the *visual elements*, *background*, *lighting*, *textures*, and *composition*.
    2.  **BRAND ALIGNMENT**: Ensure the image connects with the business type ($businessType). If it's a restaurant, make it appetizing. If fashion, make it stylish.
    3.  **NO TEXT**: Do NOT ask for text to be written on the image. AI cannot write text well. Instead, describe a *clean layout* or *negative space* where text could be added later.
    4.  **QUALITY BOOSTERS**: Always include keywords like: "masterpiece, best quality, 8k, ultra-detailed, professional photography, cinematic lighting, sharp focus, hdr".
    5.  **STYLE ADAPTATION**:
        - If mood is 'Minimalis': Focus on clean lines, solid colors, negative space, soft shadows.
        - If mood is 'Playful': Use vibrant colors, soft shapes, high saturation, digital art style.
        - If mood is 'Elegan': Use dark tones, gold accents, dramatic lighting, luxury textures, marble, silk.
    6.  **OUTPUT**: Return ONLY the final English prompt string.
    """;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": systemInstruction}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return text.trim();
        }
      }
      debugPrint('Gemini Error: ${response.statusCode} - ${response.body}');
      return "$purpose. $originalPrompt. $mood style."; // Fallback
    } catch (e) {
      debugPrint('Gemini Exception: $e');
      return "$purpose. $originalPrompt. $mood style."; // Fallback
    }
  }

  /// Generic text generation for all AI features.
  Future<String> generateText({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "system_instruction": {
            "parts": [{"text": systemPrompt}]
          },
          "contents": [
            {
              "parts": [{"text": userPrompt}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
        }
      }
      debugPrint('Gemini Error: ${response.statusCode} - ${response.body}');
      return 'Maaf, terjadi kesalahan saat memproses permintaan. Silakan coba lagi.';
    } catch (e) {
      debugPrint('Gemini Exception: $e');
      return 'Maaf, gagal terhubung ke AI. Periksa koneksi internet dan coba lagi.';
    }
  }

  /// JSON generation — parses Gemini response as Map.
  Future<Map<String, dynamic>> generateJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final raw = await generateText(systemPrompt: systemPrompt, userPrompt: userPrompt);
    try {
      // Strip markdown code blocks if present
      String cleaned = raw;
      if (cleaned.contains('```json')) {
        cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();
      } else if (cleaned.contains('```')) {
        cleaned = cleaned.replaceAll('```', '').trim();
      }
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return {'error': true, 'raw': raw};
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
