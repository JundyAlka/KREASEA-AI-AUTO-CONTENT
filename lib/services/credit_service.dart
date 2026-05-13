import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart' show isFirebaseInitialized;

// ══════════════════════════════════════════════════════════════
// CREDIT SYSTEM — KreaSea
// ══════════════════════════════════════════════════════════════
//
// Dua pool credit TERPISAH:
//   • imageCredits  → untuk generate gambar (Stability AI)
//   • captionCredits → untuk generate caption / text AI
//
// Auto-refresh harian:
//   • Cek tanggal terakhir reset vs hari ini (WIB UTC+7)
//   • Jika beda hari → reset ke nilai awal plan
//
// Plan Limits (per hari):
//   Free:    3 image,  5 caption
//   Pro:    15 image, 25 caption
//   Premium: 50 image, unlimited caption (99)
// ══════════════════════════════════════════════════════════════

/// Tipe credit yang tersedia
enum CreditType { image, caption }

/// Model data credit user
class UserCredits {
  final int imageCredits;       // sisa credit image hari ini
  final int captionCredits;     // sisa credit caption hari ini
  final int imageCreditMax;     // maksimum per hari sesuai plan
  final int captionCreditMax;   // maksimum per hari sesuai plan
  final String plan;            // 'free' | 'pro' | 'premium'
  final String resetDate;       // 'YYYY-MM-DD' tanggal terakhir reset
  final DateTime? nextResetAt;  // kapan credit berikutnya direset

  const UserCredits({
    required this.imageCredits,
    required this.captionCredits,
    required this.imageCreditMax,
    required this.captionCreditMax,
    required this.plan,
    required this.resetDate,
    this.nextResetAt,
  });

  bool get hasImageCredit => imageCredits > 0;
  bool get hasCaptionCredit => captionCredits > 0;

  int get imagePercent => imageCreditMax > 0
      ? ((imageCredits / imageCreditMax) * 100).round().clamp(0, 100)
      : 0;

  int get captionPercent => captionCreditMax > 0
      ? ((captionCredits / captionCreditMax) * 100).round().clamp(0, 100)
      : 0;

  static const UserCredits empty = UserCredits(
    imageCredits: 0,
    captionCredits: 0,
    imageCreditMax: 3,
    captionCreditMax: 5,
    plan: 'free',
    resetDate: '',
  );

  UserCredits copyWith({int? imageCredits, int? captionCredits}) {
    return UserCredits(
      imageCredits: imageCredits ?? this.imageCredits,
      captionCredits: captionCredits ?? this.captionCredits,
      imageCreditMax: imageCreditMax,
      captionCreditMax: captionCreditMax,
      plan: plan,
      resetDate: resetDate,
      nextResetAt: nextResetAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'imageCredits': imageCredits,
    'captionCredits': captionCredits,
    'imageCreditMax': imageCreditMax,
    'captionCreditMax': captionCreditMax,
    'plan': plan,
    'resetDate': resetDate,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory UserCredits.fromMap(Map<String, dynamic> map) {
    return UserCredits(
      imageCredits: (map['imageCredits'] as num?)?.toInt() ?? 0,
      captionCredits: (map['captionCredits'] as num?)?.toInt() ?? 0,
      imageCreditMax: (map['imageCreditMax'] as num?)?.toInt() ?? 3,
      captionCreditMax: (map['captionCreditMax'] as num?)?.toInt() ?? 5,
      plan: map['plan']?.toString() ?? 'free',
      resetDate: map['resetDate']?.toString() ?? '',
    );
  }
}

/// Konfigurasi limit per plan
class PlanConfig {
  static const Map<String, Map<String, int>> limits = {
    'free':    {'image': 3,  'caption': 5},
    'pro':     {'image': 15, 'caption': 25},
    'premium': {'image': 50, 'caption': 99},
  };

  static int imageLimit(String plan) => limits[plan]?['image'] ?? 3;
  static int captionLimit(String plan) => limits[plan]?['caption'] ?? 5;
}

// ══════════════════════════════════════════════════════════════
// CREDIT SERVICE
// ══════════════════════════════════════════════════════════════

class CreditService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference get _docRef =>
      _db.collection('user_credits').doc(_uid ?? 'guest');

  /// Tanggal hari ini dalam zona WIB (UTC+7), format YYYY-MM-DD
  String _todayWIB() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Waktu reset berikutnya (tengah malam WIB)
  DateTime _nextMidnightWIB() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.subtract(const Duration(hours: 7)); // konversi balik ke UTC
  }

