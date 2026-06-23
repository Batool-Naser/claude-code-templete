class SleepRecord {
  final String id;
  final String userId;
  final String date; // YYYY-MM-DD
  final int bedTimeHour;
  final int bedTimeMinute;
  final int wakeTimeHour;
  final int wakeTimeMinute;
  final int qualityRating; // 1-5
  final String? notes;
  final double? sleepScore;
  final List<String> aiInsights;
  final DateTime createdAt;

  const SleepRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.bedTimeHour,
    required this.bedTimeMinute,
    required this.wakeTimeHour,
    required this.wakeTimeMinute,
    this.qualityRating = 3,
    this.notes,
    this.sleepScore,
    this.aiInsights = const [],
    required this.createdAt,
  });

  factory SleepRecord.fromMap(Map<String, dynamic> map) => SleepRecord(
        id: map['id'] as String,
        userId: map['userId'] as String,
        date: map['date'] as String,
        bedTimeHour: (map['bedTimeHour'] as num).toInt(),
        bedTimeMinute: (map['bedTimeMinute'] as num).toInt(),
        wakeTimeHour: (map['wakeTimeHour'] as num).toInt(),
        wakeTimeMinute: (map['wakeTimeMinute'] as num).toInt(),
        qualityRating: (map['qualityRating'] as num?)?.toInt() ?? 3,
        notes: map['notes'] as String?,
        sleepScore: (map['sleepScore'] as num?)?.toDouble(),
        aiInsights: List<String>.from(map['aiInsights'] ?? []),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'date': date,
        'bedTimeHour': bedTimeHour,
        'bedTimeMinute': bedTimeMinute,
        'wakeTimeHour': wakeTimeHour,
        'wakeTimeMinute': wakeTimeMinute,
        'qualityRating': qualityRating,
        if (notes != null) 'notes': notes,
        if (sleepScore != null) 'sleepScore': sleepScore,
        'aiInsights': aiInsights,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  /// Duration in minutes
  int get durationMinutes {
    final bedTotal = bedTimeHour * 60 + bedTimeMinute;
    var wakeTotal = wakeTimeHour * 60 + wakeTimeMinute;
    if (wakeTotal <= bedTotal) wakeTotal += 24 * 60; // next day
    return wakeTotal - bedTotal;
  }

  String get durationLabel {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get bedTimeLabel {
    final h = bedTimeHour % 12 == 0 ? 12 : bedTimeHour % 12;
    final m = bedTimeMinute.toString().padLeft(2, '0');
    final p = bedTimeHour < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String get wakeTimeLabel {
    final h = wakeTimeHour % 12 == 0 ? 12 : wakeTimeHour % 12;
    final m = wakeTimeMinute.toString().padLeft(2, '0');
    final p = wakeTimeHour < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  SleepRecord copyWith({
    String? id,
    String? userId,
    String? date,
    int? bedTimeHour,
    int? bedTimeMinute,
    int? wakeTimeHour,
    int? wakeTimeMinute,
    int? qualityRating,
    String? notes,
    double? sleepScore,
    List<String>? aiInsights,
    DateTime? createdAt,
  }) =>
      SleepRecord(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        date: date ?? this.date,
        bedTimeHour: bedTimeHour ?? this.bedTimeHour,
        bedTimeMinute: bedTimeMinute ?? this.bedTimeMinute,
        wakeTimeHour: wakeTimeHour ?? this.wakeTimeHour,
        wakeTimeMinute: wakeTimeMinute ?? this.wakeTimeMinute,
        qualityRating: qualityRating ?? this.qualityRating,
        notes: notes ?? this.notes,
        sleepScore: sleepScore ?? this.sleepScore,
        aiInsights: aiInsights ?? this.aiInsights,
        createdAt: createdAt ?? this.createdAt,
      );
}
