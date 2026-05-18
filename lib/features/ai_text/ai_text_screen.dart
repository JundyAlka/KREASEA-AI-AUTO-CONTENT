import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_text_service.dart';
import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../services/gemini_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';
import '../../widgets/credit_widgets.dart';

class AiTextScreen extends ConsumerStatefulWidget {
  const AiTextScreen({super.key});
  @override
  ConsumerState<AiTextScreen> createState() => _AiTextScreenState();
}

class _AiTextScreenState extends ConsumerState<AiTextScreen> {
  final _productController = TextEditingController();
  final _hashtagController = TextEditingController();

  String? _selectedPurpose;
  final _purposes = ['Promo Diskon', 'Launching Produk', 'Edukasi', 'Testimoni', 'Reminder', 'Hiburan', 'Giveaway', 'Behind the Scenes', 'Tips & Trik', 'Seasonal / Hari Besar'];

  String? _selectedPlatform;
  final _platforms = ['Instagram Feed', 'Instagram Story', 'Instagram Reels', 'TikTok', 'WhatsApp Status', 'Facebook', 'Twitter/X', 'Threads'];

  String _selectedTone = 'Santai';
  final _tones = ['Formal', 'Santai', 'Gen Z', 'Premium', "Syar'i", 'Lucu', 'Inspiratif', 'Storytelling', 'Persuasif'];

  String _selectedLength = 'Sedang';
  final _lengths = ['Pendek', 'Sedang', 'Panjang'];

  String _selectedLanguage = 'Indonesia';
  final _languages = ['Indonesia', 'Inggris', 'Mix (ID+EN)', 'Sunda', 'Jawa'];

  bool _useEmoji = true;
  bool _useCTA = true;
  bool _isLoading = false;
  List<String> _results = [];

