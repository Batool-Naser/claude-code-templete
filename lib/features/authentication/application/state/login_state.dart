import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:todo_app/features/authentication/model/user_model.dart';

part 'login_state.freezed.dart';

/// Sealed union of all possible states for the login screen.
@freezed
sealed class LoginState with _$LoginState {
  /// No action has been taken yet.
  const factory LoginState.initial() = LoginInitial;

  /// A login request is in flight.
  const factory LoginState.loading() = LoginLoading;

  /// Login succeeded; carries the authenticated user.
  const factory LoginState.success(UserModel user) = LoginSuccess;

  /// Login failed; carries a user-facing error message.
  const factory LoginState.error(String message) = LoginError;
}
