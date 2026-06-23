import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  aiServiceInstance.initialize();

  runApp(const ProviderScope(child: AISmartAlarmApp()));
}

class AISmartAlarmApp extends ConsumerWidget {
  const AISmartAlarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AI Smart Alarm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
