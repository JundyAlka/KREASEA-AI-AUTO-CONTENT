import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../models/content_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/credit_widgets.dart';
import './widgets/analytics_section.dart';
import './dashboard_providers.dart';
import '../../services/feature_menu_service.dart';
import '../../services/credit_service.dart';
import '../../models/feature_menu_item.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;
  bool _isMenuExpanded = false;

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final next = (_bannerIndex + 1) % 3;
        _bannerController.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (userProfile) {
        final profile = userProfile ?? UserProfile(uid: 'guest', email: '', businessName: 'Tamu', businessType: 'Umum');
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final statsAsync = ref.watch(contentStatsProvider);
        final recentAsync = ref.watch(recentContentProvider);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(profile, isDark),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BANNER SLIDESHOW
                _buildBannerSlideshow().animate().fade(duration: 400.ms),
                // 2. MAIN GENERATE TOOLS
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fitur Utama ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Buat konten viral dengan kekuatan AI', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _MainToolCard(
                        title: 'Buat Caption AI', subtitle: 'Generate caption viral otomatis',
                        icon: Icons.auto_awesome_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        onTap: () => _handleAiFeature('/dashboard/ai_text'),
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: _MainToolCard(
                        title: 'Desain Banner', subtitle: 'Buat visual konten siap posting',
                        icon: Icons.palette_rounded,
                        gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5722)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        onTap: () => _handleAiFeature('/dashboard/ai_image'),
                      )),
                    ],
                  ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),
                ),
                // 3. MENU LAINNYA
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: const Text('Menu Lainnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFeatureGrid().animate().fade(delay: 200.ms),
                ),
                // 4. OVERVIEW STATS
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: const Text('Ringkasan Konten 📊', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildOverviewStats(statsAsync).animate().fade(delay: 300.ms),
                ),
                // 5. ANALYTICS
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: const AnalyticsSection().animate().fade(delay: 400.ms),
                ),
                // 6. RECENT CONTENT (only if has content)
                _buildRecentSection(recentAsync),
                // 7. TIPS
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _buildTipsSection().animate().fade(delay: 600.ms),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  AppBar _buildAppBar(UserProfile profile, bool isDark) {
    return AppBar(
      titleSpacing: 16,
      title: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(13),
            boxShadow: [BoxShadow(color: AppColors.grad2.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Center(child: Text(profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Halo, ${profile.businessName} 👋', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          // ── Credit mini bar ────────────────────────────
          Consumer(builder: (ctx, ref, _) {
            final creditsAsync = ref.watch(userCreditsProvider);
            return creditsAsync.when(
              data: (credits) => Row(children: [
                const Icon(Icons.bolt_rounded, size: 10, color: Colors.amber),
                const SizedBox(width: 2),
                Text('🖼️ ${credits.imageCredits}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                const SizedBox(width: 6),
                Text('✍️ ${credits.captionCredits}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                const SizedBox(width: 4),
                Text('/ hari', style: const TextStyle(fontSize: 9, color: Colors.white24)),
              ]),
              loading: () => const Text('...', style: TextStyle(fontSize: 10, color: Colors.white24)),
              error: (_, __) => const SizedBox.shrink(),
            );
          }),
        ]),
      ]),
      actions: [
        IconButton(
          icon: Stack(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.notifications_outlined, size: 20)),
            Positioned(top: 4, right: 4, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceDark, width: 1.5)))),
          ]),
          onPressed: () => _showNotificationPopup(context),
        ),
        Padding(padding: const EdgeInsets.only(right: 8), child: IconButton(
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.diamond_outlined, color: Colors.amber, size: 20)),
          onPressed: () => _showPremiumModal(context),
        )),
      ],
    );
  }

  IconData _getCategoryIcon(String type) {
    switch (type) { case 'Makanan & Minuman': return Icons.restaurant; case 'Fashion': return Icons.checkroom; default: return Icons.store; }
  }

  // ── NOTIFICATION POPUP ──
  void _showNotificationPopup(BuildContext context) {
    final notifications = [
      _NotifItem(icon: Icons.auto_awesome_rounded, color: const Color(0xFF7C4DFF), title: 'Caption berhasil dibuat!', subtitle: 'Caption "Promo Ramadhan" siap digunakan', time: '2 menit lalu', isNew: true),
      _NotifItem(icon: Icons.schedule_rounded, color: const Color(0xFF00B4DB), title: 'Post dijadwalkan', subtitle: 'Instagram Feed — Besok, 19:00 WIB', time: '15 menit lalu', isNew: true),
      _NotifItem(icon: Icons.trending_up_rounded, color: const Color(0xFF38EF7D), title: 'Engagement naik +23%', subtitle: 'Konten minggu ini perform lebih baik!', time: '1 jam lalu', isNew: true),
      _NotifItem(icon: Icons.palette_rounded, color: const Color(0xFFE91E63), title: 'Desain siap diunduh', subtitle: 'Banner "Flash Sale" sudah selesai', time: '3 jam lalu', isNew: false),
      _NotifItem(icon: Icons.star_rounded, color: Colors.amber, title: 'Fitur Baru: Testimoni Generator', subtitle: 'Buat template request review otomatis', time: 'Kemarin', isNew: false),
      _NotifItem(icon: Icons.card_giftcard_rounded, color: const Color(0xFFE040FB), title: 'Promo: Upgrade ke Pro 50% OFF', subtitle: 'Berlaku hingga 31 Mei 2026', time: '2 hari lalu', isNew: false),
    ];

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
            height: MediaQuery.of(context).size.height * 0.58,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.97),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(children: [
              // Handle bar
              Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Notifikasi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  GestureDetector(
                    onTap: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.accentLight.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Tandai Dibaca', style: TextStyle(color: AppColors.accentLight, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              // List
              Expanded(child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04), height: 1),
                itemBuilder: (_, i) {
                  final n = notifications[i];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: n.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(n.icon, color: n.color, size: 17),
                    ),
                    title: Row(children: [
                      Expanded(child: Text(n.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: n.isNew ? Colors.white : Colors.white60))),
                      if (n.isNew) Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.accentLight, shape: BoxShape.circle)),
                    ]),
                    subtitle: Text('${n.subtitle} · ${n.time}', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3)), overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(ctx),
                  );
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // ── PREMIUM MODAL ──
  void _showPremiumModal(BuildContext context) {
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
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.97),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(children: [
              // ── Hero header (compact) ──
              Container(
                height: 110, width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Stack(children: [
                  Positioned(right: -10, top: -10, child: Icon(Icons.diamond_rounded, size: 90, color: Colors.white.withOpacity(0.1))),
                  Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRO PLAN', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
                      const SizedBox(height: 2),
                      const Text('Unlimited Power.', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    ],
                  )),
                  Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18), onPressed: () => Navigator.pop(ctx))),
                ]),
              ),
              // ── Benefits (non-scrollable) ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                    _premiumBenefit(Icons.bolt_rounded, 'Unlimited AI', 'Buat konten tanpa batas harian', AppColors.warning),
                    const SizedBox(height: 12),
                    _premiumBenefit(Icons.speed_rounded, 'Fast Processing', 'Prioritas antrian server', AppColors.info),
                    const SizedBox(height: 12),
                    _premiumBenefit(Icons.hd_rounded, 'HD Image Downloads', 'Resolusi gambar 4K untuk cetak', AppColors.success),
                    const SizedBox(height: 12),
                    _premiumBenefit(Icons.auto_fix_high_rounded, 'Remove Watermarks', 'Hapus watermark otomatis', AppColors.accent),
                    const SizedBox(height: 12),
                    _premiumBenefit(Icons.calendar_month_rounded, 'Content Calendar', 'Jadwal konten AI 30 hari', const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _premiumBenefit(Icons.analytics_rounded, 'Advanced Analytics', 'Laporan performa mendalam', const Color(0xFF00B4DB)),
                  ]),
                ),
              ),
              // ── CTA pinned at bottom ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(children: [
                  Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur pembayaran akan segera hadir! 🚀'), behavior: SnackBarBehavior.floating)); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Langganan Sekarang - Rp 49.000/bln', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(onPressed: () {}, child: const Text('Pulihkan Pembelian', style: TextStyle(color: Colors.white38, fontSize: 11))),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _premiumBenefit(IconData icon, String title, String subtitle, Color color) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ])),
    ]);
  }

  // ── BANNER SLIDESHOW ──
  Widget _buildBannerSlideshow() {
    final banners = [
      _BannerInfo('Buat Konten Viral\ndengan AI 🚀', 'Generate caption & desain profesional dalam hitungan detik.', [const Color(0xFF3D5AFE), const Color(0xFF7C4DFF)], Icons.auto_awesome_rounded),
      _BannerInfo('Jadwalkan Post\nOtomatis 📅', 'Atur waktu posting di jam terbaik audiens kamu.', [const Color(0xFF00B4DB), const Color(0xFF0083B0)], Icons.schedule_send_rounded),
      _BannerInfo('Analisis Performa\nReal-time 📊', 'Pantau jangkauan & engagement kontenmu setiap saat.', [const Color(0xFFE040FB), const Color(0xFF7C4DFF)], Icons.insights_rounded),
    ];
    return Column(children: [
      SizedBox(
        height: 180,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: PageView.builder(
            controller: _bannerController,
          onPageChanged: (i) => setState(() => _bannerIndex = i),
          itemCount: banners.length,
          itemBuilder: (ctx, i) {
            final b = banners[i];
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: b.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: b.colors.first.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(children: [
                  Positioned(right: -20, bottom: -20, child: Icon(b.icon, size: 130, color: Colors.white.withOpacity(0.1))),
                  Padding(padding: const EdgeInsets.all(16), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1))),
                      const SizedBox(height: 8),
                      Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.2)),
                      const SizedBox(height: 4),
                      Text(b.sub, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  )),
                ]),
              ),
            );
          },
        )),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: _bannerIndex == i ? 20 : 6, height: 6,
        decoration: BoxDecoration(color: _bannerIndex == i ? AppColors.accentLight : Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
      ))),
    ]);
  }

  // ── FEATURE GRID (Dynamic + Expandable) ──
  Widget _buildFeatureGrid() {
    final allFeatures = ref.watch(featureMenuProvider);
    final displayCount = _isMenuExpanded ? allFeatures.length : (allFeatures.length > 6 ? 6 : allFeatures.length);
    final showExpandButton = allFeatures.length > 6;

    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.0),
          itemCount: displayCount,
          itemBuilder: (ctx, i) {
            final f = allFeatures[i];
            return _FeatureGridItem(item: f, onTap: () => _onFeatureTap(f));
          },
        ),
      ),
      if (showExpandButton)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: GestureDetector(
            onTap: () => setState(() => _isMenuExpanded = !_isMenuExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_isMenuExpanded ? 'Sembunyikan' : 'Lihat Semua Fitur →', style: TextStyle(color: AppColors.accentLight, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(_isMenuExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.accentLight, size: 16),
              ]),
            ),
          ),
        ),
    ]);
  }

  void _onFeatureTap(FeatureMenuItem f) {
    if (f.isComingSoon) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.name} — Coming Soon!'), duration: const Duration(seconds: 1)));
      return;
    }
    _handleAiFeature(f.route);
  }

  // ── OVERVIEW STATS ──
  Widget _buildOverviewStats(AsyncValue<ContentStats> statsAsync) {
    final stats = statsAsync.valueOrNull ?? const ContentStats(total: 0, scheduled: 0, drafts: 0);
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: IntrinsicHeight(child: Row(children: [
        Expanded(child: _statCol('Total Konten', '${stats.total}', Icons.article_rounded, AppColors.grad1, () => context.push('/dashboard/metric/total'))),
        VerticalDivider(width: 1, color: Colors.white.withOpacity(0.08), indent: 8, endIndent: 8),
        Expanded(child: _statCol('Terjadwal', '${stats.scheduled}', Icons.schedule_rounded, AppColors.warning, () => context.push('/dashboard/metric/scheduled'))),
        VerticalDivider(width: 1, color: Colors.white.withOpacity(0.08), indent: 8, endIndent: 8),
        Expanded(child: _statCol('Draft', '${stats.drafts}', Icons.edit_note_rounded, AppColors.success, () => context.push('/dashboard/metric/drafts'))),
      ])),
    );
  }

  Widget _statCol(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 20), const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)), textAlign: TextAlign.center),
    ]));
  }

  // ── RECENT CONTENT (real data, conditional) ──
  Widget _buildRecentSection(AsyncValue<List<ContentItem>> recentAsync) {
    return recentAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Konten Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.go('/library'), child: const Text('Lihat Semua', style: TextStyle(color: AppColors.accentLight, fontSize: 12))),
            ]),
            const SizedBox(height: 8),
            ...items.map((item) => _RecentContentCard(item: item)).toList(),
          ]).animate().fade(delay: 500.ms),
        );
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }

  // ── TIPS ──
  Widget _buildTipsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pusat Edukasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _tipCard('Tips Konten Viral 🔥', 'Posting minimal 3x seminggu bisa meningkatkan engagement hingga 40%.', Icons.trending_up_rounded, const Color(0xFFF59E0B)),
      _tipCard('Waktu Terbaik Post 📅', 'Jam 19.00–21.00 adalah golden hour untuk reach organik tertinggi.', Icons.access_time_rounded, const Color(0xFF3B82F6)),
    ]);
  }

  Widget _tipCard(String title, String body, IconData icon, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassContainer(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ])),
    ])));
  }

  void _handleAiFeature(String route, [Object? extra]) {
    final isGuest = ref.read(authStateProvider).value == null;
    if (isGuest) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Login Diperlukan', style: TextStyle(color: Colors.white)),
        content: const Text('Silakan login untuk menggunakan fitur AI.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.white38))),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); context.push('/login'); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentLight, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Login Sekarang')),
        ],
      ));
    } else {
      extra != null ? context.push(route, extra: extra) : context.push(route);
    }
  }
}

