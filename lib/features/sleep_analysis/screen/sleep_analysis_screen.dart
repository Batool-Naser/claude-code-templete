import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/sleep_analysis/application/notifier/sleep_analysis_notifier.dart';

class SleepAnalysisScreen extends ConsumerWidget {
  const SleepAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(sleepAnalysisNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Analysis')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) => _SleepBody(state: state),
      ),
    );
  }
}

class _SleepBody extends ConsumerWidget {
  const _SleepBody({required this.state});
  final SleepAnalysisState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OverviewCards(state: state),
        const SizedBox(height: 20),
        _LogSleepCard(),
        const SizedBox(height: 20),
        _AIInsightsCard(state: state),
        const SizedBox(height: 20),
        if (state.recentRecords.isNotEmpty) _RecentRecordsList(state: state),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.state});
  final SleepAnalysisState state;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Avg Sleep', state.recentRecords.isEmpty ? '--' : '${state.avgSleepHours.toStringAsFixed(1)}h',
          Icons.bedtime_rounded, AppColors.secondary),
      ('Avg Score', state.recentRecords.isEmpty ? '--' : '${state.avgScore.round()}',
          Icons.star_rounded, AppColors.warning),
      ('Quality', state.recentRecords.isEmpty ? '--' : '${state.avgQuality.toStringAsFixed(1)}/5',
          Icons.thumb_up_rounded, AppColors.success),
      ('Nights', '${state.recentRecords.length}', Icons.calendar_today_rounded, AppColors.primary),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards.asMap().entries.map((e) {
        final c = e.value;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [
                Icon(c.$3, color: c.$4, size: 16),
                const SizedBox(width: 6),
                Text(c.$1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              Text(c.$2,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (e.key * 80).ms);
      }).toList(),
    );
  }
}

class _LogSleepCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LogSleepCard> createState() => _LogSleepCardState();
}

class _LogSleepCardState extends ConsumerState<_LogSleepCard> {
  bool _expanded = false;
  int _bedHour = 23, _bedMinute = 0;
  int _wakeHour = 7, _wakeMinute = 0;
  int _quality = 3;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(sleepAnalysisNotifierProvider.notifier).logSleep(
          bedHour: _bedHour,
          bedMinute: _bedMinute,
          wakeHour: _wakeHour,
          wakeMinute: _wakeMinute,
          quality: _quality,
        );
    if (mounted) setState(() { _expanded = false; _saving = false; });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Log Last Night\'s Sleep',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 16),
            _TimeRow(label: 'Bed time', hour: _bedHour, minute: _bedMinute,
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _bedHour, minute: _bedMinute));
                  if (t != null) setState(() { _bedHour = t.hour; _bedMinute = t.minute; });
                }),
            const SizedBox(height: 10),
            _TimeRow(label: 'Wake time', hour: _wakeHour, minute: _wakeMinute,
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _wakeHour, minute: _wakeMinute));
                  if (t != null) setState(() { _wakeHour = t.hour; _wakeMinute = t.minute; });
                }),
            const SizedBox(height: 16),
            const Text('Sleep quality', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _quality = i + 1),
                child: Icon(i < _quality ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: _quality > i ? AppColors.warning : AppColors.textTertiary, size: 32),
              )),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Sleep Record'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.hour, required this.minute, required this.onTap});
  final String label;
  final int hour, minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final p = hour < 12 ? 'AM' : 'PM';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            Text('$h:$m $p',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AIInsightsCard extends ConsumerWidget {
  const _AIInsightsCard({required this.state});
  final SleepAnalysisState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('AI Sleep Insights',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (!state.isLoadingInsights)
                TextButton(
                  onPressed: () => ref.read(sleepAnalysisNotifierProvider.notifier).loadAIInsights(),
                  child: const Text('Refresh', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          if (state.isLoadingInsights)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
            )
          else if (state.aiInsights.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.recentRecords.isEmpty
                    ? 'Log your sleep to get AI insights.'
                    : 'Tap Refresh to get personalized sleep insights.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...state.aiInsights.map((insight) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(insight, style: const TextStyle(color: AppColors.textSecondary, height: 1.4))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _RecentRecordsList extends StatelessWidget {
  const _RecentRecordsList({required this.state});
  final SleepAnalysisState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Nights',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        ...state.recentRecords.take(7).map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(r.durationLabel,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ]),
                  const Spacer(),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                            i < r.qualityRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: AppColors.warning, size: 14)),
                      const SizedBox(width: 8),
                      if (r.sleepScore != null)
                        Text('${r.sleepScore!.round()}',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
