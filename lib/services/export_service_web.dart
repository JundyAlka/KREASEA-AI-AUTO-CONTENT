// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'export_service_base.dart';

ExportService createExportService() => WebExportService();

class WebExportService implements ExportService {
  @override
  Future<ExportResult> downloadText({
    required String title,
    required String text,
  }) async {
    final fileName = '${safeFileName(title, fallback: 'caption-kreasea')}.txt';
    final blob = html.Blob([text], 'text/plain;charset=utf-8');
    _downloadBlob(blob, fileName);
    return ExportResult('Caption diunduh sebagai $fileName');
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
      return const ExportResult(
          'Share tidak tersedia. Caption disalin ke clipboard.');
    }
  }

  @override
  Future<ExportResult> downloadImage({
    required String title,
    required String imageUrl,
    String prompt = '',
  }) async {
    if (isDataImage(imageUrl)) {
      final mimeType = imageMimeType(imageUrl);
      final ext = imageExtension(mimeType);
      final bytes = dataImageBytes(imageUrl);
      if (bytes == null) {
        throw Exception('Data gambar tidak valid.');
      }
      final fileName =
          '${safeFileName(title, fallback: 'desain-kreasea')}.$ext';
      _downloadBlob(html.Blob([bytes], mimeType), fileName);
      return ExportResult('Gambar diunduh sebagai $fileName');
    }

    final anchor = html.AnchorElement(href: imageUrl)
      ..target = '_blank'
      ..download = '${safeFileName(title, fallback: 'desain-kreasea')}.png'
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    return const ExportResult('Gambar dibuka untuk diunduh.');
  }

  @override
  Future<ExportResult> shareImage({
    required String title,
    required String imageUrl,
    String prompt = '',
  }) async {
    final shareText = [
      if (prompt.trim().isNotEmpty) prompt.trim(),
      if (!isDataImage(imageUrl)) imageUrl,
      'Dibuat dengan KreaSea AI',
    ].join('\n\n');

    try {
      if (isDataImage(imageUrl)) {
        final bytes = dataImageBytes(imageUrl);
        final mimeType = imageMimeType(imageUrl);
        if (bytes != null) {
          final ext = imageExtension(mimeType);
          await Share.shareXFiles(
            [
              XFile.fromData(
                bytes,
                name: '${safeFileName(title, fallback: 'desain-kreasea')}.$ext',
                mimeType: mimeType,
              ),
            ],
            text: prompt.isNotEmpty ? prompt : 'Dibuat dengan KreaSea AI',
          );
          return const ExportResult('Share sheet gambar dibuka.');
        }
      }

      await Share.share(shareText, subject: title);
      return const ExportResult('Share sheet dibuka.');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText));
      return const ExportResult(
          'Share tidak tersedia. Konten disalin ke clipboard.');
    }
  }

  void _downloadBlob(html.Blob blob, String fileName) {
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
