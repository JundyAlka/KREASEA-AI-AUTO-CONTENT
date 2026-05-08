import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'config/router.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'theme/theme_provider.dart';

/// Global flag: true jika Firebase berhasil diinisialisasi
bool isFirebaseInitialized = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AppStartupWidget()));
}

class AppStartupWidget extends StatefulWidget {
  const AppStartupWidget({super.key});

  @override
  State<AppStartupWidget> createState() => _AppStartupWidgetState();
}

class _AppStartupWidgetState extends State<AppStartupWidget>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // ── 1. Load .env (non-fatal if fails) ──
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('DOTENV LOAD WARNING: $e — akan gunakan fallback keys');
    }

    // ── 2. Init Firebase (non-fatal if fails → guest mode) ──
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      isFirebaseInitialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e, stack) {
      debugPrint('⚠️ Firebase init failed (app will run in guest mode): $e');
      debugPrint(stack.toString());
      isFirebaseInitialized = false;
    }

    // ── 3. Always proceed to app ──
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.surfaceDark,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grad2.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 44,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                        begin: 1.0,
                        end: 1.06,
                        duration: 1800.ms,
                        curve: Curves.easeInOut),
                const SizedBox(height: 32),
                // App name
                const Text(
                  'Kreasea',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                const SizedBox(height: 6),
                const Text(
                  'AI Content Studio untuk UMKM Indonesia',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 14,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                const SizedBox(height: 48),
                // Loading indicator
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      backgroundColor: Color(0xFF2A2A45),
                      color: AppColors.accentLight,
                      minHeight: 3,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                const SizedBox(height: 16),
                const Text(
                  'Menyiapkan Aplikasi...',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
              ],
            ),
          ),
        ),
      );
    }

    return const KreaseaApp();
  }
}

class KreaseaApp extends ConsumerWidget {
  const KreaseaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Kreasea',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
