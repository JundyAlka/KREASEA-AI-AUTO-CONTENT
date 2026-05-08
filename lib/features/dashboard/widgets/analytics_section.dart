import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/analytics_data.dart';
import '../../../services/analytics_service.dart';
import '../../../theme/app_theme.dart';

class AnalyticsSection extends ConsumerStatefulWidget {
  const AnalyticsSection({super.key});
  @override
  ConsumerState<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends ConsumerState<AnalyticsSection> {
  String _selectedTrend = 'Gabungan'; // 'Views', 'Interaksi', 'Gabungan'

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsStreamProvider);
    return analyticsAsync.when(
      data: (data) => _buildContent(context, data),
      loading: () => _buildSkeleton(),
      error: (e, s) => _buildError(e),
    );
  }

  Widget _buildSkeleton() {
    return _GlassCard(child: SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: AppColors.accentLight, strokeWidth: 2))));
  }

  Widget _buildError(Object e) {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 32), const SizedBox(height: 8),
      const Text('Gagal memuat analitik', style: TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 8),
      TextButton(onPressed: () => ref.invalidate(analyticsStreamProvider),
        child: const Text('Coba Lagi', style: TextStyle(color: AppColors.accentLight))),
    ])));
  }

  Widget _buildContent(BuildContext context, AnalyticsData data) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Performa Konten', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        Row(children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          const Text('LIVE', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => ref.invalidate(analyticsStreamProvider),
            child: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 16)),
        ]),
      ]),
      const SizedBox(height: 14),

      // 3 Metric Cards (tappable → detail pages)
      Row(children: [
        Expanded(child: _TappableMetricCard(label: 'Jangkauan', value: _fmt(data.totalReach), trend: '+12.5%', icon: Icons.groups_outlined,
          gradColors: [const Color(0xFF3D5AFE), const Color(0xFF5C7CFF)], isUp: true,
          onTap: () => context.push('/dashboard/metric/reach'))),
        const SizedBox(width: 10),
        Expanded(child: _TappableMetricCard(label: 'Interaksi', value: _fmt(data.totalEngagement), trend: '+8.2%', icon: Icons.favorite_border_rounded,
          gradColors: [const Color(0xFF7C4DFF), const Color(0xFFAB6DFF)], isUp: true,
          onTap: () => context.push('/dashboard/metric/engagement'))),
        const SizedBox(width: 10),
        Expanded(child: _TappableMetricCard(label: 'Eng. Rate', value: '${data.engagementRate.toStringAsFixed(1)}%', trend: '+2.1%', icon: Icons.bar_chart_rounded,
          gradColors: [const Color(0xFF00B4DB), const Color(0xFF0083B0)], isUp: true,
          onTap: () => context.push('/dashboard/metric/rate'))),
      ]),
      const SizedBox(height: 14),

      // Chart with trend toggle
      _buildChart(data),
    ]);
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : n.toString();

  Widget _buildChart(AnalyticsData data) {
    return _GlassCard(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header + trend toggle
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Tren 7 Hari', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
        _buildTrendToggle(),
      ]),
      const SizedBox(height: 6),
      // Legend
      Row(children: [
        if (_selectedTrend != 'Interaksi') _LegendDot(color: const Color(0xFF3D5AFE), label: 'Views'),
        if (_selectedTrend == 'Gabungan') const SizedBox(width: 10),
        if (_selectedTrend != 'Views') _LegendDot(color: const Color(0xFF7C4DFF), label: 'Interaksi'),
      ]),
      const SizedBox(height: 12),
      // Chart
      SizedBox(
        height: 150,
        child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 600,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35,
              getTitlesWidget: (v, meta) {
                if (v == meta.min || v == meta.max) return const SizedBox();
                return Text(_fmt(v.toInt()), style: const TextStyle(color: Colors.white24, fontSize: 9));
              })),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox();
                return Text(days[i], style: const TextStyle(color: Colors.white38, fontSize: 10));
              })),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardDark.withOpacity(0.9),
              getTooltipItems: (spots) => spots.map((s) {
                final isViews = s.barIndex == 0;
                return LineTooltipItem('${isViews ? "Views" : "Interaksi"}: ${s.y.toInt()}',
                  TextStyle(color: isViews ? const Color(0xFF5C7CFF) : const Color(0xFFAB6DFF), fontWeight: FontWeight.bold, fontSize: 11));
              }).toList(),
            ),
          ),
          lineBarsData: _buildLines(data),
        )),
      ),
    ])));
  }

  List<LineChartBarData> _buildLines(AnalyticsData data) {
    final lines = <LineChartBarData>[];
    if (_selectedTrend != 'Interaksi') {
      lines.add(LineChartBarData(
        spots: data.dailyMetrics.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.views.toDouble())).toList(),
        isCurved: true, curveSmoothness: 0.3,
        gradient: const LinearGradient(colors: [Color(0xFF3D5AFE), Color(0xFF5C7CFF)]),
        barWidth: 2.5,
        dotData: FlDotData(show: true, getDotPainter: (s, _, __, ___) => FlDotCirclePainter(radius: 3, color: const Color(0xFF3D5AFE), strokeWidth: 1.5, strokeColor: Colors.white)),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF3D5AFE).withOpacity(0.2), const Color(0xFF3D5AFE).withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      ));
    }
    if (_selectedTrend != 'Views') {
      lines.add(LineChartBarData(
        spots: data.dailyMetrics.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.interactions.toDouble())).toList(),
        isCurved: true, curveSmoothness: 0.3,
        gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFAB6DFF)]),
        barWidth: 2.5,
        dotData: FlDotData(show: true, getDotPainter: (s, _, __, ___) => FlDotCirclePainter(radius: 3, color: const Color(0xFF7C4DFF), strokeWidth: 1.5, strokeColor: Colors.white)),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF7C4DFF).withOpacity(0.15), const Color(0xFF7C4DFF).withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      ));
    }
    return lines;
  }

  Widget _buildTrendToggle() {
    final options = ['Gabungan', 'Views', 'Interaksi'];
    return Row(children: options.map((opt) {
      final sel = _selectedTrend == opt;
      return GestureDetector(
        onTap: () => setState(() => _selectedTrend = opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: sel ? const LinearGradient(colors: [AppColors.grad1, AppColors.grad2]) : null,
            color: sel ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(opt, style: TextStyle(fontSize: 9, color: sel ? Colors.white : Colors.white38, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
        ),
      );
    }).toList());
  }
}

// ═══════════════════ PRIVATE WIDGETS ═══════════════════

class _LegendDot extends StatelessWidget {
  final Color color; final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
  ]);
}

class _TappableMetricCard extends StatelessWidget {
  final String label, value, trend; final IconData icon; final List<Color> gradColors; final bool isUp; final VoidCallback onTap;
  const _TappableMetricCard({required this.label, required this.value, required this.trend, required this.icon, required this.gradColors, required this.isUp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [gradColors[0].withOpacity(0.18), gradColors[1].withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gradColors[0].withOpacity(0.3), width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: LinearGradient(colors: gradColors), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 14)),
            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white24),
          ]),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isUp ? AppColors.success : AppColors.error, size: 10),
            Text(trend, style: TextStyle(fontSize: 10, color: isUp ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    )));
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(20), child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1)), child: child)));
}
