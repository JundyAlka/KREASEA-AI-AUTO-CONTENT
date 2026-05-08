import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';

class BalasanDmScreen extends ConsumerStatefulWidget {
  const BalasanDmScreen({super.key});
  @override
  ConsumerState<BalasanDmScreen> createState() => _BalasanDmScreenState();
}

class _BalasanDmScreenState extends ConsumerState<BalasanDmScreen> {
  final _pesanCtrl = TextEditingController();
  final _konteksCtrl = TextEditingController();
  String _platform = 'Instagram DM';
  bool _isLoading = false;
  String _kategori = '';
  List<String> _balasan = [];
  String _tips = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Balasan DM AI', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassContainer(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE040FB).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.quickreply_rounded, color: Color(0xFFE040FB), size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Text('Paste pesan masuk → AI deteksi kategori & generate balasan profesional.', style: TextStyle(color: Colors.white60, fontSize: 11))),
        ])),
        const SizedBox(height: 16),
        GlassChipGroup(label: 'Platform', options: const ['Instagram DM', 'IG Komentar', 'WhatsApp', 'TikTok Komentar'], selected: _platform, onSelected: (v) => setState(() => _platform = v)),
        const SizedBox(height: 14),
        GlassFormField(label: 'Isi Pesan Masuk', hint: 'Paste atau ketik pesan yang diterima...', controller: _pesanCtrl, maxLines: 4),
        const SizedBox(height: 14),
        GlassFormField(label: 'Konteks Tambahan (Opsional)', hint: 'Info tambahan: harga, stok, dll', controller: _konteksCtrl, maxLines: 2),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _generate,
          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 18),
          label: Text(_isLoading ? 'Menganalisis...' : 'Generate Balasan AI ✨'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE040FB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(height: 20),
        if (_isLoading) ...[const AiResultShimmer(), const SizedBox(height: 12), const AiResultShimmer()],
        if (_kategori.isNotEmpty) ...[
          GlassContainer(padding: const EdgeInsets.all(14), child: Row(children: [
            const Icon(Icons.category_rounded, color: Color(0xFFE040FB), size: 18),
            const SizedBox(width: 8),
            Text('Kategori: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE040FB).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(_kategori, style: const TextStyle(color: Color(0xFFE040FB), fontWeight: FontWeight.bold, fontSize: 12))),
          ])),
          const SizedBox(height: 14),
          ..._balasan.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: AiResultCard(title: 'Balasan ${e.key + 1}', content: e.value, variantIndex: e.key + 1, accentColor: const Color(0xFFE040FB)))),
          if (_tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            GlassContainer(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('💡 Tips', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_tips, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ])),
            ])),
          ],
        ],
      ])),
    );
  }

  Future<void> _generate() async {
    if (_pesanCtrl.text.isEmpty) return;
    setState(() { _isLoading = true; _kategori = ''; _balasan = []; _tips = ''; });
    final gemini = ref.read(geminiServiceProvider);
    final result = await gemini.generateJson(
      systemPrompt: 'Kamu adalah asisten komunikasi untuk toko UMKM. Buat balasan yang: singkat (max 3 kalimat), profesional, dan selalu ada call-to-action yang relevan. Selalu output valid JSON.',
      userPrompt: 'Platform: $_platform\nPesan masuk: "${_pesanCtrl.text}"\nKonteks: ${_konteksCtrl.text.isEmpty ? "tidak ada" : _konteksCtrl.text}\n\nDeteksi kategori pesan, lalu buat 2 variasi balasan.\nOutput JSON: {"kategori": "...", "balasan": ["...", "..."], "tips": "satu tips singkat"}',
    );
    setState(() {
      _isLoading = false;
      _kategori = result['kategori']?.toString() ?? '';
      _balasan = result['balasan'] != null ? List<String>.from(result['balasan']) : [];
      _tips = result['tips']?.toString() ?? '';
    });
  }
}
