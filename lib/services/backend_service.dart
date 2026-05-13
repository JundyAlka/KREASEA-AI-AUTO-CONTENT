import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

/// BackendService — Semua AI call melalui backend KreaSea.
/// API key Gemini & Stability AI tidak ada di Flutter — 100% aman.
///
/// ⚠️ Web-compatible: tidak menggunakan dart:io atau File.
class BackendService {
  final String _baseUrl = Env.backendUrl;

  // ── Ambil Firebase ID Token ───────────────────────────────
  Future<String?> _getToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(false);
    } catch (e) {
      debugPrint('[BackendService] Gagal ambil token: $e');
      return null;
    }
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── Utility: handle response ──────────────────────────────
  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw BackendException(
        'Respons server tidak valid (bukan JSON). Status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode == 200 && body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }

    final error = body['error'] as Map<String, dynamic>?;
    final code = error?['code']?.toString() ?? 'UNKNOWN';
    final message = error?['message']?.toString() ?? 'Terjadi kesalahan tidak diketahui';

    if (code == 'QUOTA_EXCEEDED') throw QuotaExceededException(message);
    if (code == 'TOKEN_EXPIRED' || code == 'UNAUTHORIZED') throw AuthException(message);
    throw BackendException(message, code: code, statusCode: response.statusCode);
  }

  // ═══════════════════════════════════════════════════════════
  // TEXT GENERATION (Menggantikan GeminiService)
  // ═══════════════════════════════════════════════════════════

  Future<String> generateText({
    required String feature,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    int maxTokens = 2048,
  }) async {
    final token = await _getToken();
    if (token == null) throw AuthException('Silakan login terlebih dahulu');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/content/generate'),
          headers: _headers(token),
          body: jsonEncode({
            'feature': feature,
            'systemPrompt': systemPrompt,
            'userPrompt': userPrompt,
            'outputFormat': 'text',
            'temperature': temperature,
            'maxTokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 35));

    final data = _parseResponse(response);
    return data['result']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> generateJson({
    required String feature,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.8,
    int maxTokens = 2048,
  }) async {
    final token = await _getToken();
    if (token == null) throw AuthException('Silakan login terlebih dahulu');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/content/generate'),
          headers: _headers(token),
          body: jsonEncode({
            'feature': feature,
            'systemPrompt': systemPrompt,
            'userPrompt': userPrompt,
            'outputFormat': 'json',
            'temperature': temperature,
            'maxTokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 35));

    final data = _parseResponse(response);
    final result = data['result'];
    if (result is Map<String, dynamic>) return result;
    return {'_raw': result?.toString() ?? ''};
  }

  // ═══════════════════════════════════════════════════════════
  // IMAGE GENERATION (Menggantikan StabilityAiService)
  // ═══════════════════════════════════════════════════════════

  Future<List<String>> generateImage({
    required String prompt,
    String negativePrompt = '',
    String aspectRatio = '1:1',
    String mood = 'Minimalis',
    int samples = 1,
    bool enhancePrompt = false,
    String? purpose,
    String? businessName,
    String? businessType,
  }) async {
    final token = await _getToken();
    if (token == null) throw AuthException('Silakan login terlebih dahulu');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/image/generate'),
          headers: _headers(token),
          body: jsonEncode({
            'prompt': prompt,
            'negativePrompt': negativePrompt,
            'aspectRatio': aspectRatio,
            'mood': mood,
            'samples': samples,
            'enhancePrompt': enhancePrompt,
            if (purpose != null) 'purpose': purpose,
            if (businessName != null) 'businessName': businessName,
            if (businessType != null) 'businessType': businessType,
          }),
        )
        .timeout(const Duration(seconds: 90));

    final data = _parseResponse(response);
    final images = data['images'];
    if (images is! List) return [];
    return images.map((e) => e.toString()).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // HPP CALCULATOR
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> calculateHpp({
    required List<Map<String, dynamic>> bahanBaku,
    List<Map<String, dynamic>> tenagaKerja = const [],
    List<Map<String, dynamic>> overhead = const [],
    required int jumlahProduksi,
  }) async {
    final token = await _getToken();
    if (token == null) throw AuthException('Silakan login terlebih dahulu');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/hpp/calculate'),
          headers: _headers(token),
          body: jsonEncode({
            'bahan_baku': bahanBaku,
            'tenaga_kerja': tenagaKerja,
            'overhead': overhead,
            'jumlah_produksi': jumlahProduksi,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _parseResponse(response);
  }

  Future<String> getHppAdvice({
    required double hppPerUnit,
    required double hargaJual,
    required String kategoriProduk,
    required String lokasi,
  }) async {
    final token = await _getToken();
    if (token == null) throw AuthException('Silakan login terlebih dahulu');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/v1/hpp/ai-advice'),
          headers: _headers(token),
          body: jsonEncode({
            'hpp_per_unit': hppPerUnit,
            'harga_jual': hargaJual,
            'kategori_produk': kategoriProduk,
            'lokasi': lokasi,
          }),
        )
        .timeout(const Duration(seconds: 35));

    final data = _parseResponse(response);
    return data['advice']?.toString() ?? '';
  }

  // ═══════════════════════════════════════════════════════════
  // PHOTO ANALYSIS — Web-safe (bytes, bukan File)
  // ═══════════════════════════════════════════════════════════

  /// Analisis foto produk.
  /// [imageBytes] — gunakan dart:typed_data Uint8List (web-compatible).
  /// [fileName]   — nama file asli untuk content-type detection.
  Future<Map<String, dynamic>> analyzePhotoBytes({
    required Uint8List imageBytes,
    String fileName = 'photo.jpg',
    String kategori = 'Produk umum',
    String platform = 'Instagram Feed',
  }) async {
    final token = await _getToken();
    if (token == null) throw AuthException('Silakan login terlebih dahulu');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/photo-analysis'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['kategori'] = kategori
      ..fields['platform'] = platform
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _parseResponse(response);
  }

  // ─── Health check ──────────────────────────────────────────
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/v1/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[BackendService] Health check failed: $e');
      return false;
    }
  }
}

// ── Custom Exceptions ──────────────────────────────────────────
class BackendException implements Exception {
  final String message;
  final String code;
  final int statusCode;
  BackendException(this.message, {this.code = 'BACKEND_ERROR', this.statusCode = 500});
  @override
  String toString() => 'BackendException[$code]: $message';
}

class QuotaExceededException extends BackendException {
  QuotaExceededException(String message)
      : super(message, code: 'QUOTA_EXCEEDED', statusCode: 429);
}

class AuthException extends BackendException {
  AuthException(String message)
      : super(message, code: 'UNAUTHORIZED', statusCode: 401);
}

// ── Riverpod Provider ──────────────────────────────────────────
final backendServiceProvider = Provider<BackendService>((ref) => BackendService());
