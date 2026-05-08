import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/glass_container.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isNotifEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header
            const GlassGradientHeader(
              title: 'Pengaturan',
              subtitle: 'Kelola akun, integrasi, dan preferensimu',
              icon: Icons.settings_rounded,
              gradientColors: [Color(0xFF1A1A2E), Color(0xFF3949AB)],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Akun Bisnis
                  _sectionTitle('Akun Bisnis'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    child: Column(
                      children: [
                        _glassTile(
                          icon: Icons.storefront_rounded,
                          title: 'Profil Usaha',
                          subtitle: 'Atur informasi bisnis & logo',
                          color: AppColors.grad1,
                          onTap: () => context.go('/settings/business_profile'),
                        ),
                        Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 60),
                        _glassTile(
                          icon: Icons.diamond_rounded,
                          title: 'Langganan Premium',
                          subtitle: 'Upgrade fitur AI unlimited',
                          color: Colors.amber,
                          onTap: () => _showPremiumModal(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle('Integrasi Sosial Media'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    child: Column(
                      children: [
                        _glassTile(
                          icon: Icons.camera_alt_rounded,
                          title: 'Instagram',
                          subtitle: 'Terhubung sebagai @demo_user',
                          color: const Color(0xFFE1306C),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Aktif', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 60),
                        _glassTile(
                          icon: Icons.music_note_rounded,
                          title: 'TikTok',
                          subtitle: 'Belum terhubung',
                          color: const Color(0xFF69C9D0),
                          trailing: _connectButton('TikTok'),
                        ),
                        Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 60),
                        _glassTile(
                          icon: Icons.facebook_rounded,
                          title: 'Facebook Page',
                          subtitle: 'Belum terhubung',
                          color: const Color(0xFF1877F2),
                          trailing: _connectButton('Facebook'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle('Preferensi Aplikasi'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    child: Column(
                      children: [
                        _glassTile(
                          icon: Icons.dark_mode_rounded,
                          title: 'Mode Gelap',
                          subtitle: 'Tampilan nyaman di mata',
                          color: AppColors.accent,
                          trailing: Switch(
                            value: Theme.of(context).brightness == Brightness.dark,
                            onChanged: (v) => ref.read(themeModeProvider.notifier).toggleTheme(v),
                            activeColor: AppColors.accentLight,
                          ),
                        ),
                        Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 60),
                        _glassTile(
                          icon: Icons.language_rounded,
                          title: 'Bahasa',
                          subtitle: 'Indonesia (ID)',
                          color: AppColors.info,
                        ),
                        Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 60),
                        _glassTile(
                          icon: Icons.notifications_active_rounded,
                          title: 'Notifikasi',
                          subtitle: 'Jadwal post & promo',
                          color: AppColors.warning,
                          trailing: Switch(
                            value: _isNotifEnabled,
                            onChanged: (v) => setState(() => _isNotifEnabled = v),
                            activeColor: AppColors.accentLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Logout
                  GlassContainer(
                    child: _glassTile(
                      icon: Icons.logout_rounded,
                      title: 'Keluar',
                      subtitle: '',
                      color: AppColors.error,
                      isDestructive: true,
                      onTap: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Center(
                    child: Text('Kreasea v1.0.0', style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.35),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _connectButton(String platform) {
    return GestureDetector(
      onTap: () => _showConnectDialog(platform),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.grad1, AppColors.grad2]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('Hubungkan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _glassTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : Colors.white,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white38))
          : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
      onTap: onTap,
    );
  }

  void _showConnectDialog(String platform) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hubungkan $platform', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Anda akan dialihkan ke halaman login $platform untuk memberikan izin akses posting.',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Berhasil menghubungkan $platform (Simulasi)')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLight,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showPremiumModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Premium header
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20, top: -20,
                        child: Icon(Icons.diamond_rounded, size: 150, color: Colors.white.withOpacity(0.12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRO PLAN', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                            const SizedBox(height: 6),
                            const Text('Unlimited Power.', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 16, right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _benefitItem(Icons.bolt_rounded, 'Unlimited AI', 'Buat konten tanpa batas harian', AppColors.warning),
                      _benefitItem(Icons.speed_rounded, 'Fast Processing', 'Prioritas antrian server', AppColors.info),
                      _benefitItem(Icons.hd_rounded, 'HD Image Downloads', 'Resolusi gambar 4K untuk cetak', AppColors.success),
                      _benefitItem(Icons.auto_fix_high_rounded, 'Remove Watermarks', 'Hapus watermark otomatis', AppColors.accent),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Langganan Sekarang - Rp 49.000/bln', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Pulihkan Pembelian', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefitItem(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
