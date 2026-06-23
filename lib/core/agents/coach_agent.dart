import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';

/// Provides coaching, motivation, and daily planning via AI chat.
class CoachAgent {
  final AIService _ai;
  ChatSession? _session;

  CoachAgent(this._ai);

  String _buildSystemPrompt(UserProfileModel profile) => '''
You are an AI morning coach named "Aria" for ${profile.firstName}.
Personality: ${profile.aiPersonality}
User goals: ${profile.goals.join(', ')}
Sleep target: ${profile.targetSleepHours} hours per night
Wake time: ${profile.wakeTimeLabel}

Your role:
- Provide sleep and productivity advice
- Help plan daily routines
- Offer motivation and habit coaching
- Answer questions about sleep science
- Help with morning planning

Be conversational, encouraging, and personalized. Keep responses concise (2-4 sentences).
Never provide medical advice. Always recommend consulting a doctor for health concerns.
''';

  void startSession(UserProfileModel profile) {
    if (!_ai.isReady) return;
    final systemContent = Content.text(_buildSystemPrompt(profile));
    _session = _ai.startChat(history: [systemContent]);
  }

  Future<String> sendMessage(String userMessage) async {
    if (_session == null) {
      return 'Hi! I\'m Aria, your AI coach. Set up your GEMINI_API_KEY to unlock full AI coaching.';
    }
    return _ai.sendMessage(_session!, userMessage);
  }

  void resetSession(UserProfileModel profile) {
    startSession(profile);
  }

  Future<String> getDailyMotivation(UserProfileModel profile) async {
    final prompt = '''
Give ${profile.firstName} a powerful morning motivation quote or message.
Their goals: ${profile.goals.join(', ')}
Personality type: ${profile.aiPersonality}
Make it personal, energizing, and under 40 words.
''';
    return _ai.generate(prompt);
  }

  Future<List<String>> generateDailyTasks({
    required UserProfileModel profile,
    required DateTime date,
  }) async {
    final prompt = '''
Create 3-5 morning routine tasks for ${profile.firstName} for today.
Goals: ${profile.goals.join(', ')}
Wake time: ${profile.wakeTimeLabel}
Be specific and time-boxed. Format as a list.
Return ONLY the tasks, one per line, starting with a dash "-".
''';
    final response = await _ai.generate(prompt);
    final tasks = response
        .split('\n')
        .where((l) => l.trim().startsWith('-'))
        .map((l) => l.trim().substring(1).trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (tasks.isEmpty) {
      return [
        'Drink a glass of water',
        'Do 5 minutes of stretching',
        'Review today\'s top 3 priorities',
        'Eat a healthy breakfast',
      ];
    }
    return tasks;
  }

  List<String> get quickPrompts => [
        'Give me a sleep tip for tonight',
        'Help me plan my morning routine',
        'I\'m feeling tired, what should I do?',
        'How can I wake up easier?',
        'What\'s the best bedtime for me?',
        'Tips for better sleep quality',
      ];
}
