import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/features/authentication/model/login_request_model.dart';
import 'package:todo_app/features/authentication/model/user_model.dart';
import 'package:todo_app/features/authentication/repository/authentication_repository.dart';

/// Concrete implementation of [AuthenticationRepository].
///
/// TODO: Inject [AuthenticationApiProvider] (and optionally a local provider)
/// once the data layer is wired up. For now this is a stub that simulates
/// a network round-trip so the full UI flow can be exercised.
class AuthenticationRepositoryImpl implements AuthenticationRepository {
  const AuthenticationRepositoryImpl();

  @override
  Future<UserModel> login(LoginRequestModel request) async {
    // TODO: Replace with real API call via AuthenticationApiProvider.
    // Example:
    //   final response = await _apiProvider.login(request);
    //   return response.toModel();
    await Future<void>.delayed(const Duration(seconds: 2));

    // Stub: treat any credential as valid. Remove once real auth is in place.
    if (request.email.isEmpty || request.password.isEmpty) {
      throw Exception('Email and password must not be empty.');
    }

    return UserModel(
      id: 'stub-user-id',
      email: request.email,
      displayName: 'Stub User',
    );
  }
}

/// Riverpod provider that exposes the repository to the notifier layer.
///
/// Override this in tests to inject a fake implementation.
final authenticationRepositoryProvider =
    Provider<AuthenticationRepository>((ref) {
  return const AuthenticationRepositoryImpl();
});