  /// Ambil atau inisialisasi credit user
  Future<UserCredits> fetchCredits() async {
    if (!isFirebaseInitialized || _uid == null) return UserCredits.empty;

    try {
      final snap = await _docRef.get();
      final today = _todayWIB();

      if (!snap.exists) {
        // User baru — inisialisasi dengan free plan
        return await _initCredits(plan: 'free');
      }

      final data = snap.data() as Map<String, dynamic>;
      final resetDate = data['resetDate']?.toString() ?? '';
      final plan = data['plan']?.toString() ?? 'free';

      // Auto-refresh jika hari sudah berganti
      if (resetDate != today) {
        return await _resetCredits(plan: plan);
      }

      return UserCredits.fromMap(data).copyWith();
    } catch (e) {
      debugPrint('[CreditService] fetchCredits error: $e');
      return UserCredits.empty;
    }
  }

  /// Stream untuk UI reaktif — auto-update saat Firestore berubah
  Stream<UserCredits> watchCredits() {
    if (!isFirebaseInitialized || _uid == null) return Stream.value(UserCredits.empty);

    return _docRef.snapshots().asyncMap((snap) async {
      final today = _todayWIB();

      if (!snap.exists) return await _initCredits(plan: 'free');

      final data = snap.data() as Map<String, dynamic>;
      final resetDate = data['resetDate']?.toString() ?? '';
      final plan = data['plan']?.toString() ?? 'free';

      if (resetDate != today) {
        return await _resetCredits(plan: plan);
      }

      return UserCredits.fromMap(data);
    });
  }

  /// Inisialisasi credit untuk user baru
  Future<UserCredits> _initCredits({String plan = 'free'}) async {
    final today = _todayWIB();
    final credits = UserCredits(
      imageCredits: PlanConfig.imageLimit(plan),
      captionCredits: PlanConfig.captionLimit(plan),
      imageCreditMax: PlanConfig.imageLimit(plan),
      captionCreditMax: PlanConfig.captionLimit(plan),
      plan: plan,
      resetDate: today,
    );
    await _docRef.set(credits.toMap());
    debugPrint('[CreditService] Initialized credits for $plan plan: ${credits.imageCredits} img, ${credits.captionCredits} caption');
    return credits;
  }

  /// Reset credit ke nilai awal plan (dipanggil otomatis saat hari berganti)
  Future<UserCredits> _resetCredits({String plan = 'free'}) async {
    final today = _todayWIB();
    final credits = UserCredits(
      imageCredits: PlanConfig.imageLimit(plan),
      captionCredits: PlanConfig.captionLimit(plan),
      imageCreditMax: PlanConfig.imageLimit(plan),
      captionCreditMax: PlanConfig.captionLimit(plan),
      plan: plan,
      resetDate: today,
    );
    await _docRef.set(credits.toMap(), SetOptions(merge: true));
    debugPrint('[CreditService] Daily credit reset for $plan plan [$today]');
    return credits;
  }

  /// Kurangi 1 credit untuk tipe yang dipilih.
  /// Return true jika berhasil, false jika credit tidak cukup.
  Future<bool> useCredit(CreditType type) async {
    if (!isFirebaseInitialized || _uid == null) return true; // guest mode: tidak blokir

    try {
      // Fetch current state dulu
      final current = await fetchCredits();

      if (type == CreditType.image) {
        if (current.imageCredits <= 0) return false;
        await _docRef.update({
          'imageCredits': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        if (current.captionCredits <= 0) return false;
        await _docRef.update({
          'captionCredits': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('[CreditService] useCredit error: $e');
      return false;
    }
  }

  /// Refill credit (misalnya setelah upgrade plan)
  Future<void> refillCredits({required String plan}) async {
    if (!isFirebaseInitialized || _uid == null) return;
    await _docRef.set({
      'imageCredits': PlanConfig.imageLimit(plan),
      'captionCredits': PlanConfig.captionLimit(plan),
      'imageCreditMax': PlanConfig.imageLimit(plan),
      'captionCreditMax': PlanConfig.captionLimit(plan),
      'plan': plan,
      'resetDate': _todayWIB(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('[CreditService] Refilled credits for plan: $plan');
  }

  /// Hitung berapa detik lagi hingga reset
  Duration timeUntilReset() {
    final next = _nextMidnightWIB();
    final diff = next.difference(DateTime.now().toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Format jam:menit:detik hingga reset
  String formatTimeUntilReset() {
    final dur = timeUntilReset();
    final h = dur.inHours.toString().padLeft(2, '0');
    final m = (dur.inMinutes % 60).toString().padLeft(2, '0');
    return '${h}j ${m}m';
  }
}

// ══════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ══════════════════════════════════════════════════════════════

final creditServiceProvider = Provider<CreditService>((ref) => CreditService());

/// Stream provider — UI reaktif, auto-update
final userCreditsProvider = StreamProvider<UserCredits>((ref) {
  if (!isFirebaseInitialized) return Stream.value(UserCredits.empty);
  final service = ref.watch(creditServiceProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(UserCredits.empty);
  return service.watchCredits();
});

/// Future provider — untuk one-time fetch
final creditsFutureProvider = FutureProvider<UserCredits>((ref) async {
  final service = ref.watch(creditServiceProvider);
  return service.fetchCredits();
});
