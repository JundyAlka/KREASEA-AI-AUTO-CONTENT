import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/credit_service.dart';
import '../../services/multi_key_ai_manager.dart';
import '../../theme/app_theme.dart';
import 'premium_modal.dart';

// ══════════════════════════════════════════════════════════════════
// CREDIT BADGE WIDGET — untuk AppBar
// ══════════════════════════════════════════════════════════════════

class CreditBadge extends ConsumerWidget {
  final CreditType type;
  final Color accentColor;

  const CreditBadge({
    super.key,
    required this.type,
    this.accentColor = AppColors.accentLight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(userCreditsProvider);

    return creditsAsync.when(
      data: (credits) {
        final count = type == CreditType.image
            ? credits.imageCredits
            : credits.captionCredits;
        final max = type == CreditType.image
            ? credits.imageCreditMax
            : credits.captionCreditMax;
        final label = type == CreditType.image ? '🖼️' : '✍️';
        final isLow = count <= 1;
        final isEmpty = count <= 0;

        return GestureDetector(
          onTap: () => _showCreditDetail(context, ref, credits),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: isEmpty
                  ? Colors.red.withOpacity(0.2)
                  : isLow
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEmpty
                    ? Colors.red.withOpacity(0.5)
                    : isLow
                        ? Colors.orange.withOpacity(0.4)
                        : Colors.white12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEmpty ? Icons.block_rounded : Icons.bolt_rounded,
                  color: isEmpty
                      ? Colors.redAccent
                      : isLow
                          ? Colors.orange
                          : Colors.amber,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '$label $count/$max',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isEmpty
                        ? Colors.redAccent
                        : isLow
                            ? Colors.orange
                            : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: const SizedBox(
          width: 40,
          height: 12,
          child: LinearProgressIndicator(backgroundColor: Colors.transparent),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showCreditDetail(
      BuildContext context, WidgetRef ref, UserCredits credits) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreditDetailSheet(credits: credits, ref: ref),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CREDIT DETAIL BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════

class CreditDetailSheet extends StatefulWidget {
  final UserCredits credits;
  final WidgetRef ref;

  const CreditDetailSheet(
      {super.key, required this.credits, required this.ref});

  @override
  State<CreditDetailSheet> createState() => _CreditDetailSheetState();
}

class _CreditDetailSheetState extends State<CreditDetailSheet> {
  bool _isRefreshing = false;

  Future<void> _refreshCredit() async {
    setState(() => _isRefreshing = true);
    try {
      final service = widget.ref.read(creditServiceProvider);
      await service.refillCredits(plan: widget.credits.plan);
      // Juga reset cooldown API key saat refresh credit (untuk testing)
      MultiKeyAiManager().manualResetAllCooldowns();
      widget.ref.invalidate(userCreditsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Credit & API key direset! Siap generate lagi ✅')),
            ]),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal refresh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.ref.read(creditServiceProvider);
    final timeLeft = service.formatTimeUntilReset();
    final credits = widget.credits;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Credit Harian Kamu',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      'Reset otomatis dalam $timeLeft',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),

              // ── Plan badge — bisa diklik untuk lihat Pro modal ──
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  showKreaseaPremiumModal(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: credits.plan == 'premium'
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
                        : credits.plan == 'pro'
                            ? const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)])
                            : const LinearGradient(
                                colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_rounded,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        credits.plan == 'free'
                            ? 'Free → PRO'
                            : credits.plan.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Image Credits bar
          _CreditBar(
            icon: '🖼️',
            label: 'Image Generate',
            subtitle: 'Buat desain & banner AI',
            current: credits.imageCredits,
            max: credits.imageCreditMax,
            color: const Color(0xFFE91E63),
          ),

          const SizedBox(height: 14),

          // Caption Credits bar
          _CreditBar(
            icon: '✍️',
            label: 'Caption AI',
            subtitle: 'Generate caption & teks AI',
            current: credits.captionCredits,
            max: credits.captionCreditMax,
            color: const Color(0xFF3D5AFE),
          ),

          const SizedBox(height: 24),

          // ── BETA: Tombol Refresh Credit ──────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.25)),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _isRefreshing ? null : _refreshCredit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isRefreshing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.greenAccent,
                              ),
                            )
                          else
                            const Icon(Icons.refresh_rounded,
                                color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isRefreshing
                                ? 'Mereset credit & API key...'
                                : '🔄 Refresh Credit + Reset API Key',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Beta Testing — Tap untuk generate ulang tanpa menunggu',
                        style: TextStyle(color: Colors.white24, fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Upgrade CTA jika free
          if (credits.plan == 'free') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showKreaseaPremiumModal(context);
                },
                icon: const Icon(Icons.diamond_rounded, size: 18),
                label: const Text('Upgrade Pro — Lebih Banyak Credit',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pro: 15 image + 25 caption/hari  •  Premium: 50 image + 99 caption/hari',
              style: TextStyle(fontSize: 10, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CREDIT BAR — progress bar per tipe
// ══════════════════════════════════════════════════════════════════

class _CreditBar extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final int current;
  final int max;
  final Color color;

  const _CreditBar({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final isEmpty = current <= 0;
    final isLow = current == 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white38)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? Colors.red.withOpacity(0.15)
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isEmpty
                          ? Colors.red.withOpacity(0.3)
                          : color.withOpacity(0.3)),
                ),
                child: Text(
                  '$current/$max',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isEmpty ? Colors.redAccent : color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(
                isEmpty
                    ? Colors.red.withOpacity(0.5)
                    : isLow
                        ? Colors.orange
                        : color,
              ),
            ),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 12, color: Colors.red.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  const Text('Credit habis. Tekan Refresh Credit atau tunggu reset.',
                      style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// CREDIT GUARD DIALOG — tampil saat credit habis
// ══════════════════════════════════════════════════════════════════

Future<bool> showCreditGuard(
    BuildContext context, CreditType type, WidgetRef ref) async {
  final creditsAsync = ref.read(userCreditsProvider);
  final credits = creditsAsync.value ?? UserCredits.empty;
  final hasCredit = type == CreditType.image
      ? credits.hasImageCredit
      : credits.hasCaptionCredit;

  if (hasCredit) return true;

  final service = ref.read(creditServiceProvider);
  final timeLeft = service.formatTimeUntilReset();
  final typeLabel = type == CreditType.image ? 'image generate' : 'caption';

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bolt_rounded,
                color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Credit Habis',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credit $typeLabel kamu untuk hari ini sudah habis.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded,
                    color: Colors.greenAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Credit direset dalam $timeLeft',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup',
              style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            showKreaseaPremiumModal(context);
          },
          icon: const Icon(Icons.diamond_rounded, size: 16),
          label: const Text('Upgrade Pro'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ),
  );

  return false;
}