// ═══════════════════ PRIVATE WIDGETS ═══════════════════

class _BannerInfo {
  final String title, sub;
  final List<Color> colors;
  final IconData icon;
  const _BannerInfo(this.title, this.sub, this.colors, this.icon);
}

class _MainToolCard extends StatelessWidget {
  final String title, subtitle; final IconData icon; final LinearGradient gradient; final VoidCallback onTap;
  const _MainToolCard({required this.title, required this.subtitle, required this.icon, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      height: 150,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(children: [
        Positioned(right: -15, bottom: -15, child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.12))),
        Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 22)),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10), maxLines: 2),
        ])),
      ])),
    ));
  }
}

class _RecentContentCard extends StatelessWidget {
  final ContentItem item;
  const _RecentContentCard({required this.item});

  Color _platformColor() {
    switch (item.platform) {
      case ContentPlatform.instagramFeed: case ContentPlatform.instagramStory: return const Color(0xFFE1306C);
      case ContentPlatform.tiktok: return const Color(0xFF69C9D0);
      case ContentPlatform.whatsapp: return const Color(0xFF25D366);
      case ContentPlatform.facebook: return const Color(0xFF1877F2);
      default: return AppColors.grad1;
    }
  }

  IconData _platformIcon() {
    switch (item.platform) {
      case ContentPlatform.instagramFeed: case ContentPlatform.instagramStory: return Icons.camera_alt_rounded;
      case ContentPlatform.tiktok: return Icons.music_note_rounded;
      case ContentPlatform.whatsapp: return Icons.chat_rounded;
      case ContentPlatform.facebook: return Icons.facebook_rounded;
      default: return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _platformColor();
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassContainer(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/library/detail', extra: item),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          // Dynamic platform thumbnail
          Container(width: 52, height: 52,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Icon(_platformIcon(), color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(item.platform.name, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))),
              const SizedBox(width: 6),
              Text('${item.createdAt.day}/${item.createdAt.month}', style: const TextStyle(fontSize: 10, color: Colors.white24)),
            ]),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white24),
        ])),
      ),
    ));
  }
}

class _FeatureGridItem extends StatelessWidget {
  final FeatureMenuItem item;
  final VoidCallback onTap;
  const _FeatureGridItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Stack(
              children: [
                Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: item.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(item.name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                )),
                // Badge
                if (item.badge.isNotEmpty)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: _badgeColor(item.badge),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(item.badge, style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case 'Baru': return const Color(0xFF38EF7D);
      case 'Pro': return const Color(0xFFFFD93D);
      case 'Premium': return const Color(0xFFE91E63);
      case 'Soon': return Colors.white.withOpacity(0.15);
      default: return Colors.white24;
    }
  }
}

class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final bool isNew;
  const _NotifItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time, this.isNew = false});
}
