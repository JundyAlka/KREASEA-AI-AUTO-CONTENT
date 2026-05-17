import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../main.dart' show isFirebaseInitialized;

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String _sentEmail = '';

  // Cooldown untuk resend (60 detik)
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownSeconds = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) t.cancel();
      });
    });
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    // Cek Firebase
    if (!isFirebaseInitialized) {
      _showError(
        'Firebase tidak aktif. Pastikan koneksi internet aktif lalu restart aplikasi.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      await authService.resetPassword(email);
      if (mounted) {
        setState(() {
          _emailSent = true;
          _sentEmail = email;
        });
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        // Hapus prefix Exception: untuk tampilan yang lebih bersih
        final msg = e.toString().replaceFirst('Exception: ', '');
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_sentEmail);
      if (mounted) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Email reset dikirim ulang! Cek inbox & spam.'),
            ]),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
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
          // Background blobs
          Positioned(
            top: -60,
            right: -60,
            child: _Blob(
              size: size.width * 0.55,
              color: AppColors.grad2.withOpacity(isDark ? 0.2 : 0.12),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _Blob(
              size: size.width * 0.60,
              color: AppColors.grad1.withOpacity(isDark ? 0.15 : 0.08),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
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

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 24),
                      child: _emailSent
                          ? _buildSuccessView(isDark)
                          : _buildFormView(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut).fadeIn(),

          const SizedBox(height: 28),

          Text(
            'Lupa Password?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          Text(
            'Masukkan email akunmu. Kami akan mengirimkan\nlink untuk reset password.',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

          // Warning jika Firebase tidak aktif
          if (!isFirebaseInitialized) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Firebase tidak aktif. Reset password memerlukan koneksi internet.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 40),

          // Email field
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
              if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
              if (!v.contains('@') || !v.contains('.')) return 'Masukkan email yang valid';
              return null;
            },
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideX(begin: -0.05, end: 0),

          const SizedBox(height: 28),

          // Send button
          GestureDetector(
            onTap: _isLoading ? null : _sendReset,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                gradient: _isLoading ? null : AppColors.primaryGradient,
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
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Kirim Link Reset',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                'Kembali ke Login',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    final canResend = _cooldownSeconds <= 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withOpacity(0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(),

        const SizedBox(height: 32),

        Text(
          'Email Terkirim! 🎉',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 12),

        Text(
          'Link reset password telah dikirim ke:',
          style: TextStyle(
            fontSize: 14,
            height: 1.7,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 4),
        Text(
          _sentEmail,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 16),

        // Tips
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tipRow(Icons.inbox_rounded, Colors.blue, 'Cek folder Inbox emailmu'),
              const SizedBox(height: 8),
              _tipRow(Icons.warning_amber_rounded, Colors.orange, 'Kalau tidak ada, cek folder Spam/Junk'),
              const SizedBox(height: 8),
              _tipRow(Icons.schedule_rounded, Colors.green, 'Email bisa makan waktu 1–2 menit'),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 32),

        GestureDetector(
          onTap: () => context.go('/login'),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grad2.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Kembali ke Login',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 16),

        // Resend button dengan cooldown
        Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : TextButton(
                  onPressed: canResend ? _resendEmail : null,
                  child: Text(
                    canResend
                        ? '🔄 Kirim ulang ke email lain atau kirim ulang'
                        : '⏳ Kirim ulang dalam ${_cooldownSeconds}s',
                    style: TextStyle(
                      color: canResend ? AppColors.primary : Colors.white24,
                      fontSize: 13,
                    ),
                  ),
                ),
        ).animate().fadeIn(delay: 550.ms),

        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _emailSent = false;
                _emailController.clear();
              });
            },
            child: const Text(
              'Ganti email',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _tipRow(IconData icon, Color color, String text) {
    return Row(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ),
    ]);
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
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
