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

/// App version & beta flag
const String appVersion = '1.3.0-beta';
const bool isBetaVersion = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler — mencegah silent crash di release
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 FlutterError: ${details.exception}');
    debugPrint(details.stack.toString());
  };

  // Load .env (non-fatal)
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env loaded');
  } catch (e) {
    debugPrint('⚠️ .env tidak ditemukan: $e');
  }

  // Init Firebase (non-fatal → guest mode jika gagal)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Firebase init timeout'),
    );
    isFirebaseInitialized = true;
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase gagal — Guest Mode: $e');
    isFirebaseInitialized = false;
  }

  // Animate.defaultDuration untuk seluruh app
  Animate.restartOnHotReload = true;

  runApp(const ProviderScope(child: KreaseaApp()));
}

// ── Main App ──────────────────────────────────────────────────────
class KreaseaApp extends ConsumerWidget {
  const KreaseaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'KreaSea BETA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
