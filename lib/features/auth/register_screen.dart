import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Password tidak cocok. Periksa kembali konfirmasi passwordmu.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
          _emailController.text.trim(), _passwordController.text);
      if (mounted) context.go('/onboarding');
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg =
              'Email ini sudah terdaftar. Coba login atau gunakan email lain.';
          break;
        case 'weak-password':
          msg = 'Password terlalu lemah. Gunakan minimal 8 karakter.';
          break;
        case 'invalid-email':
          msg = 'Format email tidak valid.';
          break;
        case 'operation-not-allowed':
          msg = 'Registrasi email belum diaktifkan. Hubungi admin.';
          break;
        case 'network-request-failed':
          msg = 'Tidak ada koneksi internet. Periksa jaringanmu.';
          break;
        default:
          msg = e.message ?? 'Terjadi kesalahan saat mendaftar.';
      }
      if (mounted) _showError(msg);
    } catch (e) {
      if (mounted) _showError('Terjadi kesalahan: ${e.toString().split(']').last.trim()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    // Google Sign-In di web memerlukan konfigurasi Authorized JS Origins
    if (kIsWeb) {
      _showGoogleWebNotice();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message ?? 'Gagal masuk dengan Google.');
    } catch (e) {
      if (mounted) _showError('Gagal masuk dengan Google. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGoogleWebNotice() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_rounded,
                    color: Colors.orange, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Login Google (Web)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                'Login Google via browser memerlukan konfigurasi tambahan.\n\n'
                'Gunakan email & password, atau buka aplikasi di perangkat Android untuk login dengan Google.',
                style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentLight,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mengerti',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        duration: const Duration(seconds: 4),
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
          // Decorative blobs
          Positioned(
            top: -80,
            left: -60,
            child: _blob(size.width * 0.6,
                AppColors.grad1.withOpacity(isDark ? 0.22 : 0.12)),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _blob(size.width * 0.5,
                AppColors.grad2.withOpacity(isDark ? 0.18 : 0.10)),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                onPressed: () => context.go('/login'),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 60, 28, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header icon
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.grad2.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded,
                              color: Colors.white, size: 34),
                        ),
                      )
                          .animate()
                          .scale(
                              delay: 100.ms,
                              duration: 500.ms,
                              curve: Curves.elasticOut)
                          .fadeIn(),

                      const SizedBox(height: 24),

                      Text(
                        'Buat Akun Baru',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 6),

                      Text(
                        'Mulai perjalanan bisnis digitalmu hari ini',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 36),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'contoh@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Masukkan email yang valid';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: 350.ms)
                          .slideX(begin: -0.05, end: 0),

                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          .fadeIn(delay: 400.ms)
                          .slideX(begin: 0.05, end: 0),

                      const SizedBox(height: 14),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          hintText: 'Ulangi password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Konfirmasi password tidak boleh kosong';
                          }
                          if (v != _passwordController.text) {
                            return 'Password tidak cocok';
                          }
                          return null;
                        },
                      )
                          .animate()
                          .fadeIn(delay: 450.ms)
                          .slideX(begin: -0.05, end: 0),

                      const SizedBox(height: 28),

                      // Register Button
                      GestureDetector(
                        onTap: _isLoading ? null : _register,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : AppColors.primaryGradient,
                            color: _isLoading ? Colors.grey.shade400 : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isLoading
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
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 20),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun?  ',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 550.ms),

                      const SizedBox(height: 28),

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

                      // Google Button
                      GestureDetector(
                        onTap: _isLoading ? null : _loginWithGoogle,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E35)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDark ? Colors.white12 : Colors.black12,
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4285F4),
                                      Color(0xFF34A853)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.g_mobiledata,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                kIsWeb
                                    ? 'Daftar dengan Google (Android)'
                                    : 'Daftar dengan Google',
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
                      ).animate().fadeIn(delay: 650.ms),
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

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox.expand(),
      ),
    );
  }
}
