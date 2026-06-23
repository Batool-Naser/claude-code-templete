class AppConstants {
  AppConstants._();

  static const appName = 'AI Smart Alarm';

  // Gemini AI — set via --dart-define=GEMINI_API_KEY=<key> at build/run time
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const geminiModel = 'gemini-2.5-flash';

  // Firestore collections
  static const usersCollection = 'users';
  static const alarmsCollection = 'alarms';
  static const sleepRecordsCollection = 'sleep_records';
  static const chatHistoryCollection = 'chat_history';
  static const routinesCollection = 'routines';

  // SharedPreferences keys
  static const prefOnboardingComplete = 'onboarding_complete';
  static const prefUserGoals = 'user_goals';
  static const prefWakeHour = 'wake_hour';
  static const prefWakeMinute = 'wake_minute';
  static const prefSleepHours = 'sleep_hours';
  static const prefAiPersonality = 'ai_personality';

  // Notification channels
  static const alarmChannelId = 'ai_smart_alarm';
  static const alarmChannelName = 'Alarms';
  static const alarmChannelDesc = 'AI Smart Alarm notifications';

  // Days of week (0 = Monday, 6 = Sunday)
  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // AI personalities
  static const personalities = ['Energetic', 'Calm', 'Motivational', 'Gentle'];

  // Anti-snooze challenge types
  static const challengeMath = 'math';
  static const challengeShake = 'shake';
  static const challengePhoto = 'photo';
  static const challengeQr = 'qr';

  // Sleep quality labels
  static const sleepQualityLabels = ['Terrible', 'Poor', 'OK', 'Good', 'Excellent'];
}
