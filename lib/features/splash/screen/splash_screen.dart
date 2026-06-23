import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/services/firebase_auth_service.dart';
import 'package:todo_app/core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    final isLoggedIn = auth.value != null;
    context.go(isLoggedIn ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Logo(),
              const SizedBox(height: 24),
              _AppName(),
              const SizedBox(height: 8),
              _Tagline(),
              const SizedBox(height: 60),
              _LoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.alarm_rounded, size: 56, color: Colors.white),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.6, 0.6), duration: 600.ms, curve: Curves.easeOut);
  }
}

class _AppName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
      child: const Text(
        'AI Smart Alarm',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}

class _Tagline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Your intelligent wake-up companion',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
    ).animate(delay: 500.ms).fadeIn(duration: 500.ms);
  }
}

class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.primary,
      ),
    ).animate(delay: 800.ms).fadeIn(duration: 400.ms);
  }
}
