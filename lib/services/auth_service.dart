import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../main.dart' show isFirebaseInitialized;

// Interface
abstract class AuthService {
  Stream<UserProfile?> get authStateChanges;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> updateProfile(UserProfile profile);
  Future<void> resetPassword(String email);
  UserProfile? get currentUser;
}

/// Guest-mode auth service that works without Firebase
class GuestAuthService implements AuthService {
  UserProfile? _currentUser;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Stream<UserProfile?> get authStateChanges => Stream.value(null);

  @override
  Future<void> signIn(String email, String password) async {
    throw Exception(
      'Login dengan email memerlukan Firebase.\n'
      'Pastikan koneksi internet aktif dan coba lagi.',
    );
  }

  @override
  Future<void> signUp(String email, String password) async {
    _currentUser = UserProfile(uid: 'guest', email: email, isOnboardingComplete: false);
  }

  @override
  Future<void> signInWithGoogle() async {
    throw Exception(
      'Login Google memerlukan koneksi Firebase.\n'
      'Pastikan internet aktif dan coba lagi.',
    );
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _currentUser = profile;
  }

  @override
  Future<void> resetPassword(String email) async {
    throw Exception(
      'Reset password memerlukan Firebase.\n'
      'Pastikan koneksi internet aktif dan coba lagi.',
    );
  }
}

/// Firebase-backed auth service
class FirebaseAuthService implements AuthService {
  final _auth = firebase_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  UserProfile? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserProfile(uid: user.uid, email: user.email ?? '');
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          return UserProfile.fromMap(doc.data()!);
        }
        return UserProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          isOnboardingComplete: false,
        );
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
        return UserProfile(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
      }
    });
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (credential.user != null) {
      final newUser = UserProfile(
        uid: credential.user!.uid,
        email: email,
        isOnboardingComplete: false,
      );
      try {
        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toMap());
      } catch (e) {
        debugPrint('Error creating user profile in Firestore: $e');
      }
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      firebase_auth.UserCredential userCredential;

      if (kIsWeb) {
        // ── Web: gunakan signInWithPopup — bekerja di semua browser ──────
        final provider = firebase_auth.GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        // ── Mobile (Android): gunakan google_sign_in package ─────────────
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId:
              '10847732026-hfvuqirr6p16sje7l77d35vfmdj2nju1.apps.googleusercontent.com',
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return; // User membatalkan

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final firebase_auth.AuthCredential credential =
            firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      // ── Buat profil Firestore jika user baru ─────────────────────────
      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (!doc.exists) {
          final newUser = UserProfile(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            businessName: userCredential.user!.displayName ?? 'Bisnis UMKM',
            isOnboardingComplete: false,
          );
          await _firestore
              .collection('users')
              .doc(newUser.uid)
              .set(newUser.toMap());
        }
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      final msg = e.toString();

      // User menutup popup/cancel — bukan error, abaikan saja
      if (msg.contains('popup-closed-by-user') ||
          msg.contains('cancelled') ||
          msg.contains('AbortError') ||
          msg.contains('sign_in_canceled')) {
        return;
      }
      if (msg.contains('popup-blocked')) {
        throw Exception(
          'Popup login diblokir oleh browser.\n'
          'Izinkan popup dari situs ini di pengaturan browser, lalu coba lagi.',
        );
      }
      if (msg.contains('unauthorized-domain')) {
        throw Exception(
          'Domain belum diotorisasi di Firebase Console.\n'
          'Tambahkan domain ini di Authentication → Settings → Authorized Domains.',
        );
      }
      if (msg.contains('DEVELOPER_ERROR') || msg.contains('10:')) {
        throw Exception(
          'Google Sign-In gagal: SHA-1 fingerprint belum didaftarkan.\n'
          'Tambahkan di Firebase Console → Project Settings → Android App.',
        );
      }
      if (msg.contains('network') || msg.contains('Network')) {
        throw Exception('Tidak ada koneksi internet. Periksa jaringan dan coba lagi.');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        // Sign out Google package hanya untuk mobile
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      }
    } catch (e) {
      debugPrint('Google sign out error (non-fatal): $e');
    }
    await _auth.signOut();
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    if (_auth.currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set(profile.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating user profile in Firestore: $e');
      }
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      // Kirim reset email langsung tanpa ActionCodeSettings
      // untuk menghindari error missing-continue-uri / missing-android-pkg-name di web
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[Auth] ✅ Password reset email sent to $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('[Auth] resetPassword error: ${e.code} — ${e.message}');
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          // Firebase keamanan: tidak reveal apakah email terdaftar atau tidak
          // Tapi untuk UX kita tampilkan pesan yang helpful
          throw Exception(
            'Email "$email" tidak terdaftar di KreaSea.\n'
            'Pastikan email yang kamu masukkan sudah benar.',
          );
        case 'invalid-email':
          throw Exception('Format email tidak valid. Periksa kembali alamat emailmu.');
        case 'too-many-requests':
          throw Exception(
            'Terlalu banyak percobaan reset.\n'
            'Tunggu beberapa menit lalu coba lagi.',
          );
        case 'network-request-failed':
          throw Exception(
            'Koneksi internet bermasalah.\n'
            'Periksa jaringanmu dan coba lagi.',
          );
        case 'missing-android-pkg-name':
        case 'missing-continue-uri':
        case 'missing-ios-bundle-id':
          // Tidak seharusnya terjadi tanpa ActionCodeSettings, tapi handle juga
          debugPrint('[Auth] Unexpected settings error — email mungkin tetap terkirim');
          return; // Anggap sukses
        default:
          throw Exception(
            'Gagal mengirim email reset: ${e.message ?? e.code}\n'
            'Coba lagi atau hubungi admin.',
          );
      }
    } catch (e) {
      debugPrint('[Auth] resetPassword unexpected error: $e');
      throw Exception('Gagal mengirim email reset. Pastikan koneksi internet aktif.');
    }
  }
}

// Provider — automatically selects Firebase or Guest based on init status
final authServiceProvider = Provider<AuthService>((ref) {
  if (isFirebaseInitialized) {
    return FirebaseAuthService();
  }
  debugPrint('⚠️ Firebase not available — using GuestAuthService');
  return GuestAuthService();
});

final authStateProvider = StreamProvider<UserProfile?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
