import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class AuthService {
  final _auth = FirebaseAuth.instance;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  }

  Future<UserCredential> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: usa popup do Firebase Auth direto
      final provider = GoogleAuthProvider();
      return await _auth.signInWithPopup(provider);
    } else {
      // Android / iOS: usa google_sign_in
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Login com Google cancelado');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // deslogar do Google também no mobile
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }
}
