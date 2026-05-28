import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════
// AI RESULT CARD — Editable, copyable, shareable
// ══════════════════════════════════════════════════════════════════

class AiResultCard extends StatefulWidget {
  final String title;
  final String content;
  final int? variantIndex;
  final VoidCallback? onSave;
  final VoidCallback? onRegenerate;
  final Future<String?> Function(String current)? onImprove;
  final Color accentColor;

  const AiResultCard({
    super.key,
    required this.title,
    required this.content,
    this.variantIndex,
    this.onSave,
    this.onRegenerate,
    this.onImprove,
    this.accentColor = AppColors.accentLight,
  });

  @override
  State<AiResultCard> createState() => _AiResultCardState();
}

class _AiResultCardState extends State<AiResultCard>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isEditing = false;
  bool _isImproving = false;
  bool _isCopied = false;
  final ExportService _exportService = createExportService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void didUpdateWidget(AiResultCard old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content) {
      _controller.text = widget.content;
      _animController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    setState(() => _isCopied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Caption berhasil disalin!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isCopied = false);
  }

  Future<void> _downloadText() async {
    try {
      final result = await _exportService.downloadText(
        title: widget.title,
        text: _controller.text,
      );
      if (mounted) {
        _showSnack(result.message, Icons.download_done_rounded,
            const Color(0xFF00BCD4));
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal unduh: $e', Icons.error_rounded, Colors.red.shade800);
      }
    }
  }

  Future<void> _shareText() async {
    try {
      final result = await _exportService.shareText(
        title: widget.title,
        text: _controller.text,
      );
      if (mounted) {
        _showSnack(
            result.message, Icons.share_rounded, const Color(0xFF25D366));
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: _controller.text));
      if (mounted) {
        _showSnack(
          'Share gagal. Caption disalin ke clipboard.',
          Icons.copy_rounded,
          const Color(0xFF25D366),
        );
      }
    }
  }

  void _showSnack(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _improveText() async {
    if (widget.onImprove == null) return;
    setState(() => _isImproving = true);
    try {
      final improved = await widget.onImprove!(_controller.text);
      if (improved != null && mounted) {
        setState(() => _controller.text = improved);
        _animController
          ..reset()
          ..forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Caption berhasil diperbaiki!'),
              ],
            ),
            backgroundColor: const Color(0xFF7C4DFF),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal improve: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImproving = false);
    }
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isEditing
                    ? widget.accentColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: _isEditing ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                _buildHeader(),

                // ── Content (editable or readonly) ──────────
                _buildContent(),

                // ── Edit mode save/cancel bar ────────────────
                if (_isEditing) _buildEditBar(),

                // ── Action buttons ───────────────────────────
                if (!_isEditing) _buildActionBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          if (widget.variantIndex != null) ...[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  widget.accentColor,
                  widget.accentColor.withOpacity(0.6)
                ]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${widget.variantIndex}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          // Edit toggle button
          _IconBtn(
            icon: _isEditing ? Icons.close_rounded : Icons.edit_rounded,
            tooltip: _isEditing ? 'Batal edit' : 'Edit teks',
            color: _isEditing ? Colors.red.shade300 : Colors.white38,
            onTap: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          controller: _controller,
          maxLines: null,
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.6,
          ),
          cursorColor: widget.accentColor,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Edit caption di sini...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Text(
        _controller.text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildEditBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isEditing = false),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Simpan Perubahan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() {
              _controller.text = widget.content;
              _isEditing = false;
            }),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            child: const Text('Reset', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Copy
          _ActionChipNew(
            icon: _isCopied ? Icons.check_rounded : Icons.copy_rounded,
            label: _isCopied ? 'Copied!' : 'Copy',
            color: _isCopied ? AppColors.success : widget.accentColor,
            onTap: _copyToClipboard,
          ),

          _ActionChipNew(
            icon: Icons.download_rounded,
            label: 'Unduh',
            color: const Color(0xFF00BCD4),
            onTap: _downloadText,
          ),

          // Share
          _ActionChipNew(
            icon: Icons.share_rounded,
            label: 'Share',
            color: const Color(0xFF25D366),
            onTap: _shareText,
          ),

          // Improve dengan Gemini
          if (widget.onImprove != null)
            _ActionChipNew(
              icon: _isImproving
                  ? Icons.hourglass_top_rounded
                  : Icons.auto_awesome_rounded,
              label: _isImproving ? 'AI...' : 'Improve',
              color: const Color(0xFF7C4DFF),
              onTap: _isImproving ? () {} : _improveText,
            ),

          if (widget.onRegenerate != null)
            _ActionChipNew(
              icon: Icons.refresh_rounded,
              label: 'Ulang',
              color: const Color(0xFFE91E63),
              onTap: widget.onRegenerate!,
            ),

          // Save to library
          if (widget.onSave != null)
            _IconBtn(
              icon: Icons.bookmark_add_rounded,
              tooltip: 'Simpan ke Library',
              color: Colors.white38,
              onTap: widget.onSave!,
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// IMAGE RESULT CARD — Supports base64 data URI & network URL
// ══════════════════════════════════════════════════════════════════

class AiImageResultCard extends StatefulWidget {
  /// URL gambar:
  ///   - 'data:image/png;base64,...' → NVIDIA FLUX result
  ///   - 'https://...'              → Pollinations fallback
  final String imageUrl;
  final String prompt;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSave;

  const AiImageResultCard({
    super.key,
    required this.imageUrl,
    this.prompt = '',
    this.onRegenerate,
    this.onSave,
  });

  // Helper: cek apakah URL ini base64 data URI
  bool get isBase64 => imageUrl.startsWith('data:image');

  // Extract bytes dari data URI jika base64
  Uint8List? get imageBytes {
    if (!isBase64) return null;
    try {
      final commaIdx = imageUrl.indexOf(',');
      if (commaIdx == -1) return null;
      return base64Decode(imageUrl.substring(commaIdx + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  State<AiImageResultCard> createState() => _AiImageResultCardState();
}

class _AiImageResultCardState extends State<AiImageResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  final ExportService _exportService = createExportService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void didUpdateWidget(AiImageResultCard old) {
    super.didUpdateWidget(old);
    // Jika URL gambar berubah → restart animasi agar gambar baru muncul dengan mulus
    if (old.imageUrl != widget.imageUrl) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _viewFullscreen(BuildContext context) {
    final imageWidget = widget.isBase64
        ? () {
            final bytes = widget.imageBytes;
            if (bytes == null) {
              return const Center(
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.white24, size: 64),
              );
            }
            return Image.memory(bytes, fit: BoxFit.contain);
          }()
        : Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded,
                  color: Colors.white24, size: 64),
            ),
          );

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: imageWidget,
              ),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      final result = await _exportService.downloadImage(
        title: 'desain-kreasea',
        imageUrl: widget.imageUrl,
        prompt: widget.prompt,
      );
      if (context.mounted) {
        _showImageSnack(context, result.message, Icons.download_done_rounded,
            const Color(0xFF00BCD4));
      }
    } catch (e) {
      if (context.mounted) {
        _showImageSnack(context, 'Gagal unduh gambar: $e', Icons.error_rounded,
            Colors.red.shade800);
      }
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      final result = await _exportService.shareImage(
        title: 'desain-kreasea',
        imageUrl: widget.imageUrl,
        prompt: widget.prompt,
      );
      if (context.mounted) {
        _showImageSnack(context, result.message, Icons.share_rounded,
            const Color(0xFF25D366));
      }
    } catch (e) {
      final fallback =
          widget.isBase64 ? 'Gambar dibuat dengan KreaSea AI' : widget.imageUrl;
      await Clipboard.setData(ClipboardData(text: fallback));
      if (context.mounted) {
        _showImageSnack(
          context,
          'Share gagal. Info gambar disalin ke clipboard.',
          Icons.copy_rounded,
          const Color(0xFF25D366),
        );
      }
    }
  }

  void _showImageSnack(
      BuildContext context, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ]),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ── Smart image builder: base64 → Image.memory, URL → Image.network ──
  Widget _buildImageWidget() {
    final errorFallback = Container(
      height: 200,
      color: Colors.white.withOpacity(0.04),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported_rounded,
              color: Colors.white24, size: 48),
          const SizedBox(height: 8),
          const Text('Gagal memuat gambar',
              style: TextStyle(color: Colors.white30, fontSize: 12)),
          const SizedBox(height: 8),
          if (widget.onRegenerate != null)
            TextButton.icon(
              onPressed: widget.onRegenerate,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE91E63),
              ),
            ),
        ],
      ),
    );

    if (widget.isBase64) {
      // NVIDIA FLUX → Image.memory dari bytes
      final bytes = widget.imageBytes;
      if (bytes == null) return errorFallback;
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => errorFallback,
      );
    }

    // Pollinations fallback → Image.network
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        final progress = loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null;
        return Container(
          height: 280,
          color: Colors.white.withOpacity(0.04),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  color: const Color(0xFFE91E63),
                  backgroundColor: Colors.white12,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                progress != null
                    ? 'Loading ${(progress * 100).toInt()}%'
                    : 'Memuat gambar...',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        );
      },
      errorBuilder: (_, __, ___) => errorFallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              // ── Image ──
              GestureDetector(
                onTap: () => _viewFullscreen(context),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: _buildImageWidget(),
                    ),
                    // Fullscreen hint badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen_rounded,
                                color: Colors.white70, size: 16),
                            SizedBox(width: 2),
                            Text('Tap',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Prompt preview ──────────────────────────────
              if (widget.prompt.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.06))),
                  ),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 11, color: Colors.white24),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ]),
                ),

              // ── Action bar ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(children: [
                  Expanded(
                      child: _ImageActionBtn(
                    icon: Icons.fullscreen_rounded,
                    label: 'Fullscreen',
                    color: const Color(0xFF3D5AFE),
                    onTap: () => _viewFullscreen(context),
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _ImageActionBtn(
                    icon: Icons.download_rounded,
                    label: 'Unduh',
                    color: const Color(0xFF00BCD4),
                    onTap: () => _downloadImage(context),
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _ImageActionBtn(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    color: const Color(0xFF25D366),
                    onTap: () => _shareImage(context),
                  )),
                  if (widget.onRegenerate != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                        child: _ImageActionBtn(
                      icon: Icons.refresh_rounded,
                      label: 'Ulang',
                      color: const Color(0xFFE91E63),
                      onTap: widget.onRegenerate!,
                    )),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Helper Widgets
// ══════════════════════════════════════════════════════════════════

class _ActionChipNew extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChipNew({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _ImageActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImageActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer for AI result placeholder.
class AiResultShimmer extends StatefulWidget {
  const AiResultShimmer({super.key});

  @override
  State<AiResultShimmer> createState() => _AiResultShimmerState();
}

class _AiResultShimmerState extends State<AiResultShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(120, 14),
                const SizedBox(height: 14),
                _shimmerBox(double.infinity, 12),
                const SizedBox(height: 8),
                _shimmerBox(double.infinity, 12),
                const SizedBox(height: 8),
                _shimmerBox(220, 12),
                const SizedBox(height: 8),
                _shimmerBox(180, 12),
                const SizedBox(height: 18),
                Row(children: [
                  _shimmerBox(80, 30),
                  const SizedBox(width: 8),
                  _shimmerBox(80, 30),
                  const SizedBox(width: 8),
                  _shimmerBox(90, 30),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04 + 0.04 * _anim.value),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
