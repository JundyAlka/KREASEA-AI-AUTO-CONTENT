import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';

class ContentCalendarScreen extends ConsumerStatefulWidget {
  const ContentCalendarScreen({super.key});
  @override
  ConsumerState<ContentCalendarScreen> createState() => _ContentCalendarScreenState();
}

class _ContentCalendarScreenState extends ConsumerState<ContentCalendarScreen> {
  final _produkCtrl = TextEditingController();
  String _durasi = '7 hari';
  String _frekuensi = '1x/hari';
  final Set<String> _platforms = {'Instagram'};
  final Set<String> _fokus = {'Promosi produk'};
  bool _isLoading = false;
  List<Map<String, dynamic>> _calendar = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Content Calendar AI', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassContainer(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFF59E0B), size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Text('AI generate jadwal konten lengkap dengan topik, caption, dan waktu posting optimal.', style: TextStyle(color: Colors.white60, fontSize: 11))),
        ])),
        const SizedBox(height: 16),
        GlassChipGroup(label: 'Durasi', options: const ['7 hari', '14 hari', '30 hari'], selected: _durasi, onSelected: (v) => setState(() => _durasi = v)),
        const SizedBox(height: 14),
        GlassChipGroup(label: 'Frekuensi Posting', options: const ['1x/hari', '2x/hari', 'Hari kerja saja'], selected: _frekuensi, onSelected: (v) => setState(() => _frekuensi = v)),
        const SizedBox(height: 14),
        _multiSelectChips('Platform', ['Instagram', 'TikTok', 'Facebook', 'WhatsApp'], _platforms),
        const SizedBox(height: 14),
        _multiSelectChips('Fokus Konten', ['Promosi produk', 'Edukasi', 'Behind the scenes', 'Testimoni', 'Hari besar'], _fokus),
        const SizedBox(height: 14),
        GlassFormField(label: 'Produk Highlight (Opsional)', hint: 'Produk yang ingin difokuskan', controller: _produkCtrl),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _generate,
          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 18),
          label: Text(_isLoading ? 'Generating Calendar...' : 'Generate Calendar ✨'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(height: 20),
        if (_isLoading) ...List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: AiResultShimmer())),
        if (_calendar.isNotEmpty) ...[
          Text('📅 Jadwal ${_calendar.length} Hari', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          ..._calendar.asMap().entries.map((e) => _CalendarCard(index: e.key, data: e.value)),
        ],
      ])),
    );
  }

  Widget _multiSelectChips(String label, List<String> options, Set<String> selected) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: options.map((opt) {
        final isSel = selected.contains(opt);
        return GestureDetector(
          onTap: () => setState(() { isSel ? selected.remove(opt) : selected.add(opt); }),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isSel ? const LinearGradient(colors: [AppColors.grad1, AppColors.grad2]) : null,
              color: isSel ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? Colors.transparent : Colors.white.withOpacity(0.1))),
            child: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.white54, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal))),
        );
      }).toList()),
    ]);
  }

  Future<void> _generate() async {
    setState(() { _isLoading = true; _calendar = []; });
    final d = int.tryParse(_durasi.replaceAll(RegExp(r'[^0-9]'), '')) ?? 7;
    final gemini = ref.read(geminiServiceProvider);
    final raw = await gemini.generateText(
      systemPrompt: 'Kamu adalah social media strategist untuk UMKM Indonesia. Generate rencana konten. Rules: Mix konten 40% promosi, 30% edukasi, 20% engagement, 10% behind the scenes. Perhatikan hari besar Indonesia. Waktu posting optimal: Instagram 07.00/12.00/19.00, TikTok 19.00/21.00. Selalu output valid JSON array.',
      userPrompt: 'Generate jadwal konten $d hari.\nFrekuensi: $_frekuensi\nPlatform: ${_platforms.join(", ")}\nFokus: ${_fokus.join(", ")}\nProduk highlight: ${_produkCtrl.text.isEmpty ? "tidak ada" : _produkCtrl.text}\nTanggal mulai: ${DateTime.now().toString().substring(0, 10)}\n\nOutput JSON array: [{"tanggal":"2026-05-06","hari":"Rabu","tipe_konten":"Reels","topik":"...","hook":"...","caption_draft":"max 100 kata","hashtag":["..."],"waktu_posting":"19:00","platform":"Instagram"}]',
    );
    try {
      String cleaned = raw;
      if (cleaned.contains('```json')) cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();
      else if (cleaned.contains('```')) cleaned = cleaned.replaceAll('```', '').trim();
      final list = jsonDecode(cleaned);
      if (list is List) {
        setState(() => _calendar = List<Map<String, dynamic>>.from(list));
      }
    } catch (e) {
      debugPrint('Calendar parse error: $e');
    }
    setState(() => _isLoading = false);
  }
}

class _CalendarCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  const _CalendarCard({required this.index, required this.data});
  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final color = _platformColor(d['platform'] ?? '');
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('${widget.index + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d['hari'] ?? ''}, ${d['tanggal'] ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Text(d['topik'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(d['tipe_konten'] ?? '', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 10),
            if (d['hook'] != null) Text('🎯 ${d['hook']}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text(d['caption_draft'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text(d['waktu_posting'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              const SizedBox(width: 12),
              Icon(Icons.tag_rounded, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Expanded(child: Text((d['hashtag'] as List?)?.join(' ') ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10), overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ]),
      ))),
    ));
  }

  Color _platformColor(String p) {
    if (p.toLowerCase().contains('instagram')) return const Color(0xFFE1306C);
    if (p.toLowerCase().contains('tiktok')) return const Color(0xFF69C9D0);
    if (p.toLowerCase().contains('facebook')) return const Color(0xFF1877F2);
    return const Color(0xFF25D366);
  }
}
