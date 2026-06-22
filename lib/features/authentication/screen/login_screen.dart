import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/features/authentication/application/notifier/login_notifier.dart';
import 'package:todo_app/features/authentication/application/state/login_state.dart';
import 'package:todo_app/features/authentication/widgets/login_error_banner.dart';
import 'package:todo_app/features/authentication/widgets/login_form.dart';

/// Login screen: layout and state observation only.
///
/// All business logic lives in [LoginNotifier]. This widget watches state,
/// dispatches user intents to the notifier, and renders the appropriate UI.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginNotifierProvider);

    // Navigate on success — placed here so the transition happens in the
    // widget layer, which is the correct place for navigation side-effects.
    // TODO: Replace this listener with context.router.replace(HomeRoute())
    //       once GoRouter is configured and a HomeScreen exists.
    ref.listen<LoginState>(loginNotifierProvider, (previous, next) {
      if (next is LoginSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Welcome, ${next.user.displayName ?? next.user.email}!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // TODO: navigate to home screen
        //   context.router.replace(HomeRoute());
      }
    });

    final isLoading = loginState is LoginLoading;
    final errorMessage =
        loginState is LoginError ? (loginState).message : '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              // Cap width on larger screens so the form doesn't stretch.
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LoginHeader(),
                  const SizedBox(height: 40),

                  // Inline error banner — hidden when there is no error.
                  LoginErrorBanner(
                    message: errorMessage,
                    onDismiss: () =>
                        ref.read(loginNotifierProvider.notifier).reset(),
                  ),
                  if (errorMessage.isNotEmpty) const SizedBox(height: 20),

                  LoginForm(
                    isLoading: isLoading,
                    onSubmit: (email, password) => ref
                        .read(loginNotifierProvider.notifier)
                        .login(email, password),
                    onForgotPassword: () {
                      // TODO: Navigate to forgot-password screen.
                      //   context.router.push(ForgotPasswordRoute());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Forgot password — coming soon.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Branding header displayed at the top of the login screen.
class _LoginHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // App icon placeholder — swap for Image.asset once assets are added.
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome back',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
