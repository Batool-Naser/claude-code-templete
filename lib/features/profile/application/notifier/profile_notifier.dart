import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/firebase_auth_service.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';

class ProfileNotifier extends AsyncNotifier<UserProfileModel> {
  @override
  Future<UserProfileModel> build() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }
    final profile = await ref
        .read(firebaseAuthServiceProvider)
        .getUserProfile(user.uid);
    if (profile == null) {
      return UserProfileModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        createdAt: DateTime.now(),
      );
    }
    return profile;
  }

  Future<void> updateProfile(UserProfileModel profile) async {
    await ref.read(firebaseAuthServiceProvider).updateUserProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfileModel>(ProfileNotifier.new);
