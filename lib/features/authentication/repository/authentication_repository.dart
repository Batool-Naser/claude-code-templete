import 'package:todo_app/features/authentication/model/login_request_model.dart';
import 'package:todo_app/features/authentication/model/user_model.dart';

/// Abstract contract for authentication data operations.
///
/// Notifiers depend on this interface, never on concrete implementations.
abstract interface class AuthenticationRepository {
  /// Authenticates the user with [email] and [password].
  ///
  /// Returns the authenticated [UserModel] on success.
  /// Throws an [Exception] (or a domain-specific error type) on failure.
  Future<UserModel> login(LoginRequestModel request);
}
