import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';

class HppScreen extends ConsumerStatefulWidget {
  const HppScreen({super.key});
  @override
  ConsumerState<HppScreen> createState() => _HppScreenState();
}

class _HppScreenState extends ConsumerState<HppScreen> {
  final List<Map<String, TextEditingController>> _bahan = [_newBahan()];
  final List<Map<String, TextEditingController>> _tenaga = [_newTenaga()];
  final List<Map<String, TextEditingController>> _overhead = [_newOverhead()];
  final _jumlahCtrl = TextEditingController(text: '12');
  final _targetCtrl = TextEditingController(text: '100');
  double _margin = 30;
  bool _showResult = false;
  bool _isAiLoading = false;
  String _aiAdvice = '';

  static Map<String, TextEditingController> _newBahan() => {'nama': TextEditingController(), 'qty': TextEditingController(), 'harga': TextEditingController()};
  static Map<String, TextEditingController> _newTenaga() => {'desc': TextEditingController(), 'jam': TextEditingController(), 'upah': TextEditingController()};
  static Map<String, TextEditingController> _newOverhead() => {'nama': TextEditingController(), 'biaya': TextEditingController()};

  double get _totalBahan => _bahan.fold(0, (s, b) => s + (_d(b['qty']) * _d(b['harga'])));
  double get _totalTenaga => _tenaga.fold(0, (s, t) => s + (_d(t['jam']) * _d(t['upah'])));
  double get _totalOverhead => _overhead.fold(0, (s, o) => s + _d(o['biaya']));
  double get _hppTotal => _totalBahan + _totalTenaga + _totalOverhead;
  int get _jumlah => int.tryParse(_jumlahCtrl.text) ?? 1;
  double get _hppPerUnit => _jumlah > 0 ? _hppTotal / _jumlah : 0;
  double get _hargaJual => _hppPerUnit * (1 + _margin / 100);
  double get _labaBulanan => (_hargaJual - _hppPerUnit) * (int.tryParse(_targetCtrl.text) ?? 0);
  double _d(TextEditingController? c) => double.tryParse(c?.text ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Kalkulator HPP', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Bahan Baku
        _sectionHeader('🧾 Bahan Baku', () => setState(() => _bahan.add(_newBahan()))),
        ..._bahan.asMap().entries.map((e) => _bahanRow(e.key)),
        const SizedBox(height: 16),
        // Tenaga Kerja
        _sectionHeader('👷 Tenaga Kerja', () => setState(() => _tenaga.add(_newTenaga()))),
        ..._tenaga.asMap().entries.map((e) => _tenagaRow(e.key)),
        const SizedBox(height: 16),
        // Overhead
        _sectionHeader('⚡ Biaya Overhead', () => setState(() => _overhead.add(_newOverhead()))),
        ..._overhead.asMap().entries.map((e) => _overheadRow(e.key)),
        const SizedBox(height: 16),
        GlassFormField(label: 'Jumlah Produksi (unit/batch)', controller: _jumlahCtrl, keyboardType: TextInputType.number, hint: '12'),
        const SizedBox(height: 20),
        // Hitung button
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: () => setState(() => _showResult = true),
          icon: const Icon(Icons.calculate_rounded, size: 18),
          label: const Text('Hitung HPP'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A56DB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        if (_showResult) ...[
          const SizedBox(height: 20),
          _buildResult(),
        ],
      ])),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      GestureDetector(onTap: onAdd, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.accentLight.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.add_rounded, color: AppColors.accentLight, size: 18))),
    ]));
  }

  Widget _bahanRow(int i) {
    final b = _bahan[i];
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassContainer(padding: const EdgeInsets.all(10), child: Row(children: [
      Expanded(flex: 3, child: TextField(controller: b['nama'], style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _inputDeco('Nama'))),
      const SizedBox(width: 6),
      Expanded(flex: 2, child: TextField(controller: b['qty'], keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _inputDeco('Qty'))),
      const SizedBox(width: 6),
      Expanded(flex: 2, child: TextField(controller: b['harga'], keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _inputDeco('Harga'))),
      if (_bahan.length > 1) GestureDetector(onTap: () => setState(() => _bahan.removeAt(i)), child: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.close_rounded, color: Colors.red, size: 16))),
    ])));
  }

  Widget _tenagaRow(int i) {
    final t = _tenaga[i];
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassContainer(padding: const EdgeInsets.all(10), child: Row(children: [
      Expanded(flex: 3, child: TextField(controller: t['desc'], style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _inputDeco('Deskripsi'))),
      const SizedBox(width: 6),
      Expanded(flex: 2, child: TextField(controller: t['jam'], keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _inputDeco('Jam'))),
      const SizedBox(width: 6),
      Expanded(flex: 2, child: TextField(controller: t['upah'], keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _inputDeco('Upah/jam'))),
      if (_tenaga.length > 1) GestureDetector(onTap: () => setState(() => _tenaga.removeAt(i)), child: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.close_rounded, color: Colors.red, size: 16))),
    ])));
  }

  Widget _overheadRow(int i) {
    final o = _overhead[i];
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassContainer(padding: const EdgeInsets.all(10), child: Row(children: [
      Expanded(flex: 3, child: TextField(controller: o['nama'], style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _inputDeco('Nama'))),
      const SizedBox(width: 6),
      Expanded(flex: 2, child: TextField(controller: o['biaya'], keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: _inputDeco('Biaya'))),
      if (_overhead.length > 1) GestureDetector(onTap: () => setState(() => _overhead.removeAt(i)), child: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.close_rounded, color: Colors.red, size: 16))),
    ])));
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), isDense: true);

  Widget _buildResult() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('📊 Hasil Kalkulasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 12),
      GlassContainer(padding: const EdgeInsets.all(16), child: Column(children: [
        _resultRow('Bahan Baku', _totalBahan),
        _resultRow('Tenaga Kerja', _totalTenaga),
        _resultRow('Overhead', _totalOverhead),
        Divider(color: Colors.white.withOpacity(0.1)),
        _resultRow('HPP Total Batch', _hppTotal, bold: true),
        _resultRow('HPP Per Unit', _hppPerUnit, bold: true, color: AppColors.accentLight),
      ])),
      const SizedBox(height: 16),
      const Text('💰 Margin Keuntungan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 8),
      GlassContainer(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Margin: ${_margin.toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text('Rp ${_fmtNum(_hargaJual)}', style: const TextStyle(color: AppColors.accentLight, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        Slider(value: _margin, min: 5, max: 100, divisions: 19, activeColor: AppColors.accentLight, inactiveColor: Colors.white12, label: '${_margin.toInt()}%',
          onChanged: (v) => setState(() => _margin = v)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [10, 20, 30, 40, 50].map((m) => GestureDetector(
          onTap: () => setState(() => _margin = m.toDouble()),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _margin == m ? AppColors.accentLight.withOpacity(0.2) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Text('$m%', style: TextStyle(color: _margin == m ? AppColors.accentLight : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
        )).toList()),
      ])),
      const SizedBox(height: 16),
      const Text('📈 Proyeksi Laba', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 8),
      GlassContainer(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [
          const Expanded(child: Text('Target jual/bulan:', style: TextStyle(color: Colors.white54, fontSize: 12))),
          SizedBox(width: 80, child: TextField(controller: _targetCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center, decoration: _inputDeco('unit'), onChanged: (_) => setState(() {}))),
          const Text(' unit', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Laba Bersih/bulan:', style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text('Rp ${_fmtNum(_labaBulanan)}', style: const TextStyle(color: Color(0xFF38EF7D), fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ])),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
        onPressed: _isAiLoading ? null : _getAiAdvice,
        icon: _isAiLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.psychology_rounded, size: 18),
        label: Text(_isAiLoading ? 'Menganalisis...' : 'Minta Saran AI 🤖'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      )),
      if (_aiAdvice.isNotEmpty) ...[const SizedBox(height: 12), AiResultCard(title: 'Saran AI', content: _aiAdvice, accentColor: Colors.amber)],
    ]);
  }

  Widget _resultRow(String label, double value, {bool bold = false, Color? color}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text('Rp ${_fmtNum(value)}', style: TextStyle(color: color ?? Colors.white, fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ]));
  }

  String _fmtNum(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Future<void> _getAiAdvice() async {
    setState(() { _isAiLoading = true; _aiAdvice = ''; });
    final gemini = ref.read(geminiServiceProvider);
    _aiAdvice = await gemini.generateText(
      systemPrompt: 'Kamu adalah konsultan bisnis UMKM Indonesia yang ahli dalam strategi penetapan harga. Gunakan bahasa Indonesia yang ramah dan mudah dipahami.',
      userPrompt: 'HPP produk saya adalah Rp ${_fmtNum(_hppPerUnit)}/unit.\nSaya berencana menjualnya seharga Rp ${_fmtNum(_hargaJual)}/unit (margin ${_margin.toInt()}%).\n\nBerikan:\n1. Analisis apakah harga tersebut kompetitif (2-3 kalimat)\n2. Risiko jika harga terlalu rendah atau terlalu tinggi\n3. Saran harga psikologis yang lebih menarik\n4. Tips meningkatkan perceived value\nFormat: poin-poin singkat, maksimal 150 kata total.',
    );
    setState(() => _isAiLoading = false);
  }
}
