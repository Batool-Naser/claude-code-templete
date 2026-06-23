import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_theme.dart';

class _RoutineItem {
  final String id;
  final String title;
  final String duration;
  final IconData icon;
  bool completed = false;

  _RoutineItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.icon,
  });
}

class DailyRoutineScreen extends ConsumerStatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  ConsumerState<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends ConsumerState<DailyRoutineScreen> {
  final _items = <_RoutineItem>[
    _RoutineItem(id: '1', title: 'Wake up & drink water', duration: '2 min', icon: Icons.local_drink_rounded),
    _RoutineItem(id: '2', title: 'Morning stretch', duration: '5 min', icon: Icons.self_improvement_rounded),
    _RoutineItem(id: '3', title: 'Review daily goals', duration: '3 min', icon: Icons.track_changes_rounded),
    _RoutineItem(id: '4', title: 'Healthy breakfast', duration: '15 min', icon: Icons.breakfast_dining_rounded),
    _RoutineItem(id: '5', title: 'Mindfulness / Meditation', duration: '10 min', icon: Icons.spa_rounded),
    _RoutineItem(id: '6', title: 'Plan top 3 tasks', duration: '5 min', icon: Icons.checklist_rounded),
  ];

  int get _completedCount => _items.where((i) => i.completed).length;
  double get _progress => _items.isEmpty ? 0 : _completedCount / _items.length;

  void _toggle(String id) => setState(() {
        final item = _items.firstWhere((i) => i.id == id);
        item.completed = !item.completed;
      });

  void _addItem() async {
    final ctrl = TextEditingController();
    final durCtrl = TextEditingController(text: '5 min');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Routine Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Habit / Task'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: durCtrl,
              decoration: const InputDecoration(labelText: 'Duration'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() => _items.add(_RoutineItem(
                  id: DateTime.now().toString(),
                  title: ctrl.text.trim(),
                  duration: durCtrl.text.trim(),
                  icon: Icons.check_box_outline_blank_rounded,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Routine'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _addItem),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressHeader(completed: _completedCount, total: _items.length, progress: _progress),
          const SizedBox(height: 20),
          ..._items.asMap().entries.map((e) =>
            _RoutineTile(item: e.value, onToggle: () => _toggle(e.value.id))
                .animate().fadeIn(duration: 300.ms, delay: (e.key * 50).ms)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.completed, required this.total, required this.progress});
  final int completed, total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Routine",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('$completed / $total done',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1
                ? '🎉 Routine complete! Great morning!'
                : '${(progress * 100).round()}% complete — keep going!',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.item, required this.onToggle});
  final _RoutineItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.completed ? AppColors.success.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.completed ? AppColors.success.withValues(alpha: 0.4) : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.completed ? Icons.check_circle_rounded : item.icon,
              color: item.completed ? AppColors.success : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: item.completed ? AppColors.textTertiary : AppColors.textPrimary,
                      decoration: item.completed ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(item.duration,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
