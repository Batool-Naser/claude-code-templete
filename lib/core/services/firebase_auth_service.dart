import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/debug/debug_error_collector.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';

// Shorthand used only in this file to keep log calls concise.
void _log(String msg, {required String cat, LogLevel level = LogLevel.info, String? stack}) {
  if (!kDebugMode) return;
  DebugErrorCollector.instance.log(msg, category: cat, level: level, stack: stack);
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<UserProfileModel> signInWithEmail(String email, String password) async {
    _log('Sign-in attempt: $email', cat: DebugCategory.firebase);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _log('Sign-in success: uid=${cred.user!.uid}', cat: DebugCategory.firebase, level: LogLevel.success);
      return _fetchOrCreateProfile(cred.user!);
    } catch (e, st) {
      _log('Sign-in failed: $e', cat: DebugCategory.firebase, level: LogLevel.error, stack: st.toString());
      rethrow;
    }
  }

  Future<UserProfileModel> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    _log('Register attempt: $email', cat: DebugCategory.firebase);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(displayName);
      _log('Register success: uid=${cred.user!.uid}', cat: DebugCategory.firebase, level: LogLevel.success);
      return _fetchOrCreateProfile(cred.user!);
    } catch (e, st) {
      _log('Register failed: $e', cat: DebugCategory.firebase, level: LogLevel.error, stack: st.toString());
      rethrow;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  static bool _googleInitialized = false;

  Future<UserProfileModel> signInWithGoogle() async {
    _log('Google sign-in: initializing', cat: DebugCategory.google);
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
        _log('Google SDK initialized', cat: DebugCategory.google, level: LogLevel.success);
      }

      _log('Google sign-in: launching authenticate()', cat: DebugCategory.google);
      final googleUser = await GoogleSignIn.instance.authenticate();
      _log('Google sign-in: user=${googleUser.email}', cat: DebugCategory.google, level: LogLevel.success);

      _log('Google sign-in: authorizing scopes', cat: DebugCategory.google);
      final clientAuth = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);
      _log('Google sign-in: scopes authorized', cat: DebugCategory.google, level: LogLevel.success);

      final cred = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
        accessToken: clientAuth.accessToken,
      );

      _log('Google sign-in: signing in with Firebase credential', cat: DebugCategory.firebase);
      final userCred = await _auth.signInWithCredential(cred);
      _log('Google sign-in: Firebase uid=${userCred.user!.uid}', cat: DebugCategory.firebase, level: LogLevel.success);

      return _fetchOrCreateProfile(userCred.user!);
    } catch (e, st) {
      _log('Google sign-in failed: $e', cat: DebugCategory.google, level: LogLevel.error, stack: st.toString());
      rethrow;
    }
  }

  // ── Apple Sign-In ─────────────────────────────────────────────────────────

  Future<UserProfileModel> signInWithApple(
    OAuthCredential appleCredential,
  ) async {
    _log('Apple sign-in: received credential', cat: DebugCategory.apple);
    try {
      _log('Apple sign-in: signing in with Firebase', cat: DebugCategory.firebase);
      final userCred = await _auth.signInWithCredential(appleCredential);
      _log('Apple sign-in: Firebase uid=${userCred.user!.uid}', cat: DebugCategory.firebase, level: LogLevel.success);
      return _fetchOrCreateProfile(userCred.user!);
    } catch (e, st) {
      _log('Apple sign-in failed: $e', cat: DebugCategory.apple, level: LogLevel.error, stack: st.toString());
      rethrow;
    }
  }

  // ── Sign-Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _log('Sign-out requested', cat: DebugCategory.auth);
    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
      _log('Sign-out complete', cat: DebugCategory.auth, level: LogLevel.success);
    } catch (e, st) {
      _log('Sign-out error: $e', cat: DebugCategory.auth, level: LogLevel.warning, stack: st.toString());
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    _log('Password reset requested: $email', cat: DebugCategory.firebase);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _log('Password reset email sent', cat: DebugCategory.firebase, level: LogLevel.success);
    } catch (e, st) {
      _log('Password reset failed: $e', cat: DebugCategory.firebase, level: LogLevel.error, stack: st.toString());
      rethrow;
    }
  }

  // ── Firestore profile ─────────────────────────────────────────────────────

  Future<UserProfileModel> _fetchOrCreateProfile(User user) async {
    _log('Fetching Firestore profile: uid=${user.uid}', cat: DebugCategory.firebase);
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      _log('Profile found in Firestore', cat: DebugCategory.firebase, level: LogLevel.success);
      return UserProfileModel.fromMap(doc.data()!);
    }

    _log('Creating new Firestore profile', cat: DebugCategory.firebase);
    final profile = UserProfileModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      avatarUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(profile.toMap());
    _log('Firestore profile created', cat: DebugCategory.firebase, level: LogLevel.success);
    return profile;
  }

  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfileModel.fromMap(doc.data()!);
  }

  Future<void> updateUserProfile(UserProfileModel profile) async {
    _log('Updating profile: uid=${profile.id}', cat: DebugCategory.firebase);
    await _db
        .collection(AppConstants.usersCollection)
        .doc(profile.id)
        .update(profile.toMap());
    _log('Profile updated', cat: DebugCategory.firebase, level: LogLevel.success);
  }
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (_) => FirebaseAuthService(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);
