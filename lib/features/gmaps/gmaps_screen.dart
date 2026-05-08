import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';

class GmapsScreen extends ConsumerStatefulWidget {
  const GmapsScreen({super.key});
  @override
  ConsumerState<GmapsScreen> createState() => _GmapsScreenState();
}

class _GmapsScreenState extends ConsumerState<GmapsScreen> {
  final _namaCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _produkCtrl = TextEditingController();
  final _keunikanCtrl = TextEditingController();
  String _jenis = 'F&B - Makanan & Minuman';
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Optimasi Google Maps', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hero info
          GlassContainer(padding: const EdgeInsets.all(14), child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.map_rounded, color: Color(0xFF4285F4), size: 22)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Optimalkan profil Google Bisnisku untuk meningkatkan visibilitas pencarian lokal.', style: TextStyle(color: Colors.white60, fontSize: 11))),
          ])),
          const SizedBox(height: 16),
          GlassFormField(label: 'Nama Usaha', hint: 'Contoh: Kue Ibu Sari', controller: _namaCtrl),
          const SizedBox(height: 14),
          GlassDropdown<String>(label: 'Jenis Usaha', value: _jenis, onChanged: (v) => setState(() => _jenis = v!), items: const [
            DropdownMenuItem(value: 'F&B - Makanan & Minuman', child: Text('F&B - Makanan & Minuman')),
            DropdownMenuItem(value: 'Fashion & Pakaian', child: Text('Fashion & Pakaian')),
            DropdownMenuItem(value: 'Jasa & Layanan', child: Text('Jasa & Layanan')),
            DropdownMenuItem(value: 'Retail & Toko', child: Text('Retail & Toko')),
            DropdownMenuItem(value: 'Kecantikan & Kesehatan', child: Text('Kecantikan & Kesehatan')),
            DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
          ]),
          const SizedBox(height: 14),
          GlassFormField(label: 'Lokasi (Kota/Kecamatan)', hint: 'Contoh: Sleman, Yogyakarta', controller: _lokasiCtrl),
          const SizedBox(height: 14),
          GlassFormField(label: 'Produk/Jasa Utama', hint: 'Apa yang paling dicari?', controller: _produkCtrl, maxLength: 100),
          const SizedBox(height: 14),
          GlassFormField(label: 'Keunikan Usaha', hint: 'Apa yang membedakan dari kompetitor?', controller: _keunikanCtrl, maxLength: 150),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _generate,
            icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(_isLoading ? 'Menganalisis...' : 'Optimasi Profil GMaps ✨'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 20),
          if (_isLoading) ...[const AiResultShimmer(), const SizedBox(height: 12), const AiResultShimmer()],
          if (_result != null) _buildResults(),
        ]),
      ),
    );
  }

  Widget _buildResults() {
    final r = _result!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Nama Rekomendasi
      if (r['nama_rekomendasi'] != null) ...[
        const Text('📍 Nama GMaps Rekomendasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        ...(r['nama_rekomendasi'] as List).map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AiResultCard(title: n['nama'] ?? '', content: n['alasan'] ?? '', accentColor: const Color(0xFF4285F4)),
        )),
        const SizedBox(height: 16),
      ],
      // Deskripsi
      if (r['deskripsi_bisnis'] != null) ...[
        const Text('📝 Deskripsi Bisnis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        AiResultCard(title: 'Siap copy-paste ke GMaps', content: r['deskripsi_bisnis']),
        const SizedBox(height: 16),
      ],
      // Kata Kunci
      if (r['kata_kunci'] != null) ...[
        const Text('🔑 Kata Kunci Utama', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: (r['kata_kunci'] as List).map((k) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.3))),
          child: Text(k, style: const TextStyle(color: Color(0xFF4285F4), fontSize: 12, fontWeight: FontWeight.w600)),
        )).toList()),
        const SizedBox(height: 16),
      ],
      // Kategori
      if (r['kategori_utama'] != null) ...[
        const Text('📂 Kategori GMaps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        GlassContainer(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 16), const SizedBox(width: 6), Text('Utama: ${r['kategori_utama']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]),
          if (r['kategori_tambahan'] != null) ...[
            const SizedBox(height: 6),
            ...(r['kategori_tambahan'] as List).map((k) => Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [const Icon(Icons.add_circle_outline, color: Colors.white38, size: 14), const SizedBox(width: 6), Text(k, style: const TextStyle(color: Colors.white60, fontSize: 12))]))),
          ],
        ])),
        const SizedBox(height: 16),
      ],
      // Q&A Template
      if (r['qa_template'] != null) ...[
        const Text('❓ Template Q&A', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        ...(r['qa_template'] as List).map((qa) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AiResultCard(title: 'Q: ${qa['pertanyaan'] ?? ''}', content: 'A: ${qa['jawaban'] ?? ''}', accentColor: const Color(0xFF38EF7D)),
        )),
      ],
    ]);
  }

  Future<void> _generate() async {
    if (_namaCtrl.text.isEmpty) return;
    setState(() { _isLoading = true; _result = null; });
    final gemini = ref.read(geminiServiceProvider);
    final result = await gemini.generateJson(
      systemPrompt: 'Kamu adalah ahli SEO lokal dan Google My Business untuk UMKM Indonesia. Selalu output valid JSON.',
      userPrompt: '''Bantu optimalkan profil Google Maps untuk usaha:
- Nama: ${_namaCtrl.text}
- Jenis: $_jenis
- Lokasi: ${_lokasiCtrl.text}
- Produk utama: ${_produkCtrl.text}
- Keunikan: ${_keunikanCtrl.text}

Output JSON:
{"nama_rekomendasi": [{"nama": "...", "alasan": "..."}, ...3 item], "deskripsi_bisnis": "150-200 kata", "kata_kunci": ["...", "...", "...", "...", "..."], "kategori_utama": "...", "kategori_tambahan": ["...", "..."], "qa_template": [{"pertanyaan": "...", "jawaban": "..."}, ...5 item]}''',
    );
    setState(() { _isLoading = false; _result = result.containsKey('error') ? null : result; });
  }
}
