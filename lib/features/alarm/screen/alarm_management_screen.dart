import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/shared_models/alarm_model.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/alarm/application/notifier/alarm_notifier.dart';

class AlarmManagementScreen extends ConsumerWidget {
  const AlarmManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Alarms')),
      body: alarmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alarms) => alarms.isEmpty
            ? _EmptyState()
            : _AlarmList(alarms: alarms),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createAlarm),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
        label: const Text('Add Alarm', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off_rounded, size: 72, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text('No alarms yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Add your first smart alarm',
              style: TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _AlarmList extends ConsumerWidget {
  const _AlarmList({required this.alarms});
  final List<AlarmModel> alarms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: alarms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _AlarmTile(
        alarm: alarms[i],
        onToggle: () => ref.read(alarmNotifierProvider.notifier).toggleAlarm(alarms[i].id),
        onDelete: () => _confirmDelete(context, ref, alarms[i].id),
        onTap: () => context.push('${AppRoutes.aiAlarmSetup}?id=${alarms[i].id}'),
      ).animate().fadeIn(duration: 300.ms, delay: (i * 60).ms),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete alarm?'),
        content: const Text('This alarm will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(alarmNotifierProvider.notifier).deleteAlarm(id);
    }
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });
  final AlarmModel alarm;
  final VoidCallback onToggle, onDelete, onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alarm.isEnabled ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                alarm.displayTime,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: alarm.isEnabled ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(alarm.label,
                  style: TextStyle(
                    color: alarm.isEnabled ? AppColors.textSecondary : AppColors.textTertiary,
                  )),
              const SizedBox(height: 2),
              Row(
                children: [
                  _TypeChip(type: alarm.alarmType),
                  const SizedBox(width: 8),
                  Text(alarm.repeatLabel,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ]),
            const Spacer(),
            Column(
              children: [
                Switch(value: alarm.isEnabled, onChanged: (_) => onToggle()),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = type == 'ai'
        ? AppColors.primary
        : type == 'smart'
            ? AppColors.secondary
            : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(type.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
