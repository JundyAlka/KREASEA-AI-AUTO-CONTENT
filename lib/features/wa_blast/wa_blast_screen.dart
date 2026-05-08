import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';

class WaBlastScreen extends ConsumerStatefulWidget {
  const WaBlastScreen({super.key});
  @override
  ConsumerState<WaBlastScreen> createState() => _WaBlastScreenState();
}

class _WaBlastScreenState extends ConsumerState<WaBlastScreen> {
  final _detailCtrl = TextEditingController();
  String _tipe = 'Promo Flash Sale';
  String _cta = 'Hubungi WA';
  String _tone = 'Santai';
  bool _isLoading = false;
  String _panjang = '';
  String _pendek = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('WA Blast Template', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassContainer(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Text('Generate pesan broadcast WA yang personal dan tidak terasa spam.', style: TextStyle(color: Colors.white60, fontSize: 11))),
        ])),
        const SizedBox(height: 16),
        GlassDropdown<String>(label: 'Tipe Pesan', value: _tipe, onChanged: (v) => setState(() => _tipe = v!), items: const [
          DropdownMenuItem(value: 'Promo Flash Sale', child: Text('🔥 Promo Flash Sale')),
          DropdownMenuItem(value: 'Produk Baru', child: Text('🆕 Produk Baru')),
          DropdownMenuItem(value: 'Info Stok', child: Text('📦 Info Stok')),
          DropdownMenuItem(value: 'Pengingat Order', child: Text('🔔 Pengingat Order')),
          DropdownMenuItem(value: 'Ucapan Hari Besar', child: Text('🎉 Ucapan Hari Besar')),
          DropdownMenuItem(value: 'Follow-up Pelanggan Lama', child: Text('💌 Follow-up Pelanggan')),
          DropdownMenuItem(value: 'Undangan Event', child: Text('📍 Undangan Event')),
        ]),
        const SizedBox(height: 14),
        GlassFormField(label: 'Detail Promo / Informasi', hint: 'Nama produk, harga, diskon, batas waktu...', controller: _detailCtrl, maxLines: 3),
        const SizedBox(height: 14),
        GlassChipGroup(label: 'CTA (Call to Action)', options: const ['Hubungi WA', 'Klik Link', 'Kunjungi Toko', 'Order Sekarang'], selected: _cta, onSelected: (v) => setState(() => _cta = v)),
        const SizedBox(height: 14),
        GlassChipGroup(label: 'Tone', options: const ['Formal', 'Santai', 'Sedikit Humor'], selected: _tone, onSelected: (v) => setState(() => _tone = v)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _generate,
          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 18),
          label: Text(_isLoading ? 'Generating...' : 'Generate Template WA ✨'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(height: 20),
        if (_isLoading) ...[const AiResultShimmer(), const SizedBox(height: 12), const AiResultShimmer()],
        if (_panjang.isNotEmpty) ...[
          const Text('📝 Versi Panjang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          AiResultCard(title: 'Broadcast WA — Panjang', content: _panjang, accentColor: const Color(0xFF25D366)),
          const SizedBox(height: 16),
          const Text('⚡ Versi Pendek', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          AiResultCard(title: 'Broadcast WA — Pendek', content: _pendek, accentColor: const Color(0xFF25D366)),
        ],
      ])),
    );
  }

  Future<void> _generate() async {
    if (_detailCtrl.text.isEmpty) return;
    setState(() { _isLoading = true; _panjang = ''; _pendek = ''; });
    final gemini = ref.read(geminiServiceProvider);
    final raw = await gemini.generateText(
      systemPrompt: 'Buat pesan broadcast WhatsApp untuk UMKM yang terasa personal, tidak spam, dan memiliki CTA yang jelas. Gunakan bahasa Indonesia yang $_tone. Sertakan emoji yang relevan tapi tidak berlebihan. Selalu gunakan placeholder [Nama Kak] untuk personalisasi nama.',
      userPrompt: 'Tipe: $_tipe\nDetail: ${_detailCtrl.text}\nCTA: $_cta\n\nBuat 2 versi:\n1. VERSI PANJANG (200-250 kata)\n2. VERSI PENDEK (max 100 kata)\n\nPisahkan dengan ---PENDEK---',
    );
    final parts = raw.split('---PENDEK---');
    setState(() {
      _isLoading = false;
      _panjang = parts.isNotEmpty ? parts[0].trim() : raw;
      _pendek = parts.length > 1 ? parts[1].trim() : '';
    });
  }
}
