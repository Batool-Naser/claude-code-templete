import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/alarm/application/notifier/alarm_notifier.dart';

class AIAlarmSetupScreen extends ConsumerStatefulWidget {
  const AIAlarmSetupScreen({super.key, required this.alarmId});
  final String alarmId;

  @override
  ConsumerState<AIAlarmSetupScreen> createState() => _AIAlarmSetupScreenState();
}

class _AIAlarmSetupScreenState extends ConsumerState<AIAlarmSetupScreen> {
  String _personality = 'Motivational';
  String _antiSnooze = AppConstants.challengeMath;
  String _motivationType = 'Quote + Tip';
  bool _useVoice = false;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final alarms = ref.read(alarmNotifierProvider).value ?? [];
      final alarm = alarms.firstWhere(
        (a) => a.id == widget.alarmId,
        orElse: () => alarms.first,
      );
      await ref.read(alarmNotifierProvider.notifier).updateAlarm(
            alarm.copyWith(
              alarmType: 'ai',
              aiPersonality: _personality,
              antiSnoozeType: _antiSnooze,
              motivationType: _motivationType,
            ),
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Alarm Setup'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: _saving ? AppColors.textTertiary : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(icon: Icons.psychology_rounded, title: 'AI Personality'),
          const SizedBox(height: 12),
          _PersonalityPicker(
            selected: _personality,
            onSelect: (p) => setState(() => _personality = p),
          ),
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.emoji_events_rounded, title: 'Motivation Style'),
          const SizedBox(height: 12),
          _MotivationPicker(
            selected: _motivationType,
            onSelect: (m) => setState(() => _motivationType = m),
          ),
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.block_rounded, title: 'Anti-Snooze Challenge'),
          const SizedBox(height: 12),
          _AntiSnoozePicker(
            selected: _antiSnooze,
            onSelect: (c) => setState(() => _antiSnooze = c),
          ),
          const SizedBox(height: 28),
          _SectionHeader(icon: Icons.record_voice_over_rounded, title: 'Voice Greeting'),
          const SizedBox(height: 12),
          _VoiceToggle(
            value: _useVoice,
            onChanged: (v) => setState(() => _useVoice = v),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}

class _PersonalityPicker extends StatelessWidget {
  const _PersonalityPicker({required this.selected, required this.onSelect});
  final String selected;
  final void Function(String) onSelect;

  static const _options = [
    ('Energetic', Icons.bolt_rounded, AppColors.warning),
    ('Calm', Icons.spa_rounded, AppColors.secondary),
    ('Motivational', Icons.emoji_events_rounded, AppColors.primary),
    ('Gentle', Icons.favorite_rounded, AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _options.map((o) {
        final isSelected = selected == o.$1;
        return GestureDetector(
          onTap: () => onSelect(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? o.$3.withValues(alpha: 0.15) : AppColors.surface,
              border: Border.all(
                color: isSelected ? o.$3 : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(o.$2, color: isSelected ? o.$3 : AppColors.textSecondary, size: 18),
                const SizedBox(width: 6),
                Text(o.$1,
                    style: TextStyle(
                      color: isSelected ? o.$3 : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MotivationPicker extends StatelessWidget {
  const _MotivationPicker({required this.selected, required this.onSelect});
  final String selected;
  final void Function(String) onSelect;

  static const _options = ['Quote + Tip', 'Daily Goal', 'Weather + Schedule', 'All of the above'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _options.map((o) {
        final isSelected = selected == o;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(o,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AntiSnoozePicker extends StatelessWidget {
  const _AntiSnoozePicker({required this.selected, required this.onSelect});
  final String selected;
  final void Function(String) onSelect;

  static const _options = [
    (AppConstants.challengeMath, Icons.calculate_rounded, 'Math Problem'),
    (AppConstants.challengeShake, Icons.vibration_rounded, 'Shake Phone'),
    (AppConstants.challengePhoto, Icons.camera_alt_rounded, 'Take Photo'),
    (AppConstants.challengeQr, Icons.qr_code_rounded, 'Scan QR Code'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: _options.map((o) {
        final isSelected = selected == o.$1;
        return GestureDetector(
          onTap: () => onSelect(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
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
                Icon(o.$2, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(o.$3,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VoiceToggle extends StatelessWidget {
  const _VoiceToggle({required this.value, required this.onChanged});
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over_rounded, color: AppColors.secondary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Voice Greeting', style: TextStyle(color: AppColors.textPrimary)),
              Text('AI greets you with voice', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
