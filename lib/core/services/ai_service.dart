import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:todo_app/core/constants/app_constants.dart';

/// Central service for all Gemini AI interactions.
/// Run the app with: flutter run --dart-define=GEMINI_API_KEY=your_key
class AIService {
  GenerativeModel? _model;
  bool _initialized = false;

  void initialize() {
    final key = AppConstants.geminiApiKey;
    if (key.isEmpty) return;
    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: key,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    _initialized = true;
  }

  bool get isReady => _initialized && _model != null;

  /// One-shot text generation.
  Future<String> generate(String prompt) async {
    if (!isReady) return _fallbackResponse(prompt);
    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? _fallbackResponse(prompt);
    } catch (e) {
      return _fallbackResponse(prompt);
    }
  }

  /// Returns a [ChatSession] for multi-turn conversations.
  ChatSession startChat({List<Content>? history}) {
    if (_model == null) {
      throw StateError('AIService not initialized. Set GEMINI_API_KEY.');
    }
    return _model!.startChat(history: history ?? []);
  }

  /// Send a message in an existing chat session.
  Future<String> sendMessage(ChatSession session, String message) async {
    try {
      final response = await session.sendMessage(Content.text(message));
      return response.text?.trim() ?? 'I couldn\'t process that. Try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  String _fallbackResponse(String prompt) {
    if (prompt.toLowerCase().contains('alarm')) {
      return 'Based on your sleep patterns, I recommend waking up at the same time every day to improve consistency.';
    }
    if (prompt.toLowerCase().contains('sleep')) {
      return 'Aim for 7–9 hours of sleep and try to maintain a consistent schedule, even on weekends.';
    }
    return 'Stay consistent with your routine for best results. Small improvements compound over time.';
  }
}

final aiServiceInstance = AIService();
