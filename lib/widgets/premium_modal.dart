import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════
// PREMIUM MODAL — Shared widget, dapat dipanggil dari mana saja
// ══════════════════════════════════════════════════════════════════

void showKreaseaPremiumModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              // ── Hero header ──────────────────────────────────────
              Container(
                height: 130,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Icon(
                        Icons.diamond_rounded,
                        size: 110,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Handle
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PRO PLAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Unlimited Power. 🚀',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Buat konten lebih banyak, lebih cepat, lebih hebat',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Benefits list ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    children: [
                      // Plan comparison
                      _PlanComparisonRow(
                        feature: 'Caption AI / hari',
                        free: '5',
                        pro: '25',
                        premium: '99',
                      ),
                      const SizedBox(height: 8),
                      _PlanComparisonRow(
                        feature: 'Image Generate / hari',
                        free: '3',
                        pro: '15',
                        premium: '50',
                      ),
                      const SizedBox(height: 20),

                      // Benefits
                      _premiumBenefit(ctx, Icons.bolt_rounded,
                          'Lebih Banyak Credit', 'Buat konten tanpa khawatir kehabisan', AppColors.warning),
                      _premiumBenefit(ctx, Icons.speed_rounded,
                          'Fast Processing', 'Prioritas antrian server', AppColors.info),
                      _premiumBenefit(ctx, Icons.hd_rounded,
                          'HD Image Download', 'Resolusi gambar 4K untuk cetak', AppColors.success),
                      _premiumBenefit(ctx, Icons.auto_fix_high_rounded,
                          'Hapus Watermark', 'Output bersih tanpa watermark', AppColors.accent),
                      _premiumBenefit(ctx, Icons.calendar_month_rounded,
                          'Content Calendar AI', 'Jadwal konten 30 hari otomatis', const Color(0xFFF59E0B)),
                      _premiumBenefit(ctx, Icons.analytics_rounded,
                          'Advanced Analytics', 'Laporan performa mendalam', const Color(0xFF00B4DB)),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── CTA pinned at bottom ──────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withOpacity(0.95),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.06)),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(children: [
                                Icon(Icons.rocket_launch_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text('Fitur pembayaran akan segera hadir! 🚀'),
                              ]),
                              backgroundColor: const Color(0xFF7C4DFF),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          '⚡ Langganan Pro — Rp 49.000/bln',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Tidak sekarang',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Plan comparison row ──────────────────────────────────────────
class _PlanComparisonRow extends StatelessWidget {
  final String feature, free, pro, premium;
  const _PlanComparisonRow(
      {required this.feature,
      required this.free,
      required this.pro,
      required this.premium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          _cell(free, Colors.white38, false),
          _cell(pro, const Color(0xFF7C4DFF), true),
          _cell(premium, const Color(0xFFFFD700), false),
        ],
      ),
    );
  }

  Widget _cell(String val, Color color, bool highlight) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: highlight
            ? const EdgeInsets.symmetric(vertical: 3, horizontal: 6)
            : EdgeInsets.zero,
        decoration: highlight
            ? BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.4)))
            : null,
        child: Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Benefit row ──────────────────────────────────────────────────
Widget _premiumBenefit(
    BuildContext context, IconData icon, String title, String subtitle, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF7C4DFF), size: 18),
      ],
    ),
  );
}
