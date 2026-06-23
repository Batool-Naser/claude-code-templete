import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/alarm/application/notifier/alarm_notifier.dart';
import 'package:todo_app/features/profile/application/notifier/profile_notifier.dart';
import 'package:todo_app/features/sleep_analysis/application/notifier/sleep_analysis_notifier.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider).value;
    final sleepState = ref.watch(sleepAnalysisNotifierProvider).value;
    final alarms = ref.watch(alarmNotifierProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Progress & Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SleepTrendCard(state: sleepState),
          const SizedBox(height: 16),
          _AlarmStatsCard(alarms: alarms),
          const SizedBox(height: 16),
          _SleepStreakCard(state: sleepState, profile: profile),
          const SizedBox(height: 16),
          _WeeklyChartCard(state: sleepState),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SleepTrendCard extends StatelessWidget {
  const _SleepTrendCard({required this.state});
  final SleepAnalysisState? state;

  @override
  Widget build(BuildContext context) {
    final records = state?.recentRecords ?? [];
    final avg = state?.avgSleepHours ?? 0;
    final score = state?.avgScore ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sleep Overview', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBlock(value: '${avg.toStringAsFixed(1)}h', label: 'Avg Sleep'),
              const SizedBox(width: 24),
              _StatBlock(value: '${score.round()}', label: 'Avg Score'),
              const SizedBox(width: 24),
              _StatBlock(value: '${records.length}', label: 'Nights'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}

class _AlarmStatsCard extends StatelessWidget {
  const _AlarmStatsCard({required this.alarms});
  final List alarms;

  @override
  Widget build(BuildContext context) {
    final enabled = alarms.where((a) => a.isEnabled).length;
    final total = alarms.length;

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
          const Row(children: [
            Icon(Icons.alarm_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('Alarm Stats', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CircleStat(value: '$total', label: 'Total', color: AppColors.primary),
              _CircleStat(value: '$enabled', label: 'Active', color: AppColors.success),
              _CircleStat(value: '${total - enabled}', label: 'Paused', color: AppColors.textTertiary),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }
}

class _CircleStat extends StatelessWidget {
  const _CircleStat({required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: Center(
            child: Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _SleepStreakCard extends StatelessWidget {
  const _SleepStreakCard({required this.state, required this.profile});
  final SleepAnalysisState? state;
  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    final records = state?.recentRecords ?? [];
    int streak = 0;
    for (final r in records) {
      if (r.durationMinutes >= 7 * 60) {
        streak++;
      } else {
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: AppColors.warning, size: 28),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$streak ${streak == 1 ? 'day' : 'days'}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Sleep streak (7h+ nights)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.state});
  final SleepAnalysisState? state;

  @override
  Widget build(BuildContext context) {
    final records = (state?.recentRecords ?? []).take(7).toList().reversed.toList();
    const maxH = 9.0;

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
          const Row(children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.secondary, size: 18),
            SizedBox(width: 8),
            Text('Last 7 Nights', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          if (records.isEmpty)
            const Center(child: Text('No sleep data yet. Start logging!', style: TextStyle(color: AppColors.textTertiary)))
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: records.map((r) {
                  final h = r.durationMinutes / 60.0;
                  final frac = (h / maxH).clamp(0.0, 1.0);
                  final color = h >= 7 ? AppColors.success : h >= 6 ? AppColors.warning : AppColors.error;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${h.toStringAsFixed(1)}h',
                          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 28,
                          height: frac * 80,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(r.date.substring(5), style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}
