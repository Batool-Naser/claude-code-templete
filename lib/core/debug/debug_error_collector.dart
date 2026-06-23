import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum LogLevel { error, warning, info, success }

class DebugCategory {
  const DebugCategory._();

  static const firebase = 'Firebase';
  static const google = 'Google';
  static const apple = 'Apple';
  static const auth = 'Auth';
  static const flutter = 'Flutter';
  static const platform = 'Platform';

  static Color colorFor(String category) => switch (category) {
        firebase => const Color(0xFF42A5F5),
        google => const Color(0xFFEA4335),
        apple => const Color(0xFFE0E0E0),
        auth => const Color(0xFFAB47BC),
        flutter => const Color(0xFF26C6DA),
        platform => const Color(0xFFEF5350),
        _ => const Color(0xFF78909C),
      };

  static IconData iconFor(String category) => switch (category) {
        firebase => Icons.local_fire_department_rounded,
        google => Icons.g_mobiledata_rounded,
        apple => Icons.apple_rounded,
        auth => Icons.lock_rounded,
        flutter => Icons.flutter_dash_rounded,
        platform => Icons.phone_android_rounded,
        _ => Icons.label_rounded,
      };
}

class DebugEntry {
  final String message;
  final String? stack;
  final DateTime timestamp;
  final String category;
  final LogLevel level;

  const DebugEntry({
    required this.message,
    required this.timestamp,
    required this.category,
    required this.level,
    this.stack,
  });

  String get copyText {
    final buf = StringBuffer()
      ..writeln('[${timestamp.toIso8601String()}]')
      ..writeln('Category : $category')
      ..writeln('Level    : ${level.name.toUpperCase()}')
      ..writeln('Message  : $message');
    if (stack != null) {
      buf
        ..writeln()
        ..writeln('Stack Trace:')
        ..writeln(stack);
    }
    return buf.toString();
  }
}

class DebugErrorCollector {
  DebugErrorCollector._();
  static final instance = DebugErrorCollector._();

  final List<DebugEntry> entries = [];
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);

  void _notify() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  void log(
    String message, {
    required String category,
    LogLevel level = LogLevel.info,
    String? stack,
  }) {
    if (!kDebugMode) return;
    entries.add(DebugEntry(
      message: message,
      category: category,
      level: level,
      stack: stack,
      timestamp: DateTime.now(),
    ));
    _notify();
  }

  void captureFlutterError(FlutterErrorDetails details) {
    entries.add(DebugEntry(
      message: details.exceptionAsString(),
      stack: details.stack?.toString(),
      timestamp: DateTime.now(),
      category: DebugCategory.flutter,
      level: LogLevel.error,
    ));
    _notify();
  }

  bool capturePlatformError(Object error, StackTrace stack) {
    entries.add(DebugEntry(
      message: error.toString(),
      stack: stack.toString(),
      timestamp: DateTime.now(),
      category: DebugCategory.platform,
      level: LogLevel.error,
    ));
    _notify();
    return true;
  }

  int get errorCount =>
      entries.where((e) => e.level == LogLevel.error).length;

  List<String> get categories =>
      entries.map((e) => e.category).toSet().toList();

  void clear() {
    entries.clear();
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
