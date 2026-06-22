import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/features/authentication/application/state/login_state.dart';
import 'package:todo_app/features/authentication/model/login_request_model.dart';
import 'package:todo_app/features/authentication/repository/authentication_repository.dart';
import 'package:todo_app/features/authentication/repository/authentication_repository_impl.dart';

/// Manages login screen state and delegates auth operations to the repository.
///
/// The notifier is the only layer the screen interacts with — it never
/// touches providers or repositories directly.
class LoginNotifier extends Notifier<LoginState> {
  late AuthenticationRepository _repository;

  @override
  LoginState build() {
    _repository = ref.watch(authenticationRepositoryProvider);
    return const LoginState.initial();
  }

  /// Attempts to authenticate the user with the supplied credentials.
  ///
  /// Transitions state through: initial → loading → success | error.
  Future<void> login(String email, String password) async {
    state = const LoginState.loading();

    try {
      final user = await _repository.login(
        LoginRequestModel(email: email.trim(), password: password),
      );
      state = LoginState.success(user);
    } on Exception catch (e) {
      // Strip the "Exception: " prefix for cleaner user-facing messages.
      final rawMessage = e.toString();
      final message = rawMessage.startsWith('Exception: ')
          ? rawMessage.substring('Exception: '.length)
          : rawMessage;
      state = LoginState.error(message);
    }
  }

  /// Resets the state to [LoginInitial] (e.g. to dismiss an error banner).
  void reset() => state = const LoginState.initial();
}

/// Riverpod provider for [LoginNotifier].
final loginNotifierProvider =
    NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);
