import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream status login — dipakai provider untuk auto-redirect
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User yang sedang login
  User? get currentUser => _auth.currentUser;

  // ── REGISTER ──────────────────────────────────────────
  Future<UserCredential> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name di Auth
    await credential.user!.updateDisplayName(username);

    // Buat dokumen user di Firestore
    await _db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'username': username,
      'email': email,
      'avatarUrl': '',
      'xp': 0,
      'level': 1,
      'badges': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // ── LOGIN ─────────────────────────────────────────────
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── LOGOUT ────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── ERROR HANDLER ─────────────────────────────────────
  String getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password minimal 6 karakter.';
      case 'user-not-found':
        return 'Akun tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }
}