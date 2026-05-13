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

void main() async {
  // Wajib dipanggil sebelum apapun yang async
  WidgetsFlutterBinding.ensureInitialized();

  // Tangkap semua uncaught error agar tidak silent crash di release
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 FlutterError: ${details.exception}');
    debugPrint(details.stack.toString());
    // Jangan rethrow — biarkan app tetap berjalan
  };

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
  String _statusMsg = 'Menyiapkan Aplikasi...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // ── 1. Load .env (non-fatal) ──────────────────────────
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('✅ .env loaded');
    } catch (e) {
      debugPrint('⚠️ .env tidak ditemukan, lanjut tanpa env: $e');
    }

    // ── 2. Init Firebase (non-fatal → guest mode jika gagal) ─
    if (mounted) setState(() => _statusMsg = 'Menghubungkan Firebase...');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firebase init timeout (10s)'),
      );
      isFirebaseInitialized = true;
      debugPrint('✅ Firebase initialized');
    } catch (e, stack) {
      debugPrint('⚠️ Firebase gagal (app jalan dalam Guest Mode): $e');
      debugPrint(stack.toString());
      isFirebaseInitialized = false;
      // Lanjut — tidak crash
    }

    // ── 3. Tampilkan app ──────────────────────────────────
    if (mounted) {
      setState(() {
        _statusMsg = 'Selesai!';
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _SplashScreen(statusMsg: _statusMsg),
      );
    }
    return const KreaseaApp();
  }
}

// ── Splash Screen ─────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  final String statusMsg;
  const _SplashScreen({required this.statusMsg});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(
                  color: AppColors.grad2.withOpacity(0.5),
                  blurRadius: 30, spreadRadius: 2,
                )],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 44),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.06, duration: 1800.ms, curve: Curves.easeInOut),

            const SizedBox(height: 32),
            const Text(
              'Kreasea',
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 2.0),
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

            const SizedBox(height: 6),
            const Text(
              'AI Content Studio untuk UMKM Indonesia',
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

            const SizedBox(height: 48),
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
            Text(
              statusMsg,
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
          ],
        ),
      ),
    );
  }
}

// ── Main App ──────────────────────────────────────────────────
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
