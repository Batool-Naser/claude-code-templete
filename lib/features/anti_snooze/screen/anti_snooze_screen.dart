import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/theme/app_theme.dart';

class AntiSnoozeScreen extends StatefulWidget {
  const AntiSnoozeScreen({super.key, required this.challengeType});
  final String challengeType;

  @override
  State<AntiSnoozeScreen> createState() => _AntiSnoozeScreenState();
}

class _AntiSnoozeScreenState extends State<AntiSnoozeScreen> {
  final _rng = Random();
  late int _num1, _num2, _answer;
  final _ctrl = TextEditingController();
  bool _solved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateMath();
  }

  void _generateMath() {
    _num1 = _rng.nextInt(20) + 10;
    _num2 = _rng.nextInt(20) + 1;
    final ops = ['+', '-', '*'];
    final op = ops[_rng.nextInt(ops.length)];
    switch (op) {
      case '+':
        _answer = _num1 + _num2;
        break;
      case '-':
        _answer = _num1 - _num2;
        break;
      case '*':
        _num1 = _rng.nextInt(10) + 2;
        _num2 = _rng.nextInt(10) + 2;
        _answer = _num1 * _num2;
        break;
    }
    _ctrl.clear();
    _error = null;
  }

  void _check() {
    final input = int.tryParse(_ctrl.text.trim());
    if (input == null) {
      setState(() => _error = 'Enter a number');
      return;
    }
    if (input == _answer) {
      setState(() => _solved = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) context.go(AppRoutes.home);
      });
    } else {
      setState(() {
        _error = 'Wrong! Try again 🧠';
        _generateMath();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _solved ? _SolvedView() : _ChallengeView(
              num1: _num1,
              num2: _num2,
              answer: _answer,
              ctrl: _ctrl,
              error: _error,
              onSubmit: _check,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeView extends StatelessWidget {
  const _ChallengeView({
    required this.num1,
    required this.num2,
    required this.answer,
    required this.ctrl,
    required this.error,
    required this.onSubmit,
  });
  final int num1, num2, answer;
  final TextEditingController ctrl;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.calculate_rounded, size: 64, color: AppColors.primary)
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text('Anti-Snooze Challenge',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Solve to snooze your alarm',
            style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            'What is $num1 + $num2?',
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '?',
            errorText: error,
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: const Text('Submit Answer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _SolvedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.success)
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text('Great job! 🎉',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text('Alarm snoozed for 5 minutes.\nNow wake up for real! 💪',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center),
      ],
    );
  }
}
