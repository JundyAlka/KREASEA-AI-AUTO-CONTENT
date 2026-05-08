import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';

class StabilityAiService {
  final String _apiKey = Env.stabilityApiKey;
  // Updated to SDXL 1.0 which is more stable and higher quality
  final String _baseUrl =
      'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image';
  final String _balanceUrl = 'https://api.stability.ai/v1/user/balance';

  Future<double> getBalance() async {
    try {
      final response = await http.get(
        Uri.parse(_balanceUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['credits'] as num).toDouble();
      } else {
        throw Exception('Failed to load balance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting balance: $e');
      return 0.0;
    }
  }

  Future<String> generateImage({
    required String prompt,
    String aspectRatio = '1:1',
    String stylePreset = 'enhance',
  }) async {
    // SDXL supported resolutions
    int width = 1024;
    int height = 1024;

    if (aspectRatio == '16:9') {
      width = 1344;
      height = 768;
    } else if (aspectRatio == '9:16') {
      width = 768;
      height = 1344;
    }

    final finalPrompt = "$prompt, masterpiece, best quality, ultra-detailed";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "text_prompts": [
            {"text": finalPrompt, "weight": 1},
            {
              "text":
                  "text, watermark, signature, blurry, low quality, bad anatomy, distorted, ugly, pixelated, amateur, cropped, frame, border",
              "weight": -1
            }
          ],
          "cfg_scale": 7,
          "height": height,
          "width": width,
          "samples": 1,
          "steps": 40, // Increased steps for better quality
          "style_preset": _mapMoodToStyle(stylePreset),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Image = data['artifacts'][0]['base64'];
        return base64Image;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'Stability AI Error: ${error['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate image: $e');
    }
  }

  String _mapMoodToStyle(String mood) {
    // Map UI moods to Stability AI style presets
    switch (mood) {
      case 'Minimalis':
        return 'enhance'; // Clean, crisp
      case 'Playful/Ceria':
        return 'digital-art'; // Changed from comic-book to digital-art for better quality
      case 'Elegan/Mewah':
        return 'photographic'; // High quality realism
      case 'Vintage':
        return 'analog-film'; // Film grain, retro colors
      case 'Futuristic':
        return 'neon-punk'; // Cyberpunk, neon
      case '3D Render':
        return '3d-model';
      default:
        return 'enhance';
    }
  }
}

final stabilityAiServiceProvider = Provider<StabilityAiService>((ref) {
  return StabilityAiService();
});
