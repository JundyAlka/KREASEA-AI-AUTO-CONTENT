import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════
// ONBOARDING SCREEN — 4 Slide Modern
// ══════════════════════════════════════════════════════════════════
// Ditampilkan SEKALI saat pertama kali install.
// Setelah selesai, flag `onboarding_seen = true` disimpan.
// Tombol "Lewati" dipindah SETELAH PageView dalam Stack agar
// z-index lebih tinggi dan bisa diklik.
// ══════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingData(
      gradient: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
      icon: Icons.auto_awesome_rounded,
      emoji: '✨',
      title: 'Selamat Datang\ndi Kreasea',
      subtitle:
          'Platform AI Content Studio #1 untuk UMKM Indonesia. Buat konten profesional dalam hitungan detik.',
      badge: 'AI-Powered',
    ),
    _OnboardingData(
      gradient: [Color(0xFFE91E63), Color(0xFF9C27B0)],
      icon: Icons.edit_note_rounded,
      emoji: '✍️',
      title: 'Caption Viral\nTanpa Batas',
      subtitle:
          'AI kami paham konteks bisnis kamu. Hasilkan 3 variasi caption dalam 1 klik — Emotional, Storytelling, Informative.',
      badge: 'Gemini AI',
    ),
    _OnboardingData(
      gradient: [Color(0xFF00BCD4), Color(0xFF3D5AFE)],
      icon: Icons.image_rounded,
      emoji: '🎨',
      title: 'Gambar Produk\nBerkualitas Tinggi',
      subtitle:
          'Deskripsikan idemu dalam bahasa Indonesia, Kreasea otomatis membuat gambar produk yang memukau untuk postinganmu.',
      badge: 'Stability AI',
    ),
    _OnboardingData(
      gradient: [Color(0xFF4CAF50), Color(0xFF009688)],
      icon: Icons.rocket_launch_rounded,
      emoji: '🚀',
      title: 'Gratis Mulai\nHari Ini',
      subtitle:
          'Dapatkan kredit harian gratis setiap hari. Generate caption dan gambar tanpa biaya. Upgrade kapan saja kamu mau.',
      badge: 'Free Forever',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Stack(
        children: [
          // ── Animated gradient background ─────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  slide.gradient[0].withOpacity(0.15),
                  AppColors.surfaceDark,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Background decorative circles ────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: slide.gradient[0].withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: slide.gradient[1].withOpacity(0.08),
              ),
            ),
          ),

          // ── Page content (bawah stack) ───────────────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _SlidePage(data: _slides[index]);
            },
          ),

          // ── Bottom controls ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == _currentPage
                                ? slide.gradient[0]
                                : Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Next / Get Started button
                    GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: slide.gradient,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: slide.gradient[0].withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage < _slides.length - 1
                                ? 'Lanjut →'
                                : '🚀 Mulai Gratis',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Lewati button — di BAWAH next button ────
                    // Gunakan TextButton bukan GestureDetector agar
                    // tap area lebih reliable dan tidak tertimpa PageView
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.07),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lewati',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model per slide ─────────────────────────────────────────
class _OnboardingData {
  final List<Color> gradient;
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final String badge;

  const _OnboardingData({
    required this.gradient,
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

// ── Single slide widget ───────────────────────────────────────────
class _SlidePage extends StatelessWidget {
  final _OnboardingData data;
  const _SlidePage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: data.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: data.gradient[0].withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(data.icon, color: Colors.white.withOpacity(0.2), size: 100),
                Icon(data.icon, color: Colors.white, size: 56),
              ],
            ),
          )
              .animate()
              .scale(
                delay: 100.ms,
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(),

          const SizedBox(height: 16),

          // Badge pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: data.gradient[0].withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: data.gradient[0].withOpacity(0.3)),
            ),
            child: Text(
              '${data.emoji}  ${data.badge}',
              style: TextStyle(
                color: data.gradient[0],
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 28),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms),
        ],
      ),
    );
  }
}