  Future<void> _generate() async {
    if (_productController.text.isEmpty || _selectedPurpose == null || _selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi form utama'), behavior: SnackBarBehavior.floating));
      return;
    }

    // ── Cek & kurangi credit caption ─────────────────────
    final canProceed = await showCreditGuard(context, CreditType.caption, ref);
    if (!canProceed || !mounted) return;

    setState(() { _isLoading = true; _results = []; });
    await ref.read(creditServiceProvider).useCredit(CreditType.caption);

    try {
      final authService = ref.read(authServiceProvider);
      final userProfile = authService.currentUser ?? UserProfile(uid: 'demo', email: 'demo@mail.com', businessName: 'Bisnis Demo', targetAudience: 'Umum');
      final service = ref.read(aiTextServiceProvider);
      var promptProduct = _productController.text;
      if (_hashtagController.text.isNotEmpty) promptProduct += " (Hashtags: ${_hashtagController.text})";
      if (_useEmoji) promptProduct += " (Gunakan Emoji)";
      if (_useCTA) promptProduct += " (Sertakan Call-to-Action)";
      promptProduct += " (Bahasa: $_selectedLanguage)";
      final captions = await service.generateCaptions(
        userProfile: userProfile,
        purpose: _selectedPurpose!,
        platform: _selectedPlatform!,
        productName: promptProduct,
        tone: _selectedTone,
        length: _selectedLength,
        useEmoji: _useEmoji,
        useCTA: _useCTA,
      );
      setState(() => _results = captions);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final isKeyError = msg.contains('quota') || msg.contains('429') ||
          msg.contains('rate') || msg.contains('invalid') ||
          msg.contains('tidak valid') || msg.contains('cooldown') ||
          msg.contains('semua');

      if (isKeyError) {
        _showAiErrorDialog(e.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontSize: 12)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Improve caption (tanpa kurangi credit) ─────────────────
  Future<String?> _improveCaption(String currentText) async {
    final gemini = ref.read(geminiServiceProvider);
    return await gemini.generateText(
      systemPrompt:
          'Kamu adalah copywriter UMKM Indonesia profesional. '
          'Tugas: perbaiki dan tingkatkan kualitas caption media sosial yang diberikan. '
          'Buat lebih menarik, persuasif, dan sesuai untuk bisnis UMKM Indonesia. '
          'Pertahankan tone dan tujuan aslinya. '
          'Output HANYA caption yang sudah diperbaiki, tanpa penjelasan.',
      userPrompt: 'Improve caption ini:\n\n$currentText',
      temperature: 0.8,
    );
  }

  void _showAiErrorDialog(String errorMessage) {
    final isAllInvalid = errorMessage.toLowerCase().contains('semua') &&
        errorMessage.toLowerCase().contains('tidak valid');
    final isQuota = errorMessage.toLowerCase().contains('quota') ||
        errorMessage.toLowerCase().contains('cooldown') ||
        errorMessage.toLowerCase().contains('429');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAllInvalid ? 'API Key Tidak Valid' : 'AI Sedang Sibuk',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isAllInvalid
                            ? 'Semua key sudah expired'
                            : 'Quota gratis habis hari ini',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 Cara Atasi:',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    if (isAllInvalid) ...[
                      _step('1', 'Buka aistudio.google.com/app/apikey'),
                      _step('2', 'Buat API key baru (gratis)'),
                      _step('3', 'Update GEMINI_KEY_1 di file .env'),
                      _step('4', 'Restart aplikasi'),
                    ] else ...[
                      _step('1', 'Tunggu hingga besok (reset 00:00 WIB)'),
                      _step('2', 'ATAU tambah API key baru di .env'),
                      _step('3',
                          'Buka aistudio.google.com/app/apikey (gratis)'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AFE).withOpacity(0.15),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mengerti',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF3D5AFE).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
        ]),
      );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(slivers: [
        // ── HERO HEADER ──
        SliverAppBar(
          expandedHeight: 180,
          floating: false, pinned: true,
          backgroundColor: AppColors.surfaceDark,
          actions: [
            CreditBadge(type: CreditType.caption, accentColor: const Color(0xFF3D5AFE)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Buat Caption AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            background: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/banner_ai_text.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: const Center(child: Icon(Icons.auto_awesome_rounded, size: 60, color: Colors.white24)),
              )),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.surfaceDark]))),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── POWERED BY ──
          GlassContainer(padding: const EdgeInsets.all(14), child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.grad1, AppColors.grad2]), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Powered by Gemini AI. Ketik ide simpel, AI akan mempercantiknya!', style: TextStyle(color: Colors.white70, fontSize: 11))),
          ])),
          const SizedBox(height: 20),

          // ── SECTION: Detail Konten ──
          _sectionTitle('📝 Detail Konten'),
          const SizedBox(height: 12),
          GlassContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GlassDropdown<String>(label: 'Tujuan Konten', value: _selectedPurpose, onChanged: (v) => setState(() => _selectedPurpose = v),
              items: _purposes.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList()),
            const SizedBox(height: 14),
            GlassDropdown<String>(label: 'Platform Target', value: _selectedPlatform, onChanged: (v) => setState(() => _selectedPlatform = v),
              items: _platforms.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList()),
            const SizedBox(height: 14),
            GlassFormField(label: 'Produk / Topik Utama', hint: 'Jelaskan produk atau topik yang ingin dibahas...', controller: _productController, maxLines: 3),
          ])),
          const SizedBox(height: 20),

          // ── SECTION: Preferensi & Gaya ──
          _sectionTitle('🎨 Preferensi & Gaya'),
          const SizedBox(height: 12),
          GlassContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GlassChipGroup(label: 'Gaya Bahasa (Tone)', options: _tones, selected: _selectedTone, onSelected: (v) => setState(() => _selectedTone = v)),
            const SizedBox(height: 14),
            GlassChipGroup(label: 'Panjang Caption', options: _lengths, selected: _selectedLength, onSelected: (v) => setState(() => _selectedLength = v)),
            const SizedBox(height: 14),
            GlassChipGroup(label: 'Bahasa', options: _languages, selected: _selectedLanguage, onSelected: (v) => setState(() => _selectedLanguage = v)),
            const SizedBox(height: 14),
            GlassFormField(label: 'Hashtags (Opsional)', hint: '#jualan #promo #umkm', controller: _hashtagController, prefix: const Icon(Icons.tag_rounded, size: 18, color: Colors.white38)),
            const SizedBox(height: 14),
            // Toggles
            Row(children: [
              Expanded(child: _toggleCard('Emoji 😊', _useEmoji, (v) => setState(() => _useEmoji = v))),
              const SizedBox(width: 10),
              Expanded(child: _toggleCard('CTA 🎯', _useCTA, (v) => setState(() => _useCTA = v))),
            ]),
          ])),
          const SizedBox(height: 24),

          // ── GENERATE BUTTON ──
          SizedBox(width: double.infinity, height: 52, child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFF3D5AFE).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 20),
              label: Text(_isLoading ? 'Generating...' : 'Generate Caption Ajaib ✨', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          )),
          const SizedBox(height: 20),

          // ── RESULTS ──
          if (_isLoading) ...List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: AiResultShimmer())),
          if (_results.isNotEmpty) ...[
            _sectionTitle('✨ Hasil Caption'),
            const SizedBox(height: 12),
            ..._results.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AiResultCard(
                title: 'Caption ${e.key + 1}',
                content: e.value,
                variantIndex: e.key + 1,
                accentColor: const Color(0xFF3D5AFE),
                onRegenerate: _isLoading ? null : _generate,
                onImprove: _improveCaption,
                onSave: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tersimpan ke Library!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            )),
          ],
        ]))),
      ]),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));

  Widget _toggleCard(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: value ? AppColors.accentLight.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? AppColors.accentLight.withOpacity(0.3) : Colors.white.withOpacity(0.08)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(value ? Icons.check_circle_rounded : Icons.circle_outlined, size: 16, color: value ? AppColors.accentLight : Colors.white24),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: value ? AppColors.accentLight : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
