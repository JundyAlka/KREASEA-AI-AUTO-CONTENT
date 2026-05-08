import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/stability_ai_service.dart';
import '../../services/gemini_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';

class AiImageScreen extends ConsumerStatefulWidget {
  const AiImageScreen({super.key});
  @override
  ConsumerState<AiImageScreen> createState() => _AiImageScreenState();
}

class _AiImageScreenState extends ConsumerState<AiImageScreen> {
  final _promptController = TextEditingController();

  String _selectedType = 'Square Post (1:1)';
  final _types = ['Square Post (1:1)', 'Story (9:16)', 'Banner (16:9)', 'Portrait (3:4)', 'Wide (21:9)'];

  String? _selectedPurpose;
  final _purposes = ['Promo Diskon', 'Pengumuman', 'Testimoni', 'Produk Showcase', 'Quotes', 'Menu / Katalog', 'Event / Undangan', 'Thumbnail Video', 'Cover Highlight'];

  String _selectedMood = 'Minimalis';
  final _moods = ['Minimalis', 'Playful/Ceria', 'Elegan/Mewah', 'Vintage', 'Futuristic', '3D Render', 'Flat Design', 'Neon Glow', 'Watercolor', 'Photography'];

  String _selectedColor = 'Auto';
  final _colors = ['Auto', 'Pastel', 'Bold & Vibrant', 'Monochrome', 'Earth Tone', 'Neon', 'Gold & Luxury'];

  bool _isLoading = false;
  String _loadingMessage = '';
  String? _resultImageBase64;
  double _creditBalance = 0.0;

  @override
  void initState() { super.initState(); _fetchBalance(); }

  Future<void> _fetchBalance() async {
    try {
      final balance = await ref.read(stabilityAiServiceProvider).getBalance();
      if (mounted) setState(() => _creditBalance = balance);
    } catch (e) { debugPrint('Failed to load credits: $e'); }
  }

  Future<void> _generate() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jelaskan desain yang kamu inginkan'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_creditBalance < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credit tidak mencukupi (Butuh min. 2 credit)'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() { _isLoading = true; _loadingMessage = 'Meracik prompt ajaib dengan Gemini AI... ✨'; _resultImageBase64 = null; });
    try {
      final authState = ref.read(authStateProvider);
      final profile = authState.asData?.value ?? UserProfile(uid: 'guest', email: '', businessName: 'UMKM Demo', businessType: 'Umum');
      final geminiService = ref.read(geminiServiceProvider);
      var colorHint = _selectedColor != 'Auto' ? ' Color palette: $_selectedColor.' : '';
      final enhancedPrompt = await geminiService.enhancePrompt(
        originalPrompt: '${_promptController.text}$colorHint',
        purpose: _selectedPurpose ?? 'General',
        mood: _selectedMood,
        businessName: profile.businessName,
        businessType: profile.businessType,
        businessDescription: profile.businessDescription,
      );
      if (mounted) setState(() { _loadingMessage = 'Generating gambar (Stability AI)... 🎨'; });
      String aspectRatio = '1:1';
      if (_selectedType.contains('16:9')) aspectRatio = '16:9';
      if (_selectedType.contains('9:16')) aspectRatio = '9:16';
      if (_selectedType.contains('3:4')) aspectRatio = '3:4';
      if (_selectedType.contains('21:9')) aspectRatio = '21:9';
      final service = ref.read(stabilityAiServiceProvider);
      final base64Image = await service.generateImage(prompt: enhancedPrompt, aspectRatio: aspectRatio, stylePreset: _selectedMood);
      setState(() => _resultImageBase64 = base64Image);
      _fetchBalance();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(slivers: [
        // ── HERO HEADER ──
        SliverAppBar(
          expandedHeight: 180, floating: false, pinned: true,
          backgroundColor: AppColors.surfaceDark,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
              child: Row(children: [
                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('Credits: ${_creditBalance.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
              ]),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Studio Desain AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            background: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/banner_ai_image.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5722)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: const Center(child: Icon(Icons.palette_rounded, size: 60, color: Colors.white24)),
              )),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.surfaceDark]))),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── POWERED BY ──
          GlassContainer(padding: const EdgeInsets.all(14), child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5722)]), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.palette_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Powered by Gemini + Stability AI. Prompt Anda akan disempurnakan otomatis!', style: TextStyle(color: Colors.white70, fontSize: 11))),
          ])),
          const SizedBox(height: 20),

          // ── SECTION: Konsep Visual ──
          _sectionTitle('🖼️ Konsep Visual'),
          const SizedBox(height: 12),
          GlassContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GlassDropdown<String>(label: 'Tujuan Visual', value: _selectedPurpose, onChanged: (v) => setState(() => _selectedPurpose = v),
              items: _purposes.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList()),
            const SizedBox(height: 14),
            GlassFormField(label: 'Deskripsi Visual (Prompt)', hint: 'Misal: Kopi latte hangat di meja kayu rustic, pencahayaan pagi...', controller: _promptController, maxLines: 4),
          ])),
          const SizedBox(height: 20),

          // ── SECTION: Format & Gaya ──
          _sectionTitle('🎨 Format & Gaya'),
          const SizedBox(height: 12),
          GlassContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GlassChipGroup(label: 'Ukuran / Rasio', options: _types, selected: _selectedType, onSelected: (v) => setState(() => _selectedType = v)),
            const SizedBox(height: 14),
            GlassChipGroup(label: 'Mood & Style', options: _moods, selected: _selectedMood, onSelected: (v) => setState(() => _selectedMood = v)),
            const SizedBox(height: 14),
            GlassChipGroup(label: 'Palet Warna', options: _colors, selected: _selectedColor, onSelected: (v) => setState(() => _selectedColor = v)),
          ])),
          const SizedBox(height: 24),

          // ── GENERATE BUTTON ──
          SizedBox(width: double.infinity, height: 52, child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5722)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.palette_rounded, size: 20),
              label: Text(_isLoading ? _loadingMessage : 'Generate Desain ✨', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          )),
          const SizedBox(height: 20),

          // ── LOADING ──
          if (_isLoading) ...[
            GlassContainer(padding: const EdgeInsets.all(20), child: Column(children: [
              const CircularProgressIndicator(color: AppColors.accentLight),
              const SizedBox(height: 12),
              Text(_loadingMessage, style: const TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
            ])),
          ],

          // ── RESULT ──
          if (_resultImageBase64 != null) ...[
            _sectionTitle('🖼️ Hasil Desain'),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Column(children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.memory(base64Decode(_resultImageBase64!), fit: BoxFit.cover, width: double.infinity)),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
                  child: Row(children: [
                    Expanded(child: _glassActionButton(Icons.download_rounded, 'Download', () {})),
                    const SizedBox(width: 10),
                    Expanded(child: _glassActionButton(Icons.share_rounded, 'Bagikan', () {})),
                    const SizedBox(width: 10),
                    Expanded(child: _glassActionButton(Icons.bookmark_add_rounded, 'Simpan', () {})),
                  ]),
                ),
              ]),
            )),
          ],
        ]))),
      ]),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));

  Widget _glassActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Column(children: [
          Icon(icon, color: AppColors.accentLight, size: 18),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
