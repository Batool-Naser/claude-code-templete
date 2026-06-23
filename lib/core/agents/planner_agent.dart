import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/shared_models/alarm_model.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';

class PlannerEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final bool needsAlarm;
  final int? suggestedAlarmMinutesBefore;

  const PlannerEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    this.needsAlarm = false,
    this.suggestedAlarmMinutesBefore,
  });
}

/// Manages schedules and creates smart alarms for calendar events.
class PlannerAgent {
  final AIService _ai;

  PlannerAgent(this._ai);

  Future<List<AlarmModel>> suggestAlarmsForEvents({
    required List<PlannerEvent> events,
    required UserProfileModel profile,
  }) async {
    final alarms = <AlarmModel>[];

    for (final event in events) {
      if (!event.needsAlarm) continue;

      final prepTime = event.suggestedAlarmMinutesBefore ?? await _calculatePrepTime(
        event: event,
        profile: profile,
      );

      final alarmTime = event.startTime.subtract(Duration(minutes: prepTime));

      alarms.add(AlarmModel(
        id: 'planner_${event.id}',
        userId: profile.id,
        timeHour: alarmTime.hour,
        timeMinute: alarmTime.minute,
        label: '${event.title} prep time',
        purpose: 'Prepare for ${event.title}',
        alarmType: 'smart',
        createdAt: DateTime.now(),
      ));
    }

    return alarms;
  }

  Future<int> _calculatePrepTime({
    required PlannerEvent event,
    required UserProfileModel profile,
  }) async {
    final prompt = '''
An event called "${event.title}" starts at ${_formatTime(event.startTime)}.
Location: ${event.location ?? 'unknown'}
How many minutes before should the user set an alarm to prepare and travel?
Return ONLY a number (integer, 15-120 range).
''';

    final response = await _ai.generate(prompt);
    final match = RegExp(r'\d+').firstMatch(response.trim());
    if (match != null) {
      return int.parse(match.group(0)!).clamp(15, 120);
    }
    return 30; // Default 30 minutes
  }

  Future<String> generateMorningPlan({
    required UserProfileModel profile,
    required List<PlannerEvent> todayEvents,
  }) async {
    final eventList = todayEvents
        .map((e) => '- ${e.title} at ${_formatTime(e.startTime)}')
        .join('\n');

    final prompt = '''
Create a morning plan for ${profile.firstName}.
Wake time: ${profile.wakeTimeLabel}
Today's schedule:
${eventList.isEmpty ? 'No events scheduled' : eventList}
Goals: ${profile.goals.join(', ')}

Provide a structured morning timeline (wake → breakfast → tasks → first event).
Keep it practical and time-boxed. Use bullet points.
''';
    return _ai.generate(prompt);
  }

  Future<String> analyzeProductivity({
    required UserProfileModel profile,
    required int alarmsCompleted,
    required int alarmsTotal,
    required int habitStreak,
  }) async {
    final successRate =
        alarmsTotal > 0 ? (alarmsCompleted / alarmsTotal * 100).round() : 0;

    final prompt = '''
Analyze ${profile.firstName}'s morning productivity.
Alarm success rate: $successRate% ($alarmsCompleted/$alarmsTotal)
Habit streak: $habitStreak days
Goals: ${profile.goals.join(', ')}

Give 2-3 sentences: what's going well and one specific improvement suggestion.
Be encouraging and concrete.
''';
    return _ai.generate(prompt);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
