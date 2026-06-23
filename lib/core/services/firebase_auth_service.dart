import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserProfileModel> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchOrCreateProfile(cred.user!);
  }

  Future<UserProfileModel> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    return _fetchOrCreateProfile(cred.user!);
  }

  static bool _googleInitialized = false;

  Future<UserProfileModel> signInWithGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
    final googleUser = await GoogleSignIn.instance.authenticate();
    final clientAuth = await googleUser.authorizationClient
        .authorizeScopes(['email', 'profile']);
    final cred = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
      accessToken: clientAuth.accessToken,
    );
    final userCred = await _auth.signInWithCredential(cred);
    return _fetchOrCreateProfile(userCred.user!);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserProfileModel> _fetchOrCreateProfile(User user) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      return UserProfileModel.fromMap(doc.data()!);
    }

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
    return profile;
  }

  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfileModel.fromMap(doc.data()!);
  }

  Future<void> updateUserProfile(UserProfileModel profile) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(profile.id)
        .update(profile.toMap());
  }
}

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (_) => FirebaseAuthService(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);
