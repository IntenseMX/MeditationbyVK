import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/entities/app_user.dart';
import '../data/models/app_user_model.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    if (cred.user != null) {
      await _createOrUpdateUserDoc(cred.user!, 'anonymous');
    }
    return cred;
  }

  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await _createOrUpdateUserDoc(cred.user!, 'email');
    }
    return cred;
  }

  Future<UserCredential> signUpWithEmailAndPassword({required String email, required String password}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await _createOrUpdateUserDoc(cred.user!, 'email');
    }
    return cred;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters(<String, String>{'prompt': 'select_account'});
      final cred = await _auth.signInWithPopup(provider);
      if (cred.user != null) {
        await _createOrUpdateUserDoc(cred.user!, 'google');
      }
      return cred;
    } else {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await _createOrUpdateUserDoc(cred.user!, 'google');
      }
      return cred;
    }
  }

  Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      final provider = OAuthProvider('apple.com');
      final cred = await _auth.signInWithPopup(provider);
      if (cred.user != null) {
        await _createOrUpdateUserDoc(cred.user!, 'apple');
      }
      return cred;
    } else {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final cred = await _auth.signInWithCredential(oauthCredential);
      if (cred.user != null) {
        await _createOrUpdateUserDoc(cred.user!, 'apple');
      }
      return cred;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore google sign-out errors to avoid blocking sign-out
    }
    await _auth.signOut();
  }

  Future<void> _createOrUpdateUserDoc(User user, String provider) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final appUser = AppUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        authProvider: provider,
        isAnonymous: user.isAnonymous,
        isPremium: false,
        dailyGoldGoal: 10,
        createdAt: DateTime.now(),
      );
      await docRef.set(AppUserModel.toFirestore(appUser));
    } else {
      await docRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateDailyGoldGoal(int minutes) async {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not authenticated');
    final safe = minutes <= 0 ? 10 : minutes;
    await _firestore.collection('users').doc(u.uid).update({
      'dailyGoldGoal': safe,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

