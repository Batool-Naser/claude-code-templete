import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/agents/alarm_agent.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/profile/application/notifier/profile_notifier.dart';
import 'package:todo_app/features/sleep_analysis/application/notifier/sleep_analysis_notifier.dart';

class WakeUpScreen extends ConsumerStatefulWidget {
  const WakeUpScreen({super.key, required this.alarmId});
  final String alarmId;

  @override
  ConsumerState<WakeUpScreen> createState() => _WakeUpScreenState();
}

class _WakeUpScreenState extends ConsumerState<WakeUpScreen> {
  String _greeting = 'Good morning! ☀️';
  String _summary = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = ref.read(profileNotifierProvider).value;
    final sleepState = ref.read(sleepAnalysisNotifierProvider).value;
    final lastSleep = sleepState?.recentRecords.firstOrNull;
    final agent = AlarmAgent(aiServiceInstance);

    if (profile != null) {
      _greeting = await agent.generateWakeUpGreeting(
        profile: profile,
        lastSleep: lastSleep,
      );
    }

    if (mounted) setState(() => _loading = false);

    if (profile != null) {
      _summary = await agent.generateDailySummary(
        profile: profile,
        lastSleep: lastSleep,
        todayAlarms: [],
      );
      if (mounted) setState(() {});
    }
  }

  void _dismiss() {
    NotificationService.cancelAll();
    context.go(AppRoutes.home);
  }

  void _snooze() {
    context.go('${AppRoutes.antiSnooze}?type=math');
  }

  @override
  Widget build(BuildContext context) {
    final sleepState = ref.watch(sleepAnalysisNotifierProvider).value;
    final lastSleep = sleepState?.recentRecords.firstOrNull;
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.sleepGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                _TimeDisplay(h: h, m: m, period: period),
                const SizedBox(height: 32),
                _GreetingCard(greeting: _greeting, loading: _loading),
                const SizedBox(height: 16),
                if (lastSleep != null) _SleepSummaryCard(sleep: lastSleep),
                if (_summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InsightCard(summary: _summary),
                ],
                const Spacer(),
                _WakeUpActions(onDismiss: _dismiss, onSnooze: _snooze),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  const _TimeDisplay({required this.h, required this.m, required this.period});
  final int h;
  final String m, period;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$h:$m',
            style: const TextStyle(
                fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center),
        Text(period,
            style: const TextStyle(fontSize: 24, color: Colors.white60),
            textAlign: TextAlign.center),
      ],
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.greeting, required this.loading});
  final String greeting;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: loading
                ? const Text('Loading your morning brief...',
                    style: TextStyle(color: Colors.white70))
                : Text(greeting,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _SleepSummaryCard extends StatelessWidget {
  const _SleepSummaryCard({required this.sleep});
  final dynamic sleep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.bedtime_rounded, color: Colors.white54, size: 20),
          const SizedBox(width: 10),
          Text('Last night: ${sleep.durationLabel}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          _QualityStars(rating: sleep.qualityRating),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn();
  }
}

class _QualityStars extends StatelessWidget {
  const _QualityStars({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.warning,
            size: 14,
          )),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.summary});
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(summary,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
    ).animate(delay: 700.ms).fadeIn();
  }
}

class _WakeUpActions extends StatelessWidget {
  const _WakeUpActions({required this.onDismiss, required this.onSnooze});
  final VoidCallback onDismiss, onSnooze;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onDismiss,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wb_sunny_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text("I'm Up!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSnooze,
          child: const Text('Snooze (solve a challenge first)',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
        ),
      ],
    ).animate(delay: 800.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}
