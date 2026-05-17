import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';

// ══════════════════════════════════════════════════════════════════
// BUSINESS PROFILE SCREEN
// ══════════════════════════════════════════════════════════════════
// Data pre-fill dari authStateProvider (Firestore) — termasuk
// data yang dibuat saat onboarding (Google displayName → businessName).
// Fix: gunakan ref.listen agar tetap update setelah stream emit.
// ══════════════════════════════════════════════════════════════════

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState
    extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descController = TextEditingController();
  final _audienceController = TextEditingController();
  final _customTypeController = TextEditingController();

  String? _selectedType;
  bool _isCustomType = false;
  bool _profileLoaded = false;
  bool _isLoading = false;

  // ── Daftar jenis usaha ─────────────────────────────────────────
  static const List<Map<String, dynamic>> _businessTypeOptions = [
    {'label': 'Makanan & Minuman', 'icon': Icons.restaurant_rounded},
    {'label': 'Kafe & Coffee Shop', 'icon': Icons.coffee_rounded},
    {'label': 'Bakery & Roti', 'icon': Icons.bakery_dining_rounded},
    {'label': 'Katering & Snack', 'icon': Icons.set_meal_rounded},
    {'label': 'Fashion & Pakaian', 'icon': Icons.checkroom_rounded},
    {'label': 'Aksesori & Perhiasan', 'icon': Icons.diamond_rounded},
    {'label': 'Kecantikan & Skincare', 'icon': Icons.face_retouching_natural_rounded},
    {'label': 'Salon & Barbershop', 'icon': Icons.content_cut_rounded},
    {'label': 'Kesehatan & Apotek', 'icon': Icons.local_pharmacy_rounded},
    {'label': 'Olahraga & Fitness', 'icon': Icons.fitness_center_rounded},
    {'label': 'Elektronik & Gadget', 'icon': Icons.devices_rounded},
    {'label': 'Furnitur & Interior', 'icon': Icons.chair_rounded},
    {'label': 'Properti & Kontrakan', 'icon': Icons.home_work_rounded},
    {'label': 'Jasa & Layanan', 'icon': Icons.handyman_rounded},
    {'label': 'Pendidikan & Kursus', 'icon': Icons.school_rounded},
    {'label': 'Otomotif & Bengkel', 'icon': Icons.car_repair_rounded},
    {'label': 'Pertanian & Agribisnis', 'icon': Icons.agriculture_rounded},
    {'label': 'Toko Online / Reseller', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Lainnya (ketik sendiri)', 'icon': Icons.edit_note_rounded},
  ];

  String? _selectedTone = 'Santai';
  static const List<String> _tones = [
    'Formal', 'Santai', 'Lucu & Humor', 'Elegan',
    "Syar'i", 'Gen Z / Gaul', 'Motivasi', 'Profesional',
  ];

  // ── Pre-fill controllers dari profil ─────────────────────────
  void _initFromProfile(UserProfile? profile) {
    if (profile == null || _profileLoaded) return;
    _profileLoaded = true;

    _businessNameController.text = profile.businessName;
    _descController.text = profile.businessDescription;
    _audienceController.text = profile.targetAudience;
    _selectedTone =
        profile.brandTone.isNotEmpty ? profile.brandTone : 'Santai';

    if (profile.businessType.isNotEmpty) {
      final matchedType = _businessTypeOptions
          .where((o) => o['label'] != 'Lainnya (ketik sendiri)')
          .map((o) => o['label'] as String)
          .contains(profile.businessType);
      if (!matchedType) {
        _selectedType = 'Lainnya (ketik sendiri)';
        _isCustomType = true;
        _customTypeController.text = profile.businessType;
      } else {
        _selectedType = profile.businessType;
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descController.dispose();
    _audienceController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  String get _effectiveBusinessType {
    if (_isCustomType) return _customTypeController.text.trim();
    return _selectedType ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      _showSnackbar('Mohon pilih jenis usaha terlebih dahulu',
          isError: true);
      return;
    }
    if (_isCustomType && _customTypeController.text.trim().isEmpty) {
      _showSnackbar('Mohon ketik jenis usahamu', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentProfile = ref.read(authStateProvider).valueOrNull;
      final updatedProfile = UserProfile(
        uid: currentProfile?.uid ?? 'guest',
        email: currentProfile?.email ?? '',
        businessName: _businessNameController.text.trim(),
        businessType: _effectiveBusinessType,
        brandTone: _selectedTone ?? 'Santai',
        targetAudience: _audienceController.text.trim(),
        businessDescription: _descController.text.trim(),
        isOnboardingComplete: true,
      );
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(updatedProfile);
      if (mounted) {
        _showSnackbar('Profil bisnis berhasil diperbarui! ✅');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) _showSnackbar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Listen auth state — pre-fill saat stream emit ─────────────
    ref.listen(authStateProvider, (_, next) {
      if (!_profileLoaded) {
        _initFromProfile(next.valueOrNull);
        if (mounted) setState(() {});
      }
    });

    // Juga coba baca langsung jika sudah ada nilainya
    if (!_profileLoaded) {
      _initFromProfile(ref.read(authStateProvider).valueOrNull);
    }

    final authAsync = ref.watch(authStateProvider);
    final currentProfile = authAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible App Bar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surfaceDark,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    size: 16, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.grad1.withOpacity(0.3),
                          AppColors.surfaceDark,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Decorative blob
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grad2.withOpacity(0.12),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar circle
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.grad2.withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  currentProfile?.businessName.isNotEmpty == true
                                      ? currentProfile!.businessName[0]
                                          .toUpperCase()
                                      : '🏪',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Identitas Bisnis',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (currentProfile?.email.isNotEmpty == true)
                                    Text(
                                      currentProfile!.email,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Form body ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    _InfoBanner(
                      message:
                          'Informasi ini mempengaruhi kualitas konten AI yang dihasilkan. Semakin lengkap, semakin relevan hasilnya.',
                    ),

                    const SizedBox(height: 20),

                    // ── Section: Identitas ─────────────────────────
                    _SectionHeader(
                        icon: Icons.store_rounded, title: 'Identitas Bisnis'),
                    const SizedBox(height: 12),

                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _glassField(
                            controller: _businessNameController,
                            label: 'Nama Bisnis / Brand',
                            icon: Icons.store_rounded,
                            hint: 'Contoh: Kedai Kopi Nusantara',
                            validator: (v) => v == null || v.isEmpty
                                ? 'Nama bisnis wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Target Audiens
                          _glassField(
                            controller: _audienceController,
                            label: 'Target Audiens',
                            icon: Icons.people_rounded,
                            hint: 'Contoh: Ibu rumah tangga, usia 25–40',
                            validator: (v) => v == null || v.isEmpty
                                ? 'Target audiens wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Deskripsi Bisnis
                          _glassField(
                            controller: _descController,
                            label: 'Deskripsi Singkat Bisnis',
                            icon: Icons.description_rounded,
                            hint: 'Ceritakan apa yang bisnismu jual / tawarkan',
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Deskripsi bisnis wajib diisi'
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Section: Jenis Usaha ───────────────────────
                    _SectionHeader(
                        icon: Icons.category_rounded, title: 'Jenis Usaha'),
                    const SizedBox(height: 12),

                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBusinessTypeGrid(),
                          if (_isCustomType) ...[
                            const SizedBox(height: 12),
                            _glassField(
                              controller: _customTypeController,
                              label: 'Ketik jenis usahamu',
                              icon: Icons.edit_rounded,
                              validator: (v) =>
                                  _isCustomType && (v == null || v.isEmpty)
                                      ? 'Wajib diisi'
                                      : null,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Section: Tone Bahasa ───────────────────────
                    _SectionHeader(
                        icon: Icons.record_voice_over_rounded,
                        title: 'Tone / Gaya Bahasa AI'),
                    const SizedBox(height: 12),

                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: _buildToneChips(),
                    ),

                    const SizedBox(height: 32),

                    // ── Save Button ────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.grad1, AppColors.grad2]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.grad2.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
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
                                  Icon(Icons.save_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Business Type Grid ────────────────────────────────────────
  Widget _buildBusinessTypeGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _businessTypeOptions.map((opt) {
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final isSelected = _selectedType == label;
        final isLainnya = label == 'Lainnya (ketik sendiri)';

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = label;
              _isCustomType = isLainnya;
              if (!isLainnya) _customTypeController.clear();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [AppColors.grad1, AppColors.grad2])
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.12),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.grad2.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.6)),
                const SizedBox(width: 6),
                Text(
                  isLainnya ? 'Lainnya...' : label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Tone Chips ────────────────────────────────────────────────
  Widget _buildToneChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tones.map((tone) {
        final isSelected = _selectedTone == tone;
        return GestureDetector(
          onTap: () => setState(() => _selectedTone = tone),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF00B4DB), Color(0xFF3D5AFE)])
                  : null,
              color:
                  isSelected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Text(
              tone,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white38),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
        prefixIcon:
            Icon(icon, color: AppColors.accentLight.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.accentLight)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error)),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.grad1.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.grad1, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.info.withOpacity(0.9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
