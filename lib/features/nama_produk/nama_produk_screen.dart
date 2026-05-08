import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';

class NamaProdukScreen extends ConsumerStatefulWidget {
  const NamaProdukScreen({super.key});
  @override
  ConsumerState<NamaProdukScreen> createState() => _NamaProdukScreenState();
}

class _NamaProdukScreenState extends ConsumerState<NamaProdukScreen> {
  final _deskripsiCtrl = TextEditingController();
  final _hindariCtrl = TextEditingController();
  String _target = 'Anak Muda';
  String _tone = 'Simple & Modern';
  String _bahasa = 'Indonesia';
  bool _isLoading = false;
  List<Map<String, dynamic>> _names = [];
  List<String> _taglines = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Nama Produk AI', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GlassFormField(label: 'Deskripsi Produk', hint: 'Apa produknya, bahan utama, keunggulan...', controller: _deskripsiCtrl, maxLines: 3, maxLength: 200),
          const SizedBox(height: 14),
          GlassChipGroup(label: 'Target Audiens', options: const ['Anak Muda', 'Ibu Rumah Tangga', 'Profesional', 'Semua Umur'], selected: _target, onSelected: (v) => setState(() => _target = v)),
          const SizedBox(height: 14),
          GlassChipGroup(label: 'Tone / Karakter', options: const ['Simple & Modern', 'Elegan & Premium', 'Lucu & Playful', 'Lokal & Hangat'], selected: _tone, onSelected: (v) => setState(() => _tone = v)),
          const SizedBox(height: 14),
          GlassChipGroup(label: 'Bahasa', options: const ['Indonesia', 'Inggris', 'Mix'], selected: _bahasa, onSelected: (v) => setState(() => _bahasa = v)),
          const SizedBox(height: 14),
          GlassFormField(label: 'Hindari Kata (Opsional)', hint: 'Kata yang tidak ingin ada di nama', controller: _hindariCtrl),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _generate,
            icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(_isLoading ? 'Generating...' : 'Generate Nama & Tagline ✨'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLight, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(height: 20),
          if (_isLoading) ...[const AiResultShimmer(), const SizedBox(height: 12), const AiResultShimmer()],
          if (_taglines.isNotEmpty) ...[
            const Text('Tagline Rekomendasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            ...(_taglines.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: AiResultCard(title: '✨ Tagline', content: t, accentColor: const Color(0xFFE040FB))))),
            const SizedBox(height: 16),
          ],
          if (_names.isNotEmpty) ...[
            const Text('Nama Produk Rekomendasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            ..._names.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NameCard(index: e.key + 1, data: e.value),
            )),
          ],
        ]),
      ),
    );
  }

  Future<void> _generate() async {
    if (_deskripsiCtrl.text.isEmpty) return;
    setState(() { _isLoading = true; _names = []; _taglines = []; });
    final gemini = ref.read(geminiServiceProvider);
    final result = await gemini.generateJson(
      systemPrompt: 'Kamu adalah brand naming specialist untuk produk UMKM Indonesia. Selalu output valid JSON.',
      userPrompt: '''Produk: ${_deskripsiCtrl.text}
Target: $_target
Tone: $_tone
Bahasa: $_bahasa
Hindari: ${_hindariCtrl.text.isEmpty ? "tidak ada" : _hindariCtrl.text}

Buat 10 nama produk unik dan 3 tagline. Output JSON:
{"nama": [{"nama": "...", "alasan": "...", "skor_ingat": 4, "skor_unik": 5}], "tagline": ["...", "...", "..."]}''',
    );
    setState(() {
      _isLoading = false;
      if (result.containsKey('nama')) {
        _names = List<Map<String, dynamic>>.from(result['nama']);
      }
      if (result.containsKey('tagline')) {
        _taglines = List<String>.from(result['tagline']);
      }
    });
  }
}

class _NameCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  const _NameCard({required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    final skorIngat = (data['skor_ingat'] ?? 3) as num;
    final skorUnik = (data['skor_unik'] ?? 3) as num;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 26, height: 26, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.grad1, AppColors.grad2]), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 10),
            Expanded(child: Text(data['nama'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
          ]),
          const SizedBox(height: 8),
          Text(data['alasan'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
          const SizedBox(height: 10),
          Row(children: [
            _ScoreBadge(label: 'Ingat', score: skorIngat.toInt(), color: const Color(0xFF38EF7D)),
            const SizedBox(width: 8),
            _ScoreBadge(label: 'Unik', score: skorUnik.toInt(), color: const Color(0xFF7C4DFF)),
          ]),
        ]),
      )),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label; final int score; final Color color;
  const _ScoreBadge({required this.label, required this.score, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: TextStyle(color: color, fontSize: 10)),
        ...List.generate(5, (i) => Icon(i < score ? Icons.star_rounded : Icons.star_outline_rounded, size: 11, color: color)),
      ]),
    );
  }
}
