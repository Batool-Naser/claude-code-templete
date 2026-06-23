import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/agents/planner_agent.dart';
import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/profile/application/notifier/profile_notifier.dart';

class SmartPlannerScreen extends ConsumerStatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  ConsumerState<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends ConsumerState<SmartPlannerScreen> {
  final _events = <PlannerEvent>[];
  String _morningPlan = '';
  bool _loadingPlan = false;

  void _addEvent() async {
    final titleCtrl = TextEditingController();
    TimeOfDay? time;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Event title'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                );
              },
              icon: const Icon(Icons.access_time_rounded),
              label: const Text('Set time'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && time != null) {
                final now = DateTime.now();
                final start = DateTime(now.year, now.month, now.day, time!.hour, time!.minute);
                setState(() => _events.add(PlannerEvent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text,
                  startTime: start,
                  endTime: start.add(const Duration(hours: 1)),
                  needsAlarm: true,
                )));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePlan() async {
    final profile = ref.read(profileNotifierProvider).value;
    if (profile == null) return;
    setState(() => _loadingPlan = true);
    final agent = PlannerAgent(aiServiceInstance);
    final plan = await agent.generateMorningPlan(
      profile: profile,
      todayEvents: _events,
    );
    if (mounted) setState(() { _morningPlan = plan; _loadingPlan = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _addEvent,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TodayHeader(),
          const SizedBox(height: 16),
          if (_events.isEmpty)
            _EmptyEventsCard(onAdd: _addEvent)
          else
            ..._events.asMap().entries.map((e) =>
              _EventTile(event: e.value, onDelete: () => setState(() => _events.removeAt(e.key)))
                  .animate().fadeIn(duration: 300.ms, delay: (e.key * 60).ms)),
          const SizedBox(height: 20),
          _GeneratePlanButton(loading: _loadingPlan, onTap: _generatePlan),
          if (_morningPlan.isNotEmpty) ...[
            const SizedBox(height: 20),
            _MorningPlanCard(plan: _morningPlan),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[now.weekday - 1];
    final dateStr = '$dayName, ${months[now.month - 1]} ${now.day}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Today', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
        ],
      ),
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_note_rounded, color: AppColors.textTertiary, size: 48),
          const SizedBox(height: 12),
          const Text('No events today', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add an event'),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.onDelete});
  final PlannerEvent event;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final h = event.startTime.hour % 12 == 0 ? 12 : event.startTime.hour % 12;
    final m = event.startTime.minute.toString().padLeft(2, '0');
    final p = event.startTime.hour < 12 ? 'AM' : 'PM';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$h:$m $p', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(event.title, style: const TextStyle(color: AppColors.textPrimary))),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textTertiary, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _GeneratePlanButton extends StatelessWidget {
  const _GeneratePlanButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(loading ? 'Generating plan...' : 'Generate AI Morning Plan',
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _MorningPlanCard extends StatelessWidget {
  const _MorningPlanCard({required this.plan});
  final String plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('AI Morning Plan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(plan, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
