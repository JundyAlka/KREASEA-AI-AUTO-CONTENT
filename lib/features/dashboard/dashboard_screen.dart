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
import '../../widgets/premium_modal.dart';
import './widgets/analytics_section.dart';
import './dashboard_providers.dart';
import '../../services/feature_menu_service.dart';
import '../../services/credit_service.dart';
import '../../models/feature_menu_item.dart';
import '../../main.dart' show appVersion, isBetaVersion;

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

  // ── Time-based greeting ──────────────────────────────────────────
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
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

  PreferredSizeWidget _buildAppBar(UserProfile profile, bool isDark) {
    final displayName = profile.businessName.isNotEmpty
        ? profile.businessName
        : (profile.email.isNotEmpty ? profile.email.split('@').first : 'Pengguna');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final greeting = _getGreeting();

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F0F1A).withOpacity(0.88),
                  const Color(0xFF1A1A2E).withOpacity(0.80),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // ── Avatar dengan gradient + glow ──────────────────
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.grad2.withOpacity(0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: AppColors.grad1.withOpacity(0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Greeting + Nama + Badges ───────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Greeting row
                          Row(
                            children: [
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.45),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('👋', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Nama bisnis — full, tidak terpotong
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          // Sub-row: tipe bisnis + credit
                          Row(
                            children: [
                              if (profile.businessType.isNotEmpty) ...[
                                _GlassBadge(
                                  label: profile.businessType,
                                  color: AppColors.accentLight,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Consumer(builder: (ctx, ref, _) {
                                final creditsAsync = ref.watch(userCreditsProvider);
                                return creditsAsync.when(
                                  data: (credits) => Row(children: [
                                    _MiniCreditChip(
                                      emoji: '🖼️',
                                      count: credits.imageCredits,
                                      max: credits.imageCreditMax,
                                    ),
                                    const SizedBox(width: 5),
                                    _MiniCreditChip(
                                      emoji: '✍️',
                                      count: credits.captionCredits,
                                      max: credits.captionCreditMax,
                                    ),
                                  ]),
                                  loading: () => Container(
                                    width: 60, height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Action Buttons ─────────────────────────────────
                    // BETA badge
                    if (isBetaVersion) ...[
                      _GlassActionButton(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'BETA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        onTap: null,
                      ),
                      const SizedBox(width: 4),
                    ],
                    _GlassActionButton(
                      icon: Icons.notifications_outlined,
                      onTap: () => _showNotificationPopup(context),
                    ),
                    const SizedBox(width: 6),
                    _GlassActionButton(
                      icon: Icons.diamond_outlined,
                      iconColor: Colors.amber,
                      bgColor: Colors.amber.withOpacity(0.12),
                      onTap: () => _showPremiumModal(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'Makanan & Minuman': return Icons.restaurant_rounded;
      case 'Kafe & Coffee Shop': return Icons.coffee_rounded;
      case 'Bakery & Roti': return Icons.bakery_dining_rounded;
      case 'Katering & Snack': return Icons.set_meal_rounded;
      case 'Fashion & Pakaian': return Icons.checkroom_rounded;
      case 'Aksesori & Perhiasan': return Icons.diamond_rounded;
      case 'Kecantikan & Skincare': return Icons.face_retouching_natural_rounded;
      case 'Salon & Barbershop': return Icons.content_cut_rounded;
      case 'Kesehatan & Apotek': return Icons.local_pharmacy_rounded;
      case 'Olahraga & Fitness': return Icons.fitness_center_rounded;
      case 'Elektronik & Gadget': return Icons.devices_rounded;
      case 'Furnitur & Interior': return Icons.chair_rounded;
      case 'Properti & Kontrakan': return Icons.home_work_rounded;
      case 'Jasa & Layanan': return Icons.handyman_rounded;
      case 'Pendidikan & Kursus': return Icons.school_rounded;
      case 'Otomotif & Bengkel': return Icons.car_repair_rounded;
      case 'Pertanian & Agribisnis': return Icons.agriculture_rounded;
      case 'Toko Online / Reseller': return Icons.shopping_bag_rounded;
      default: return Icons.store_rounded;
    }
  }

  // ── NOTIFICATION POPUP — kosong, tidak ada dummy ──
  void _showNotificationPopup(BuildContext context) {
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
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.97),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(children: [
              Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Notifikasi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('0 baru', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                ]),
              ),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 60, color: Colors.white.withOpacity(0.12)),
                      const SizedBox(height: 12),
                      const Text('Belum ada notifikasi', style: TextStyle(color: Colors.white38, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Aktivitas kamu akan muncul di sini', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── PREMIUM MODAL ──


  // Premium modal now uses shared widget from premium_modal.dart
  void _showPremiumModal(BuildContext context) =>
      showKreaseaPremiumModal(context);

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

// ═══════════════════ GLASS APPBAR HELPERS ═══════════════════

/// Badge kecil bertipe pill dengan glass style
class _GlassBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _GlassBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Mini chip kredit dengan emoji + angka
class _MiniCreditChip extends StatelessWidget {
  final String emoji;
  final int count;
  final int max;
  const _MiniCreditChip({required this.emoji, required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final isEmpty = count <= 0;
    final isLow = count == 1;
    final color = isEmpty ? Colors.redAccent : isLow ? Colors.orange : Colors.white54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isEmpty
            ? Colors.red.withOpacity(0.12)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$emoji $count',
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Tombol aksi glass untuk AppBar
class _GlassActionButton extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? bgColor;
  final VoidCallback? onTap;
  final Widget? child;

  const _GlassActionButton({
    this.icon,
    this.iconColor,
    this.bgColor,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? Colors.white.withOpacity(0.07);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: child != null
            ? EdgeInsets.zero
            : const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
        ),
        child: child ??
            Icon(
              icon!,
              size: 20,
              color: iconColor ?? Colors.white.withOpacity(0.85),
            ),
      ),
    );
  }
}
