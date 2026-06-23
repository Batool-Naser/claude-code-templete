import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/shared_models/alarm_model.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/alarm/application/notifier/alarm_notifier.dart';

class CreateAlarmScreen extends ConsumerStatefulWidget {
  const CreateAlarmScreen({super.key});

  @override
  ConsumerState<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends ConsumerState<CreateAlarmScreen> {
  int _hour = 7;
  int _minute = 0;
  final _labelCtrl = TextEditingController(text: 'Wake up');
  final _purposeCtrl = TextEditingController();
  final List<int> _repeatDays = [];
  String _alarmType = 'standard';
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final alarm = AlarmModel(
        id: '',
        userId: '',
        timeHour: _hour,
        timeMinute: _minute,
        label: _labelCtrl.text.trim().isEmpty ? 'Alarm' : _labelCtrl.text.trim(),
        purpose: _purposeCtrl.text.trim(),
        repeatDays: _repeatDays,
        alarmType: _alarmType,
        createdAt: DateTime.now(),
      );
      await ref.read(alarmNotifierProvider.notifier).addAlarm(alarm);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Alarm'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _TimePicker(hour: _hour, minute: _minute, onChanged: (h, m) => setState(() { _hour = h; _minute = m; })),
          const SizedBox(height: 24),
          _LabelField(controller: _labelCtrl),
          const SizedBox(height: 16),
          _PurposeField(controller: _purposeCtrl),
          const SizedBox(height: 24),
          _RepeatPicker(
            selected: _repeatDays,
            onToggle: (d) => setState(() => _repeatDays.contains(d)
                ? _repeatDays.remove(d)
                : _repeatDays.add(d)),
          ),
          const SizedBox(height: 24),
          _AlarmTypePicker(
            selected: _alarmType,
            onSelect: (t) => setState(() => _alarmType = t),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.hour, required this.minute, required this.onChanged});
  final int hour, minute;
  final void Function(int, int) onChanged;

  @override
  Widget build(BuildContext context) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                    surface: AppColors.surface,
                  ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked.hour, picked.minute);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text('$h:$m $period',
                style: const TextStyle(
                    fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Tap to change time',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _LabelField extends StatelessWidget {
  const _LabelField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Alarm label',
        prefixIcon: Icon(Icons.label_outline),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

class _PurposeField extends StatelessWidget {
  const _PurposeField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Purpose (optional)',
        hintText: 'e.g. Morning workout, Early meeting...',
        prefixIcon: Icon(Icons.track_changes),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

class _RepeatPicker extends StatelessWidget {
  const _RepeatPicker({required this.selected, required this.onToggle});
  final List<int> selected;
  final void Function(int) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Repeat', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final isSelected = selected.contains(i);
            return GestureDetector(
              onTap: () => onToggle(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    AppConstants.dayNames[i][0],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          selected.isEmpty ? 'Once' : _label(selected),
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }

  String _label(List<int> days) {
    if (days.length == 7) return 'Every day';
    final sorted = [...days]..sort();
    return sorted.map((d) => AppConstants.dayNames[d]).join(', ');
  }
}

class _AlarmTypePicker extends StatelessWidget {
  const _AlarmTypePicker({required this.selected, required this.onSelect});
  final String selected;
  final void Function(String) onSelect;

  static const _types = [
    ('standard', Icons.alarm_rounded, 'Standard', 'Regular alarm sound'),
    ('smart', Icons.auto_awesome, 'Smart', 'AI-optimized timing'),
    ('ai', Icons.psychology, 'AI', 'Full AI experience'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alarm type', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        ..._types.map((t) {
          final isSelected = selected == t.$1;
          return GestureDetector(
            onTap: () => onSelect(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(t.$2, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.$3,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(t.$4,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                  if (isSelected) ...[
                    const Spacer(),
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
