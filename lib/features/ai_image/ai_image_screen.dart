import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/stability_ai_service.dart';
import '../../services/gemini_service.dart';
import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';
import '../../widgets/credit_widgets.dart';

class AiImageScreen extends ConsumerStatefulWidget {
  const AiImageScreen({super.key});
  @override
  ConsumerState<AiImageScreen> createState() => _AiImageScreenState();
}

class _AiImageScreenState extends ConsumerState<AiImageScreen> {
  final _promptController = TextEditingController();

  String _selectedType = 'Square Post (1:1)';
  final _types = [
    'Square Post (1:1)',
    'Story (9:16)',
    'Banner (16:9)',
    'Portrait (3:4)',
    'Wide (21:9)',
  ];

  String? _selectedPurpose;
  final _purposes = [
    'Promo Diskon',
    'Pengumuman',
    'Testimoni',
    'Produk Showcase',
    'Quotes',
    'Menu / Katalog',
    'Event / Undangan',
    'Thumbnail Video',
    'Cover Highlight',
  ];

  String _selectedMood = 'Minimalis';
  final _moods = [
    'Minimalis',
    'Playful/Ceria',
    'Elegan/Mewah',
    'Vintage',
    'Futuristic',
    '3D Render',
    'Flat Design',
    'Neon Glow',
    'Watercolor',
    'Photography',
  ];

  String _selectedColor = 'Auto';
  final _colors = [
    'Auto',
    'Pastel',
    'Bold & Vibrant',
    'Monochrome',
    'Earth Tone',
    'Neon',
    'Gold & Luxury',
  ];

  bool _isLoading = false;
  String _loadingMessage = '';
  String? _resultImageBase64;
  String _enhancedPrompt = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creditServiceProvider).fetchCredits();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  String get _aspectRatio {
    if (_selectedType.contains('16:9')) return '16:9';
    if (_selectedType.contains('9:16')) return '9:16';
    if (_selectedType.contains('3:4')) return '3:4';
    if (_selectedType.contains('21:9')) return '21:9';
    return '1:1';
  }

  Future<void> _generate() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Jelaskan desain yang kamu inginkan'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final canProceed =
        await showCreditGuard(context, CreditType.image, ref);
    if (!canProceed || !mounted) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = '✨ Menyempurnakan prompt dengan Gemini AI...';
      _resultImageBase64 = null;
      _enhancedPrompt = '';
    });

    await ref.read(creditServiceProvider).useCredit(CreditType.image);

    try {
      // Step 1: Enhance prompt via Gemini
      final authState = ref.read(authStateProvider);
      final profile = authState.asData?.value ??
          UserProfile(
              uid: 'guest',
              email: '',
              businessName: 'UMKM Demo',
              businessType: 'Umum');

      final geminiService = ref.read(geminiServiceProvider);
      var colorHint =
          _selectedColor != 'Auto' ? ' Color palette: $_selectedColor.' : '';

      final enhanced = await geminiService.enhancePrompt(
        originalPrompt: '${_promptController.text}$colorHint',
        purpose: _selectedPurpose ?? 'General',
        mood: _selectedMood,
        businessName: profile.businessName,
        businessType: profile.businessType,
        businessDescription: profile.businessDescription,
      );

      if (mounted) {
        setState(() {
          _enhancedPrompt = enhanced;
          _loadingMessage =
              '🎨 Generating gambar (Pollinations AI)... biasanya 10-30 detik';
        });
      }

      // Step 2: Generate image via Pollinations.ai
      final service = ref.read(stabilityAiServiceProvider);
      final base64Image = await service.generateImage(
        prompt: enhanced,
        aspectRatio: _aspectRatio,
        stylePreset: _selectedMood,
      );

      if (mounted) setState(() => _resultImageBase64 = base64Image);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e',
              style: const TextStyle(fontSize: 12)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade900,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(slivers: [
        // ── HERO HEADER ─────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.surfaceDark,
          actions: [
            CreditBadge(
                type: CreditType.image,
                accentColor: const Color(0xFFE91E63)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Studio Desain AI',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            background: Stack(fit: StackFit.expand, children: [
              Image.asset(
                'assets/images/banner_ai_image.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.palette_rounded,
                        size: 60, color: Colors.white24),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.surfaceDark,
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── POWERED BY ──────────────────────────────
                GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFFF5722)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.palette_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Gemini AI menyempurnakan prompt → Pollinations AI generate gambar. Gratis & cepat!',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── KONSEP VISUAL ────────────────────────────
                _sectionTitle('🖼️ Konsep Visual'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassDropdown<String>(
                          label: 'Tujuan Visual',
                          value: _selectedPurpose,
                          onChanged: (v) =>
                              setState(() => _selectedPurpose = v),
                          items: _purposes
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(
                                          fontSize: 13))))
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        GlassFormField(
                          label: 'Deskripsi Visual (Prompt)',
                          hint:
                              'Misal: Kopi latte hangat di meja kayu rustic, suasana pagi...',
                          controller: _promptController,
                          maxLines: 4,
                        ),
                      ]),
                ),
                const SizedBox(height: 20),

                // ── FORMAT & GAYA ────────────────────────────
                _sectionTitle('🎨 Format & Gaya'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassChipGroup(
                            label: 'Ukuran / Rasio',
                            options: _types,
                            selected: _selectedType,
                            onSelected: (v) =>
                                setState(() => _selectedType = v)),
                        const SizedBox(height: 14),
                        GlassChipGroup(
                            label: 'Mood & Style',
                            options: _moods,
                            selected: _selectedMood,
                            onSelected: (v) =>
                                setState(() => _selectedMood = v)),
                        const SizedBox(height: 14),
                        GlassChipGroup(
                            label: 'Palet Warna',
                            options: _colors,
                            selected: _selectedColor,
                            onSelected: (v) =>
                                setState(() => _selectedColor = v)),
                      ]),
                ),
                const SizedBox(height: 24),

                // ── GENERATE BUTTON ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFFF5722)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generate,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.palette_rounded, size: 20),
                      label: Text(
                        _isLoading
                            ? 'Generating...'
                            : 'Generate Desain ✨',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── LOADING STATE ────────────────────────────
                if (_isLoading) ...[
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: Color(0xFFE91E63),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Harap tunggu... proses ini bisa 10-30 detik',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                ],

                // ── RESULT ──────────────────────────────────
                if (_resultImageBase64 != null) ...[
                  _sectionTitle('🖼️ Hasil Desain'),
                  const SizedBox(height: 12),
                  AiImageResultCard(
                    base64Image: _resultImageBase64!,
                    prompt: _enhancedPrompt,
                    onRegenerate: _isLoading ? null : _generate,
                    onSave: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tersimpan ke Library!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
}
