import 'dart:convert';
import 'dart:typed_data';

class ExportResult {
  final String message;

  const ExportResult(this.message);
}

abstract class ExportService {
  Future<ExportResult> downloadText({
    required String title,
    required String text,
  });

  Future<ExportResult> shareText({
    required String title,
    required String text,
  });

  Future<ExportResult> downloadImage({
    required String title,
    required String imageUrl,
    String prompt = '',
  });

  Future<ExportResult> shareImage({
    required String title,
    required String imageUrl,
    String prompt = '',
  });
}

String safeFileName(String raw, {String fallback = 'kreasea-export'}) {
  final cleaned = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\-_ ]'), '')
      .replaceAll(RegExp(r'\s+'), '-');
  if (cleaned.isEmpty) return fallback;
  return cleaned.length > 60 ? cleaned.substring(0, 60) : cleaned;
}

bool isDataImage(String imageUrl) => imageUrl.startsWith('data:image');

String imageMimeType(String imageUrl) {
  if (!isDataImage(imageUrl)) return 'image/png';
  final header = imageUrl.substring(0, imageUrl.indexOf(','));
  final match = RegExp(r'data:([^;]+)').firstMatch(header);
  return match?.group(1) ?? 'image/png';
}

String imageExtension(String mimeType) {
  return switch (mimeType) {
    'image/jpeg' => 'jpg',
    'image/jpg' => 'jpg',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'png',
  };
}

Uint8List? dataImageBytes(String imageUrl) {
  if (!isDataImage(imageUrl)) return null;
  final comma = imageUrl.indexOf(',');
  if (comma == -1) return null;
  return base64Decode(imageUrl.substring(comma + 1));
}
