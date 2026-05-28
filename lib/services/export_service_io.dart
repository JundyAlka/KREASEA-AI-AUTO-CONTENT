import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import 'export_service_base.dart';

ExportService createExportService() => IoExportService();

class IoExportService implements ExportService {
  @override
  Future<ExportResult> downloadText({
    required String title,
    required String text,
  }) async {
    final file = await _writeTempFile(
      '${safeFileName(title, fallback: 'caption-kreasea')}.txt',
      utf8.encode(text),
    );
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      text: 'Simpan caption KreaSea',
    );
    return const ExportResult('Pilih "Save to Files" atau aplikasi tujuan.');
  }

  @override
  Future<ExportResult> shareText({
    required String title,
    required String text,
  }) async {
    try {
      await Share.share(text, subject: title);
      return const ExportResult('Share sheet dibuka.');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      return const ExportResult('Share tidak tersedia. Caption disalin.');
    }
  }

  @override
  Future<ExportResult> downloadImage({
    required String title,
    required String imageUrl,
    String prompt = '',
  }) async {
    final data = await _imageData(imageUrl);
    final fileName =
        '${safeFileName(title, fallback: 'desain-kreasea')}.${imageExtension(data.mimeType)}';
    final file = await _writeTempFile(fileName, data.bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: data.mimeType)],
      text: 'Simpan gambar KreaSea AI',
    );
    return const ExportResult(
        'Pilih "Save to Files", galeri, atau aplikasi tujuan.');
  }

  @override
  Future<ExportResult> shareImage({
    required String title,
    required String imageUrl,
    String prompt = '',
  }) async {
    try {
      final data = await _imageData(imageUrl);
      final fileName =
          '${safeFileName(title, fallback: 'desain-kreasea')}.${imageExtension(data.mimeType)}';
      final file = await _writeTempFile(fileName, data.bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: data.mimeType)],
        text: prompt.isNotEmpty ? prompt : 'Dibuat dengan KreaSea AI',
      );
      return const ExportResult('Share sheet gambar dibuka.');
    } catch (_) {
      final fallbackText =
          isDataImage(imageUrl) ? 'Gambar dibuat dengan KreaSea AI' : imageUrl;
      await Clipboard.setData(ClipboardData(text: fallbackText));
      return const ExportResult('Share gambar gagal. Info gambar disalin.');
    }
  }

  Future<File> _writeTempFile(String fileName, List<int> bytes) async {
    final dir = Directory.systemTemp.createTempSync('kreasea_');
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<_ImageData> _imageData(String imageUrl) async {
    if (isDataImage(imageUrl)) {
      final bytes = dataImageBytes(imageUrl);
      if (bytes == null) throw Exception('Data gambar tidak valid.');
      return _ImageData(bytes, imageMimeType(imageUrl));
    }

    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal mengambil gambar (${response.statusCode}).');
    }
    return _ImageData(
      response.bodyBytes,
      response.headers['content-type']?.split(';').first ?? 'image/png',
    );
  }
}

class _ImageData {
  final List<int> bytes;
  final String mimeType;

  const _ImageData(this.bytes, this.mimeType);
}
