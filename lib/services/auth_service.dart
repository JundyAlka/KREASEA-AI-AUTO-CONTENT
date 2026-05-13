import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _currentUser = UserProfile(uid: 'guest', email: email, businessName: 'Guest User', isOnboardingComplete: true);
  }

  @override
  Future<void> signUp(String email, String password) async {
    _currentUser = UserProfile(uid: 'guest', email: email, isOnboardingComplete: false);
  }

  @override
  Future<void> signInWithGoogle() async {
    throw Exception(
      'Login Google memerlukan koneksi Firebase.\n'
      'Pastikan internet aktif dan coba lagi.'
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
            isOnboardingComplete: false);
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
        return UserProfile(
            uid: firebaseUser.uid, email: firebaseUser.email ?? '');
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
      final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId:
              "10847732026-hfvuqirr6p16sje7l77d35vfmdj2nju1.apps.googleusercontent.com");
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

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
      debugPrint('Error in Google Sign In: $e');
      final msg = e.toString();
      if (msg.contains('DEVELOPER_ERROR') || msg.contains('10:')) {
        throw Exception(
          'Google Sign-In gagal: SHA-1 fingerprint belum didaftarkan di Firebase Console.\n'
          'SHA-1 debug: C0:43:8D:21:EE:74:39:32:09:68:9B:56:C9:F1:84:D6:61:47:24:A2\n'
          'Tambahkan di Firebase Console → Project Settings → Android App.'
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
