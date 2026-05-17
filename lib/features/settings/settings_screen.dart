import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/multi_key_ai_manager.dart';
import '../../services/credit_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/glass_container.dart';
import '../../main.dart' show appVersion, isBetaVersion;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isNotifEnabled = false; // Default off — no dummy notif
  bool _isResettingCooldown = false;
  bool _isRefreshingCredit = false;
  Map<String, String> _keyStatusCache = {};

  @override
  void initState() {
    super.initState();
    _refreshKeyStatus();
  }

  void _refreshKeyStatus() {
    setState(() {
      _keyStatusCache = MultiKeyAiManager().keyStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final profile = authAsync.valueOrNull;
    final isGuest = profile == null || profile.uid == 'guest';
    final isLoggedIn = !isGuest;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
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

                  // ── USER PROFILE CARD ──────────────────────────────────
                  if (isLoggedIn) ...[
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                (profile?.businessName.isNotEmpty == true
                                        ? profile!.businessName[0]
                                        : profile?.email.isNotEmpty == true
                                            ? profile!.email[0]
                                            : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.businessName.isNotEmpty == true
                                      ? profile!.businessName
                                      : 'Pengguna Kreasea',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 12,
                                  ),
                                ),
                                if (profile?.businessType.isNotEmpty == true)
                                  Text(
                                    profile!.businessType,
                                    style: TextStyle(
                                      color: AppColors.accentLight.withOpacity(0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified_rounded, color: AppColors.accentLight, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (!isLoggedIn) ...[
                    // Guest state
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.account_circle_rounded, size: 56, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('Kamu belum login',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text('Login untuk menyimpan progres dan sinkronisasi data',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Masuk Sekarang',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── AKUN BISNIS ──────────────────────────────────────
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

                  // ── INTEGRASI SOSIAL MEDIA ───────────────────────────
                  _sectionTitle('Integrasi Sosial Media'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    child: Column(
                      children: [
                        _glassTile(
                          icon: Icons.camera_alt_rounded,
                          title: 'Instagram',
                          subtitle: 'Belum terhubung',
                          color: const Color(0xFFE1306C),
                          trailing: _connectButton('Instagram'),
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

                  // ── PREFERENSI APLIKASI ──────────────────────────────
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
                          icon: Icons.notifications_rounded,
                          title: 'Notifikasi',
                          subtitle: _isNotifEnabled ? 'Aktif' : 'Nonaktif',
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

                  // ── TENTANG & LAINNYA ────────────────────────────────
                  _sectionTitle('Tentang'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    child: Column(
                      children: [
                        _glassTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Versi Aplikasi',
                          subtitle: 'KreaSea v$appVersion',
                          color: Colors.teal,
                          trailing: isBetaVersion
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('BETA',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5)),
                                )
                              : null,
                        ),
                        Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 60),
                        _glassTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Kebijakan Privasi',
                          subtitle: 'Baca bagaimana kami menjaga datamu',
                          color: Colors.blueGrey,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  // ── INFO DEVELOPER (BETA) ─────────────────────────────
                  const SizedBox(height: 24),
                  _sectionTitle('Info Developer (Beta Testing)'),
                  const SizedBox(height: 8),
                  _buildDeveloperSection(isLoggedIn),

                  // ── LOGOUT ───────────────────────────────────────────
                  if (isLoggedIn) ...[
                    const SizedBox(height: 24),
                    GlassContainer(
                      child: _glassTile(
                        icon: Icons.logout_rounded,
                        title: 'Keluar',
                        subtitle: 'Logout dari akun ini',
                        color: AppColors.error,
                        isDestructive: true,
                        onTap: () => _confirmLogout(context),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Center(
                    child: Text('Kreasea © 2025 — UMKM Indonesia 🇮🇩',
                        style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ),
                  if (isBetaVersion)
                    const Center(
                      child: Text('Versi Beta — Feedback sangat diterima!',
                          style: TextStyle(color: Colors.white12, fontSize: 10)),
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
        child: const Text('Hubungkan',
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
      trailing: trailing ?? (onTap != null
          ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24)
          : null),
      onTap: onTap,
    );
  }

  // ── DEVELOPER SECTION (Beta Testing) ──────────────────────────────
  Widget _buildDeveloperSection(bool isLoggedIn) {
    final aiManager = MultiKeyAiManager();
    final readyKeys = aiManager.readyKeyCount;
    final totalKeys = aiManager.keyStatus.length;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.developer_mode_rounded, color: Colors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Beta Testing Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Kontrol API key & credit untuk pengujian', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text('BETA', style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ]),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 16),

          // Status API Keys
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Status Gemini API Keys', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: _refreshKeyStatus,
              child: Row(children: [
                Icon(Icons.refresh_rounded, size: 14, color: AppColors.accentLight),
                const SizedBox(width: 4),
                Text('Refresh', style: TextStyle(color: AppColors.accentLight, fontSize: 11)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),

          // Key status list
          ..._keyStatusCache.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Text(e.key, style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
              const SizedBox(width: 8),
              Expanded(
                child: Text(e.value,
                    style: TextStyle(
                      fontSize: 11,
                      color: e.value.contains('✅') ? Colors.greenAccent
                          : e.value.contains('⏳') ? Colors.orange
                          : Colors.white38,
                    )),
              ),
            ]),
          )).toList(),

          // Summary
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: readyKeys > 0
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: readyKeys > 0
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(
                readyKeys > 0 ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 14,
                color: readyKeys > 0 ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 6),
              Text(
                '$readyKeys dari ${totalKeys > 0 ? totalKeys - (aiManager.keyStatus.containsKey('OpenAI') ? 1 : 0) : 0} key Gemini siap digunakan',
                style: TextStyle(
                  fontSize: 11,
                  color: readyKeys > 0 ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 16),

          // Reset Cooldown button
          _devActionButton(
            icon: Icons.restart_alt_rounded,
            label: '🔑 Reset Cooldown API Key',
            subtitle: 'Paksa semua key siap digunakan sekarang',
            color: Colors.blue,
            isLoading: _isResettingCooldown,
            onTap: () async {
              setState(() => _isResettingCooldown = true);
              await Future.delayed(const Duration(milliseconds: 300));
              MultiKeyAiManager().manualResetAllCooldowns();
              _refreshKeyStatus();
              setState(() => _isResettingCooldown = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('Semua cooldown API key direset! ✅'),
                    ]),
                    backgroundColor: Colors.blue.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 10),

          // Refresh Credit button
          if (isLoggedIn)
            _devActionButton(
              icon: Icons.credit_score_rounded,
              label: '💳 Refresh Credit Harian',
              subtitle: 'Reset credit ke nilai awal (testing)',
              color: Colors.green,
              isLoading: _isRefreshingCredit,
              onTap: () async {
                setState(() => _isRefreshingCredit = true);
                try {
                  final creditService = ref.read(creditServiceProvider);
                  // Baca plan dulu
                  final credits = await creditService.fetchCredits();
                  await creditService.refillCredits(plan: credits.plan);
                  ref.invalidate(userCreditsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Credit berhasil di-refresh! ✅'),
                        ]),
                        backgroundColor: const Color(0xFF4CAF50),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal refresh credit: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isRefreshingCredit = false);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _devActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(children: [
            if (isLoading)
              SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color))
            else
              Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withOpacity(0.5)),
          ]),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final profile = ref.read(authStateProvider).valueOrNull;

    final name = profile?.businessName.isNotEmpty == true
        ? profile!.businessName
        : profile?.email ?? 'akun ini';

    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Kamu akan keluar dari\n"$name"',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(c),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(c);
                      try {
                        await ref.read(authServiceProvider).signOut();
                      } catch (e) {
                        debugPrint('Logout error: $e');
                      }
                      if (mounted) context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Keluar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
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
          'Fitur integrasi $platform akan segera hadir di update berikutnya.',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(c),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentLight,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Oke'),
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
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  height: 180,
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
                            const Text('Unlimited Power.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
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
                      _benefitItem(Icons.bolt_rounded, 'Unlimited AI', 'Generate konten tanpa batas harian', AppColors.warning),
                      _benefitItem(Icons.speed_rounded, 'Fast Processing', 'Prioritas antrian server', AppColors.info),
                      _benefitItem(Icons.hd_rounded, 'HD Downloads', 'Gambar resolusi 4K untuk cetak', AppColors.success),
                      _benefitItem(Icons.auto_fix_high_rounded, 'No Watermark', 'Hapus watermark otomatis', AppColors.accent),
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
                          child: const Text('Langganan Sekarang — Rp 49.000/bln',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tidak sekarang', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
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
