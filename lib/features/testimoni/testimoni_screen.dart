import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';

class TestimoniScreen extends ConsumerStatefulWidget {
  const TestimoniScreen({super.key});
  @override
  ConsumerState<TestimoniScreen> createState() => _TestimoniScreenState();
}

class _TestimoniScreenState extends ConsumerState<TestimoniScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _namaCtrl = TextEditingController();
  final _produkCtrl = TextEditingController();
  final _ulasanCtrl = TextEditingController();
  String _platform = 'Google Maps';
  int _rating = 5;
  String _estimasi = '2 hari lalu';
  String _channel = 'WhatsApp';
  bool _isLoading = false;
  List<String> _results = [];

  @override
  void initState() { super.initState(); _tabController = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); _namaCtrl.dispose(); _produkCtrl.dispose(); _ulasanCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Testimoni Generator', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accentLight,
          unselectedLabelColor: Colors.white38,
          indicatorColor: AppColors.accentLight,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '💬 Request Review'),
            Tab(text: '⭐ Respons Review'),
            Tab(text: '📦 Follow-up'),
            Tab(text: '🙏 Thank You'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildRequestReview(),
        _buildResponsReview(),
        _buildFollowUp(),
        _buildThankYou(),
      ]),
    );
  }

  // ── TAB 1: Request Review ──
  Widget _buildRequestReview() {
    return _buildTab(
      fields: [
        GlassFormField(label: 'Nama Pembeli (Opsional)', hint: 'Kosong = "Kak"', controller: _namaCtrl),
        const SizedBox(height: 14),
        GlassFormField(label: 'Nama Produk', hint: 'Contoh: Brownies Premium', controller: _produkCtrl),
        const SizedBox(height: 14),
        GlassChipGroup(label: 'Platform Ulasan', options: const ['Google Maps', 'Shopee', 'Tokopedia', 'Instagram'], selected: _platform, onSelected: (v) => setState(() => _platform = v)),
      ],
      onGenerate: () => _generate(
        system: 'Kamu adalah asisten komunikasi UMKM Indonesia yang ramah. Buat pesan WA meminta ulasan yang: sopan, tidak memaksa, singkat (max 3 paragraf), dan terasa personal bukan copy-paste massal.',
        user: 'Nama pembeli: ${_namaCtrl.text.isEmpty ? "Kak" : _namaCtrl.text}\nProduk: ${_produkCtrl.text}\nPlatform ulasan: $_platform\n\nBuat 2 variasi pesan dalam bahasa Indonesia. Pisahkan dengan ---VARIASI---',
      ),
    );
  }

  // ── TAB 2: Respons Review ──
  Widget _buildResponsReview() {
    return _buildTab(
      fields: [
        const Text('Rating Bintang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 6),
        Row(children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: Padding(padding: const EdgeInsets.only(right: 4),
            child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 32)),
        ))),
        const SizedBox(height: 14),
        GlassFormField(label: 'Isi Ulasan Pembeli', hint: 'Paste ulasan yang ingin dibalas...', controller: _ulasanCtrl, maxLines: 3),
      ],
      onGenerate: () => _generate(
        system: 'Buat respons profesional untuk ulasan ${_rating <= 2 ? "negatif" : _rating == 3 ? "netral" : "positif"} yang: empati, tidak defensif, ${_rating <= 2 ? "tawarkan solusi konkret" : "ucapan terima kasih"}, singkat (max 4 kalimat).',
        user: 'Rating: $_rating bintang\nUlasan pembeli: "${_ulasanCtrl.text}"\n\nBuat 2 variasi respons. Pisahkan dengan ---VARIASI---',
      ),
    );
  }

  // ── TAB 3: Follow-up ──
  Widget _buildFollowUp() {
    return _buildTab(
      fields: [
        GlassFormField(label: 'Nama Pembeli', hint: 'Contoh: Kak Sari', controller: _namaCtrl),
        const SizedBox(height: 14),
        GlassFormField(label: 'Nama Produk', hint: 'Contoh: Hampers Lebaran', controller: _produkCtrl),
        const SizedBox(height: 14),
        GlassChipGroup(label: 'Estimasi Diterima', options: const ['Baru saja', '1 hari lalu', '2 hari lalu', '3 hari lalu'], selected: _estimasi, onSelected: (v) => setState(() => _estimasi = v)),
      ],
      onGenerate: () => _generate(
        system: 'Kamu adalah asisten komunikasi UMKM Indonesia. Buat pesan follow-up WA untuk cek kepuasan pembeli. Singkat, personal, hangat.',
        user: 'Nama: ${_namaCtrl.text}\nProduk: ${_produkCtrl.text}\nEstimasi diterima: $_estimasi\n\nBuat 2 variasi pesan. Pisahkan dengan ---VARIASI---',
      ),
    );
  }

  // ── TAB 4: Thank You ──
  Widget _buildThankYou() {
    return _buildTab(
      fields: [
        GlassFormField(label: 'Nama Pembeli (Opsional)', hint: 'Kosong = "Kak"', controller: _namaCtrl),
        const SizedBox(height: 14),
        GlassFormField(label: 'Nama Produk', hint: 'Contoh: Kue Lapis', controller: _produkCtrl),
        const SizedBox(height: 14),
        GlassChipGroup(label: 'Channel Pembelian', options: const ['WhatsApp', 'Shopee', 'Tokopedia', 'Instagram', 'Offline'], selected: _channel, onSelected: (v) => setState(() => _channel = v)),
      ],
      onGenerate: () => _generate(
        system: 'Kamu adalah asisten komunikasi UMKM Indonesia. Buat pesan ucapan terima kasih setelah transaksi. Hangat, personal, ajak repeat order.',
        user: 'Nama: ${_namaCtrl.text.isEmpty ? "Kak" : _namaCtrl.text}\nProduk: ${_produkCtrl.text}\nChannel: $_channel\n\nBuat 2 variasi pesan. Pisahkan dengan ---VARIASI---',
      ),
    );
  }

  Widget _buildTab({required List<Widget> fields, required VoidCallback onGenerate}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...fields,
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: _isLoading ? null : onGenerate,
          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 18),
          label: Text(_isLoading ? 'Generating...' : 'Generate dengan AI ✨'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLight, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(height: 20),
        if (_isLoading) const AiResultShimmer(),
        ..._results.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AiResultCard(title: 'Variasi ${e.key + 1}', content: e.value, variantIndex: e.key + 1),
        )),
      ]),
    );
  }

  Future<void> _generate({required String system, required String user}) async {
    setState(() { _isLoading = true; _results = []; });
    try {
      final gemini = ref.read(geminiServiceProvider);
      final raw = await gemini.generateText(systemPrompt: system, userPrompt: user);
      final variants = raw.split('---VARIASI---').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (mounted) setState(() { _isLoading = false; _results = variants.isEmpty ? [raw] : variants; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
