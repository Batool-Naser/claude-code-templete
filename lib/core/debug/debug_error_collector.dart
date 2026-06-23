import 'package:flutter/foundation.dart';

class AppError {
  final String message;
  final String? stack;
  final DateTime timestamp;
  final String type;

  AppError({
    required this.message,
    required this.timestamp,
    this.stack,
    this.type = 'Flutter',
  });
}

class DebugErrorCollector {
  DebugErrorCollector._();
  static final instance = DebugErrorCollector._();

  final List<AppError> errors = [];
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void _notify() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  void captureFlutterError(FlutterErrorDetails details) {
    errors.add(AppError(
      message: details.exceptionAsString(),
      stack: details.stack?.toString(),
      timestamp: DateTime.now(),
      type: 'Flutter',
    ));
    _notify();
  }

  bool capturePlatformError(Object error, StackTrace stack) {
    errors.add(AppError(
      message: error.toString(),
      stack: stack.toString(),
      timestamp: DateTime.now(),
      type: 'Platform',
    ));
    _notify();
    return true;
  }

  void clear() {
    errors.clear();
    _notify();
  }

  static void install() {
    if (!kDebugMode) return;

    final collector = DebugErrorCollector.instance;
    final originalOnError = FlutterError.onError;

    FlutterError.onError = (details) {
      collector.captureFlutterError(details);
      originalOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      return collector.capturePlatformError(error, stack);
    };
  }
}
