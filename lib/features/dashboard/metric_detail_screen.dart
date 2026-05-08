import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../models/analytics_data.dart';
import '../../services/analytics_service.dart';

class MetricDetailScreen extends ConsumerWidget {
  final String metricType; // 'reach', 'engagement', 'rate', 'total', 'scheduled', 'drafts'
  const MetricDetailScreen({super.key, required this.metricType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _getConfig();
    final analyticsAsync = ref.watch(analyticsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(config.title, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hero Metric Card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: config.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: config.colors.first.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: Icon(config.icon, color: Colors.white, size: 28)),
              const SizedBox(height: 16),
              analyticsAsync.when(
                data: (data) => Text(_getValue(data), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
                loading: () => const Text('...', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
                error: (_, __) => const Text('—', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text(config.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 12),
                  Text(config.trend, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Text(' vs minggu lalu', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ])),
            ]),
          ),
          const SizedBox(height: 24),

          // Chart 7 hari
          const Text('Tren 7 Hari Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          analyticsAsync.when(
            data: (data) => _buildChart(data, config),
            loading: () => GlassContainer(height: 200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => GlassContainer(height: 200, child: const Center(child: Text('Gagal memuat', style: TextStyle(color: Colors.white54)))),
          ),
          const SizedBox(height: 24),

          // Breakdown per Platform
          const Text('Distribusi Platform', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          _buildPlatformBreakdown(config),
          const SizedBox(height: 24),

          // Tips
          const Text('Tips Meningkatkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          ...config.tips.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassContainer(padding: const EdgeInsets.all(14), child: Row(children: [
            Icon(Icons.lightbulb_outline_rounded, color: config.colors.first, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          ])))),
        ]),
      ),
    );
  }

  String _getValue(AnalyticsData data) {
    switch (metricType) {
      case 'reach': return _fmt(data.totalReach);
      case 'engagement': return _fmt(data.totalEngagement);
      case 'rate': return '${data.engagementRate.toStringAsFixed(1)}%';
      case 'total': return '${data.dailyMetrics.length * 2}';
      case 'scheduled': return '3';
      case 'drafts': return '2';
      default: return '—';
    }
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : n.toString();

  Widget _buildChart(AnalyticsData data, _MetricConfig config) {
    final spots = data.dailyMetrics.asMap().entries.map((e) {
      final y = metricType == 'engagement' ? e.value.interactions.toDouble()
          : metricType == 'rate' ? (e.value.interactions / e.value.views * 100)
          : e.value.views.toDouble();
      return FlSpot(e.key.toDouble(), y);
    }).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: SizedBox(height: 180, child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 500,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
            getTitlesWidget: (v, _) {
              final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
              final i = v.toInt();
              return i >= 0 && i < days.length ? Text(days[i], style: const TextStyle(color: Colors.white38, fontSize: 10)) : const SizedBox();
            })),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: true, touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.cardDark.withOpacity(0.9),
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
            metricType == 'rate' ? '${s.y.toStringAsFixed(1)}%' : s.y.toInt().toString(),
            TextStyle(color: config.colors.first, fontWeight: FontWeight.bold, fontSize: 12))).toList())),
        lineBarsData: [LineChartBarData(
          spots: spots, isCurved: true, curveSmoothness: 0.3,
          gradient: LinearGradient(colors: config.colors), barWidth: 3,
          dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
            FlDotCirclePainter(radius: 4, color: config.colors.first, strokeWidth: 2, strokeColor: Colors.white)),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(
            colors: [config.colors.first.withOpacity(0.25), config.colors.first.withOpacity(0.0)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        )],
      ))),
    );
  }

  Widget _buildPlatformBreakdown(_MetricConfig config) {
    final platforms = [
      ('Instagram', 0.55, const Color(0xFFE1306C)),
      ('WhatsApp', 0.30, const Color(0xFF25D366)),
      ('TikTok', 0.15, const Color(0xFF69C9D0)),
    ];
    return GlassContainer(padding: const EdgeInsets.all(16), child: Column(
      children: platforms.map((p) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
        SizedBox(width: 70, child: Text(p.$1, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
          value: p.$2, minHeight: 8, backgroundColor: Colors.white.withOpacity(0.06), color: p.$3))),
        const SizedBox(width: 10),
        Text('${(p.$2 * 100).toInt()}%', style: TextStyle(color: p.$3, fontWeight: FontWeight.bold, fontSize: 12)),
      ]))).toList(),
    ));
  }

  _MetricConfig _getConfig() {
    switch (metricType) {
      case 'reach': return _MetricConfig('Jangkauan', 'Total reach semua konten kamu', '+12.5%', Icons.groups_rounded,
        [const Color(0xFF3D5AFE), const Color(0xFF5C7CFF)],
        ['Gunakan hashtag trending untuk meningkatkan reach.', 'Posting di jam 19:00-21:00 untuk jangkauan maksimal.', 'Kolaborasi dengan akun lain untuk cross-promotion.']);
      case 'engagement': return _MetricConfig('Interaksi', 'Like, comment, share & save', '+8.2%', Icons.favorite_rounded,
        [const Color(0xFF7C4DFF), const Color(0xFFAB6DFF)],
        ['Ajukan pertanyaan di caption untuk memancing komentar.', 'Gunakan CTA yang jelas seperti "Tag temanmu!".', 'Reply semua komentar dalam 1 jam pertama.']);
      case 'rate': return _MetricConfig('Engagement Rate', 'Rasio interaksi terhadap reach', '+2.1%', Icons.bar_chart_rounded,
        [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
        ['Rate 3-6% dianggap bagus untuk akun bisnis.', 'Konten carousel biasanya punya rate lebih tinggi.', 'Posting konsisten 3-5x seminggu.']);
      case 'total': return _MetricConfig('Total Konten', 'Semua konten yang sudah dibuat', '—', Icons.article_rounded,
        [AppColors.grad1, AppColors.grad2],
        ['Buat minimal 3 konten per minggu.', 'Variasikan tipe konten: gambar, video, carousel.']);
      case 'scheduled': return _MetricConfig('Terjadwal', 'Konten menunggu posting', '—', Icons.schedule_rounded,
        [AppColors.warning, const Color(0xFFFFA726)],
        ['Jadwalkan konten di waktu audiens paling aktif.', 'Siapkan konten 1 minggu di muka.']);
      case 'drafts': return _MetricConfig('Draft', 'Konten belum selesai', '—', Icons.edit_note_rounded,
        [AppColors.success, const Color(0xFF66BB6A)],
        ['Selesaikan draft tertua terlebih dahulu.', 'Gunakan AI untuk melengkapi caption draft.']);
      default: return _MetricConfig('Detail', '', '—', Icons.info, [AppColors.grad1, AppColors.grad2], []);
    }
  }
}

class _MetricConfig {
  final String title, subtitle, trend;
  final IconData icon;
  final List<Color> colors;
  final List<String> tips;
  const _MetricConfig(this.title, this.subtitle, this.trend, this.icon, this.colors, this.tips);
}
