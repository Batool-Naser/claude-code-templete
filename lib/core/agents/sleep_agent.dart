import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/shared_models/sleep_record_model.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';

/// Analyzes sleep patterns and provides AI-driven insights.
class SleepAgent {
  final AIService _ai;

  SleepAgent(this._ai);

  Future<double> calculateSleepScore(SleepRecord record, UserProfileModel profile) async {
    double score = 0;

    // Duration score (0-40 points)
    final durationHours = record.durationMinutes / 60.0;
    final target = profile.targetSleepHours.toDouble();
    final durationDiff = (durationHours - target).abs();
    score += (40 - (durationDiff * 10)).clamp(0, 40);

    // Quality score (0-40 points)
    score += (record.qualityRating / 5.0) * 40;

    // Consistency bonus (0-20 points) — bedtime near midnight is ideal
    final idealBed = 23 * 60; // 11 PM
    final actualBed = record.bedTimeHour * 60 + record.bedTimeMinute;
    final bedDiff = (actualBed - idealBed).abs();
    score += (20 - (bedDiff / 30).clamp(0, 20));

    return score.clamp(0, 100);
  }

  Future<List<String>> generateSleepInsights({
    required List<SleepRecord> records,
    required UserProfileModel profile,
  }) async {
    if (records.isEmpty) {
      return ['Start logging your sleep to receive personalized insights.'];
    }

    final avgDuration = records.map((r) => r.durationMinutes).reduce((a, b) => a + b) /
        records.length;
    final avgQuality =
        records.map((r) => r.qualityRating).reduce((a, b) => a + b) / records.length;
    final avgScore = records.map((r) => r.sleepScore ?? 0).reduce((a, b) => a + b) /
        records.length;

    final prompt = '''
You are a sleep science expert AI. Analyze this sleep data and provide 3 concise, actionable insights.

User: ${profile.firstName}
Target sleep: ${profile.targetSleepHours}h
Last ${records.length} nights:
- Average duration: ${(avgDuration / 60).toStringAsFixed(1)}h
- Average quality: ${avgQuality.toStringAsFixed(1)}/5
- Average sleep score: ${avgScore.toStringAsFixed(0)}/100

Format: Return exactly 3 bullet points, each starting with "• "
Focus on: duration, consistency, quality improvements.
''';

    final response = await _ai.generate(prompt);
    final lines = response
        .split('\n')
        .where((l) => l.trim().startsWith('•') || l.trim().startsWith('-'))
        .map((l) => l.trim().replaceFirst(RegExp(r'^[•\-]\s*'), ''))
        .toList();

    if (lines.isEmpty) {
      return [
        'Aim for ${profile.targetSleepHours} hours of sleep every night.',
        'Keep a consistent bedtime to improve sleep quality.',
        'Avoid screens 1 hour before bed for better sleep.',
      ];
    }
    return lines.take(3).toList();
  }

  Future<String> generateWeeklyReport({
    required List<SleepRecord> weekRecords,
    required UserProfileModel profile,
  }) async {
    if (weekRecords.isEmpty) {
      return 'No sleep data this week. Start logging your sleep to get a personalized report!';
    }

    final avgDuration =
        weekRecords.map((r) => r.durationMinutes).reduce((a, b) => a + b) /
            weekRecords.length;
    final avgScore =
        weekRecords.map((r) => r.sleepScore ?? 0).reduce((a, b) => a + b) /
            weekRecords.length;

    final prompt = '''
Create a brief weekly sleep report for ${profile.firstName}.
Nights logged: ${weekRecords.length}/7
Average sleep: ${(avgDuration / 60).toStringAsFixed(1)}h (target: ${profile.targetSleepHours}h)
Average score: ${avgScore.toStringAsFixed(0)}/100

Write 2-3 sentences: weekly summary + one improvement suggestion.
Be encouraging but honest. Address ${profile.firstName} directly.
''';
    return _ai.generate(prompt);
  }

  Future<String> getSleepTip({required UserProfileModel profile}) async {
    final prompt = '''
Give one specific, practical sleep improvement tip for someone who wants to: ${profile.goals.join(', ')}.
Maximum 2 sentences. Be direct and actionable.
''';
    return _ai.generate(prompt);
  }

  /// Calculates streak of consecutive days meeting sleep target.
  int calculateStreak(List<SleepRecord> records, int targetHours) {
    if (records.isEmpty) return 0;
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    for (final record in sorted) {
      if (record.durationMinutes >= targetHours * 60 - 30) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
