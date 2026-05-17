import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
          _emailController.text.trim(), _passwordController.text);
      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Email atau password salah. Periksa kembali.';
          break;
        case 'invalid-email':
          msg = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          msg = 'Akun ini telah dinonaktifkan. Hubungi dukungan.';
          break;
        case 'too-many-requests':
          msg = 'Terlalu banyak percobaan. Tunggu beberapa menit.';
          break;
        case 'network-request-failed':
          msg = 'Tidak ada koneksi internet. Periksa jaringanmu.';
          break;
        default:
          msg = e.message ?? 'Terjadi kesalahan saat login.';
      }
      if (mounted) _showError(msg);
    } catch (e) {
      if (mounted) _showError('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Gagal login dengan Google.');
    } catch (e) {
      final msg = e.toString();
      // User cancel — jangan tampilkan error
      if (msg.contains('popup-closed') ||
          msg.contains('cancelled') ||
          msg.contains('AbortError') ||
          msg.contains('sign_in_canceled')) {
        return;
      }
      if (mounted) _showError(msg.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: Stack(
        children: [
          // ── Decorative background blobs ──────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: _Blob(
              size: size.width * 0.55,
              color: AppColors.grad2.withOpacity(isDark ? 0.25 : 0.15),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _Blob(
              size: size.width * 0.65,
              color: AppColors.grad1.withOpacity(isDark ? 0.2 : 0.10),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.grad2.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      )
                          .animate()
                          .scale(
                              delay: 100.ms,
                              duration: 500.ms,
                              curve: Curves.elasticOut)
                          .fadeIn(),

                      const SizedBox(height: 28),

                      // Heading
                      Text(
                        'Selamat Datang di',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 6),

                      Text(
                        'Kreasea — AI Content Studio',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms),

                      const SizedBox(height: 40),

                      // ── Email ──────────────────────────────────────────
                      TextFormField(
                        controller: _emailController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'contoh@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!v.contains('@')) {
                            return 'Masukkan email yang valid';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 400.ms)
                          .slideX(begin: -0.05, end: 0),

                      const SizedBox(height: 16),

                      // ── Password ──────────────────────────────────────
                      TextFormField(
                        controller: _passwordController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Minimal 6 karakter',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (v.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms)
                          .slideX(begin: 0.05, end: 0),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 450.ms),

                      const SizedBox(height: 8),

                      // ── Login Button ───────────────────────────────────
                      _GradientButton(
                        label: 'Masuk',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _login,
                      )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 20),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun?  ',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 550.ms),

                      const SizedBox(height: 32),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'atau',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12)),
                        ],
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 20),

                      // ── Google Sign-In — bekerja di web & Android ──────
                      _GoogleButton(
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        isDark: isDark,
                      )
                          .animate()
                          .fadeIn(delay: 650.ms, duration: 400.ms),

                      const SizedBox(height: 24),

                      // Guest mode link
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/dashboard'),
                          child: Text(
                            'Lanjut tanpa akun →',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : AppColors.primaryGradient,
          color: onPressed == null ? Colors.grey.shade400 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: AppColors.grad2.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isDark;

  const _GoogleButton({
    required this.isLoading,
    this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E35) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo colours
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                            ).createShader(
                                const Rect.fromLTWH(0, 0, 24, 24)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
