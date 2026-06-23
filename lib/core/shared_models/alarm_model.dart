class AlarmModel {
  final String id;
  final String userId;
  final int timeHour;
  final int timeMinute;
  final String label;
  final String purpose;
  final List<int> repeatDays;
  final bool isEnabled;
  final String alarmType;
  final String? aiPersonality;
  final String? motivationType;
  final String? antiSnoozeType;
  final DateTime createdAt;

  const AlarmModel({
    required this.id,
    required this.userId,
    required this.timeHour,
    required this.timeMinute,
    required this.label,
    this.purpose = '',
    this.repeatDays = const [],
    this.isEnabled = true,
    this.alarmType = 'standard',
    this.aiPersonality,
    this.motivationType,
    this.antiSnoozeType,
    required this.createdAt,
  });

  factory AlarmModel.fromMap(Map<String, dynamic> map) => AlarmModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        timeHour: (map['timeHour'] as num).toInt(),
        timeMinute: (map['timeMinute'] as num).toInt(),
        label: map['label'] as String? ?? 'Alarm',
        purpose: map['purpose'] as String? ?? '',
        repeatDays: List<int>.from(map['repeatDays'] ?? []),
        isEnabled: map['isEnabled'] as bool? ?? true,
        alarmType: map['alarmType'] as String? ?? 'standard',
        aiPersonality: map['aiPersonality'] as String?,
        motivationType: map['motivationType'] as String?,
        antiSnoozeType: map['antiSnoozeType'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'timeHour': timeHour,
        'timeMinute': timeMinute,
        'label': label,
        'purpose': purpose,
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'alarmType': alarmType,
        if (aiPersonality != null) 'aiPersonality': aiPersonality,
        if (motivationType != null) 'motivationType': motivationType,
        if (antiSnoozeType != null) 'antiSnoozeType': antiSnoozeType,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  AlarmModel copyWith({
    String? id,
    String? userId,
    int? timeHour,
    int? timeMinute,
    String? label,
    String? purpose,
    List<int>? repeatDays,
    bool? isEnabled,
    String? alarmType,
    String? aiPersonality,
    String? motivationType,
    String? antiSnoozeType,
    DateTime? createdAt,
  }) =>
      AlarmModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        timeHour: timeHour ?? this.timeHour,
        timeMinute: timeMinute ?? this.timeMinute,
        label: label ?? this.label,
        purpose: purpose ?? this.purpose,
        repeatDays: repeatDays ?? this.repeatDays,
        isEnabled: isEnabled ?? this.isEnabled,
        alarmType: alarmType ?? this.alarmType,
        aiPersonality: aiPersonality ?? this.aiPersonality,
        motivationType: motivationType ?? this.motivationType,
        antiSnoozeType: antiSnoozeType ?? this.antiSnoozeType,
        createdAt: createdAt ?? this.createdAt,
      );

  String get displayTime {
    final h = timeHour % 12 == 0 ? 12 : timeHour % 12;
    final m = timeMinute.toString().padLeft(2, '0');
    final period = timeHour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get repeatLabel {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 && !repeatDays.contains(5) && !repeatDays.contains(6)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && repeatDays.contains(5) && repeatDays.contains(6)) {
      return 'Weekends';
    }
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = [...repeatDays]..sort();
    return sorted.map((d) => names[d]).join(', ');
  }
}
