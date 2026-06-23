import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/shared_models/alarm_model.dart';
import 'package:todo_app/core/shared_models/sleep_record_model.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';

/// Creates and optimizes alarms using Gemini AI.
class AlarmAgent {
  final AIService _ai;

  AlarmAgent(this._ai);

  Future<String> suggestAlarmLabel({
    required String purpose,
    required UserProfileModel profile,
  }) async {
    final prompt = '''
You are an AI alarm assistant. Create a short, motivating alarm label (max 5 words).
User purpose: $purpose
User goals: ${profile.goals.join(', ')}
Personality: ${profile.aiPersonality}
Return ONLY the label, nothing else.
''';
    return _ai.generate(prompt);
  }

  Future<Map<String, dynamic>> suggestAlarmConfig({
    required String purpose,
    required List<SleepRecord> recentSleep,
    required UserProfileModel profile,
  }) async {
    final avgDuration = recentSleep.isEmpty
        ? profile.targetSleepHours * 60.0
        : recentSleep.map((r) => r.durationMinutes).reduce((a, b) => a + b) /
            recentSleep.length;

    final prompt = '''
You are an AI sleep optimization expert. Based on this data, suggest the optimal alarm configuration.

User: ${profile.firstName}
Target wake time: ${profile.wakeTimeLabel}
Target sleep hours: ${profile.targetSleepHours}h
Recent avg sleep: ${(avgDuration / 60).toStringAsFixed(1)}h
Alarm purpose: $purpose
AI personality: ${profile.aiPersonality}

Return a JSON object with these fields:
{
  "recommendedHour": <0-23>,
  "recommendedMinute": <0-59>,
  "motivationMessage": "<short message>",
  "antiSnoozeType": "math|shake|photo",
  "tip": "<one sleep tip>"
}
''';
    final response = await _ai.generate(prompt);
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        // Simple parsing without dart:convert to keep it lightweight
        final json = response.substring(jsonStart, jsonEnd);
        return _parseSimpleJson(json);
      }
    } catch (_) {}
    return {
      'recommendedHour': profile.wakeTimeHour,
      'recommendedMinute': profile.wakeTimeMinute,
      'motivationMessage': 'Time to rise and shine!',
      'antiSnoozeType': 'math',
      'tip': 'Stick to your wake-up time even on weekends.',
    };
  }

  Future<String> generateWakeUpGreeting({
    required UserProfileModel profile,
    required SleepRecord? lastSleep,
  }) async {
    final sleepInfo = lastSleep != null
        ? 'Slept ${lastSleep.durationLabel} (quality: ${lastSleep.qualityRating}/5)'
        : 'No sleep data recorded';

    final prompt = '''
You are a ${profile.aiPersonality} AI morning coach.
Generate a warm, energizing wake-up greeting for ${profile.firstName}.
$sleepInfo
Goals: ${profile.goals.join(', ')}
Keep it under 3 sentences. Be uplifting and personalized.
''';
    return _ai.generate(prompt);
  }

  Future<String> generateDailySummary({
    required UserProfileModel profile,
    required SleepRecord? lastSleep,
    required List<AlarmModel> todayAlarms,
  }) async {
    final prompt = '''
You are an AI morning coach. Create a brief daily summary for ${profile.firstName}.
Sleep last night: ${lastSleep?.durationLabel ?? 'unknown'}
Sleep quality: ${lastSleep?.qualityRating ?? 'N/A'}/5
Today's alarms: ${todayAlarms.length}
User goals: ${profile.goals.join(', ')}

Provide: 1 sleep insight, 1 motivation tip, 1 focus suggestion. Keep it concise.
''';
    return _ai.generate(prompt);
  }

  Map<String, dynamic> _parseSimpleJson(String json) {
    final result = <String, dynamic>{};
    final hourMatch = RegExp(r'"recommendedHour"\s*:\s*(\d+)').firstMatch(json);
    final minuteMatch = RegExp(r'"recommendedMinute"\s*:\s*(\d+)').firstMatch(json);
    final msgMatch = RegExp(r'"motivationMessage"\s*:\s*"([^"]+)"').firstMatch(json);
    final antiMatch = RegExp(r'"antiSnoozeType"\s*:\s*"([^"]+)"').firstMatch(json);
    final tipMatch = RegExp(r'"tip"\s*:\s*"([^"]+)"').firstMatch(json);

    if (hourMatch != null) result['recommendedHour'] = int.parse(hourMatch.group(1)!);
    if (minuteMatch != null) result['recommendedMinute'] = int.parse(minuteMatch.group(1)!);
    if (msgMatch != null) result['motivationMessage'] = msgMatch.group(1);
    if (antiMatch != null) result['antiSnoozeType'] = antiMatch.group(1);
    if (tipMatch != null) result['tip'] = tipMatch.group(1);
    return result;
  }
}
