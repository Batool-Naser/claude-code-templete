import 'package:flutter/material.dart';

/// Displays an inline error message below the login form.
///
/// Animated so it slides in/out smoothly rather than popping abruptly.
class LoginErrorBanner extends StatelessWidget {
  const LoginErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;

  /// Called when the user taps the dismiss (close) icon.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: message.isEmpty
          ? const SizedBox.shrink()
          : Semantics(
              label: 'Login error: $message',
              child: Container(
                key: const ValueKey('error-banner'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      tooltip: 'Dismiss error',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: onDismiss,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
