class UserProfileModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final List<String> goals;
  final int wakeTimeHour;
  final int wakeTimeMinute;
  final int targetSleepHours;
  final String aiPersonality;
  final bool onboardingComplete;
  final String subscriptionTier;
  final DateTime createdAt;

  const UserProfileModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.goals = const [],
    this.wakeTimeHour = 7,
    this.wakeTimeMinute = 0,
    this.targetSleepHours = 8,
    this.aiPersonality = 'Motivational',
    this.onboardingComplete = false,
    this.subscriptionTier = 'free',
    required this.createdAt,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) => UserProfileModel(
        id: map['id'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        goals: List<String>.from(map['goals'] ?? []),
        wakeTimeHour: (map['wakeTimeHour'] as num?)?.toInt() ?? 7,
        wakeTimeMinute: (map['wakeTimeMinute'] as num?)?.toInt() ?? 0,
        targetSleepHours: (map['targetSleepHours'] as num?)?.toInt() ?? 8,
        aiPersonality: map['aiPersonality'] as String? ?? 'Motivational',
        onboardingComplete: map['onboardingComplete'] as bool? ?? false,
        subscriptionTier: map['subscriptionTier'] as String? ?? 'free',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        if (displayName != null) 'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'goals': goals,
        'wakeTimeHour': wakeTimeHour,
        'wakeTimeMinute': wakeTimeMinute,
        'targetSleepHours': targetSleepHours,
        'aiPersonality': aiPersonality,
        'onboardingComplete': onboardingComplete,
        'subscriptionTier': subscriptionTier,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    List<String>? goals,
    int? wakeTimeHour,
    int? wakeTimeMinute,
    int? targetSleepHours,
    String? aiPersonality,
    bool? onboardingComplete,
    String? subscriptionTier,
    DateTime? createdAt,
  }) =>
      UserProfileModel(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        goals: goals ?? this.goals,
        wakeTimeHour: wakeTimeHour ?? this.wakeTimeHour,
        wakeTimeMinute: wakeTimeMinute ?? this.wakeTimeMinute,
        targetSleepHours: targetSleepHours ?? this.targetSleepHours,
        aiPersonality: aiPersonality ?? this.aiPersonality,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        subscriptionTier: subscriptionTier ?? this.subscriptionTier,
        createdAt: createdAt ?? this.createdAt,
      );

  String get wakeTimeLabel {
    final h = wakeTimeHour % 12 == 0 ? 12 : wakeTimeHour % 12;
    final m = wakeTimeMinute.toString().padLeft(2, '0');
    final p = wakeTimeHour < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String get firstName => displayName?.split(' ').first ?? email.split('@').first;
}
