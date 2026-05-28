import 'package:flutter/services.dart';

import 'export_service_base.dart';

ExportService createExportService() => StubExportService();

class StubExportService implements ExportService {
  @override
  Future<ExportResult> downloadText({
    required String title,
    required String text,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    return const ExportResult(
        'Teks disalin. Platform ini belum mendukung unduh file.');
  }

  @override
  Future<ExportResult> shareText({
    required String title,
    required String text,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    return const ExportResult('Teks disalin. Paste ke aplikasi tujuan.');
  }

  @override
  Future<ExportResult> downloadImage({
    required String title,
    required String imageUrl,
    String prompt = '',
  }) async {
    await Clipboard.setData(ClipboardData(text: imageUrl));
    return const ExportResult(
        'Link gambar disalin. Platform ini belum mendukung unduh file.');
  }

  @override
  Future<ExportResult> shareImage({
    required String title,
    required String imageUrl,
    String prompt = '',
  }) async {
    await Clipboard.setData(ClipboardData(text: imageUrl));
    return const ExportResult('Link gambar disalin. Paste ke aplikasi tujuan.');
  }
}
