import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';

// ══════════════════════════════════════════════════════════════════
// SPLASH ROUTER SCREEN
// ══════════════════════════════════════════════════════════════════
// Ditampilkan saat app launch. Bertugas:
//   1. Menampilkan splash animatif minimal 2.5 detik
//   2. Mengecek apakah onboarding sudah pernah ditampilkan
//   3. Routing ke: onboarding | login | dashboard
// ══════════════════════════════════════════════════════════════════

class SplashRouterScreen extends ConsumerStatefulWidget {
  const SplashRouterScreen({super.key});

  @override
  ConsumerState<SplashRouterScreen> createState() => _SplashRouterScreenState();
}

class _SplashRouterScreenState extends ConsumerState<SplashRouterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _navigate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    // Minimum splash duration: 2.5 detik
    final timer = Future.delayed(const Duration(milliseconds: 2500));

    // Parallel: cek onboarding & auth
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('onboarding_seen') ?? false;

    await timer; // tunggu minimum splash

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      context.go('/onboarding');
      return;
    }

    // Cek auth state
    if (isFirebaseInitialized) {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user != null && user.uid.isNotEmpty && user.uid != 'guest') {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    } else {
      // Firebase gagal → langsung ke dashboard (guest mode)
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Stack(
        children: [
          // Gradient background blobs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grad2.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grad1.withOpacity(0.12),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo pulsing
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.06),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.grad2.withOpacity(
                              0.35 + _pulseController.value * 0.2,
                            ),
                            blurRadius: 30 + _pulseController.value * 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Kreasea',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                const SizedBox(height: 8),

                Text(
                  'AI Content Studio untuk UMKM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 60),

                // Loading dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) {
                        final delay = i * 0.33;
                        final t = (_pulseController.value + delay) % 1.0;
                        final opacity = 0.3 + (t * 0.7);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentLight.withOpacity(opacity),
                          ),
                        );
                      },
                    );
                  }),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),

          // Version at bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.2.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ),
          ),
        ],
      ),
    );
  }
}
