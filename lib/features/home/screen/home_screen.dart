import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/shared_models/alarm_model.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/alarm/application/notifier/alarm_notifier.dart';
import 'package:todo_app/features/profile/application/notifier/profile_notifier.dart';
import 'package:todo_app/features/sleep_analysis/application/notifier/sleep_analysis_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider);
    final alarms = ref.watch(alarmNotifierProvider);
    final sleepState = ref.watch(sleepAnalysisNotifierProvider);

    final firstName = profile.value?.firstName ?? 'there';
    final enabledAlarms = alarms.value?.where((a) => a.isEnabled).toList() ?? [];
    final nextAlarm = _nextAlarm(enabledAlarms);
    final sleepScore = sleepState.value?.recentRecords.firstOrNull?.sleepScore;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HomeHeader(firstName: firstName)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    NextAlarmCard(alarm: nextAlarm),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: SleepScoreCard(score: sleepScore)),
                        const SizedBox(width: 12),
                        Expanded(child: _ActiveAlarmsCard(count: enabledAlarms.length)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _QuickActionsCard(),
                    const SizedBox(height: 16),
                    _AIInsightCard(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createAlarm),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
        label: const Text('New Alarm', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  AlarmModel? _nextAlarm(List<AlarmModel> alarms) {
    if (alarms.isEmpty) return null;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    AlarmModel? next;
    int minDiff = 9999;

    for (final alarm in alarms) {
      final alarmMinutes = alarm.timeHour * 60 + alarm.timeMinute;
      var diff = alarmMinutes - nowMinutes;
      if (diff < 0) diff += 24 * 60;
      if (diff < minDiff) {
        minDiff = diff;
        next = alarm;
      }
    }
    return next;
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good morning, 👋',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            Text(firstName,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ]),
          GestureDetector(
            onTap: () => context.push(AppRoutes.aiCoach),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

class NextAlarmCard extends StatelessWidget {
  const NextAlarmCard({super.key, required this.alarm});
  final AlarmModel? alarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: alarm == null
          ? const _NoAlarmContent()
          : _AlarmContent(alarm: alarm!),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }
}

class _NoAlarmContent extends StatelessWidget {
  const _NoAlarmContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('No alarm set', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Set your first smart alarm',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Icon(Icons.alarm_add_rounded, color: Colors.white70, size: 32),
      ],
    );
  }
}

class _AlarmContent extends StatelessWidget {
  const _AlarmContent({required this.alarm});
  final AlarmModel alarm;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Next alarm', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(alarm.displayTime,
              style: const TextStyle(
                  color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(alarm.label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(alarm.repeatLabel,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
        const Icon(Icons.alarm_rounded, color: Colors.white54, size: 48),
      ],
    );
  }
}

class SleepScoreCard extends StatelessWidget {
  const SleepScoreCard({super.key, required this.score});
  final double? score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bedtime_rounded, color: AppColors.secondary, size: 18),
              SizedBox(width: 6),
              Text('Sleep Score', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            score != null ? '${score!.round()}' : '--',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            score != null ? _label(score!) : 'Log sleep',
            style: TextStyle(
              color: score != null ? _color(score!) : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  String _label(double s) => s >= 80 ? 'Excellent' : s >= 60 ? 'Good' : s >= 40 ? 'Fair' : 'Poor';
  Color _color(double s) => s >= 80 ? AppColors.success : s >= 60 ? AppColors.warning : AppColors.error;
}

class _ActiveAlarmsCard extends StatelessWidget {
  const _ActiveAlarmsCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.alarms),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.alarm_on_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 6),
                Text('Active', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text('$count',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('alarms', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }
}

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.auto_awesome, 'AI Coach', AppRoutes.aiCoach, AppColors.primary),
      (Icons.calendar_today, 'Planner', AppRoutes.smartPlanner, AppColors.secondary),
      (Icons.self_improvement, 'Routine', AppRoutes.dailyRoutine, AppColors.accent),
      (Icons.show_chart, 'Progress', AppRoutes.progress, AppColors.success),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((a) {
              return GestureDetector(
                onTap: () => context.push(a.$4 == AppColors.primary ? AppRoutes.aiCoach : a.$4 == AppColors.secondary ? AppRoutes.smartPlanner : a.$4 == AppColors.accent ? AppRoutes.dailyRoutine : AppRoutes.progress),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: a.$4.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.$1, color: a.$4, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(a.$2,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}

class _AIInsightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Insight', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                SizedBox(height: 4),
                Text(
                  'Maintain a consistent sleep schedule to improve your energy levels throughout the day.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms);
  }
}
