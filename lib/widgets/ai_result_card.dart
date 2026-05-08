import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Reusable card for displaying AI-generated results with copy & save actions.
class AiResultCard extends StatelessWidget {
  final String title;
  final String content;
  final int? variantIndex;
  final VoidCallback? onSave;
  final Color accentColor;

  const AiResultCard({
    super.key,
    required this.title,
    required this.content,
    this.variantIndex,
    this.onSave,
    this.accentColor = AppColors.accentLight,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  if (variantIndex != null) ...[
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accentColor, accentColor.withOpacity(0.6)]),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(child: Text('$variantIndex', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                ],
              ),
              const SizedBox(height: 10),
              // Content
              Text(content, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
              const SizedBox(height: 14),
              // Actions
              Row(
                children: [
                  _ActionChip(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Teks berhasil disalin!'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  if (onSave != null)
                    _ActionChip(icon: Icons.bookmark_add_outlined, label: 'Simpan', onTap: onSave!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accentLight),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer for AI result placeholder.
class AiResultShimmer extends StatelessWidget {
  const AiResultShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(120, 14),
              const SizedBox(height: 12),
              _shimmerBox(double.infinity, 12),
              const SizedBox(height: 6),
              _shimmerBox(double.infinity, 12),
              const SizedBox(height: 6),
              _shimmerBox(200, 12),
              const SizedBox(height: 16),
              Row(children: [_shimmerBox(70, 28), const SizedBox(width: 8), _shimmerBox(80, 28)]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
    );
  }
}
