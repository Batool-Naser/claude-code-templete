import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/core/agents/sleep_agent.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/services/ai_service.dart';
import 'package:todo_app/core/shared_models/sleep_record_model.dart';
import 'package:todo_app/core/shared_models/user_profile_model.dart';
import 'package:uuid/uuid.dart';

class SleepAnalysisState {
  final List<SleepRecord> recentRecords;
  final List<String> aiInsights;
  final String? weeklyReport;
  final bool isLoadingInsights;

  const SleepAnalysisState({
    this.recentRecords = const [],
    this.aiInsights = const [],
    this.weeklyReport,
    this.isLoadingInsights = false,
  });

  SleepAnalysisState copyWith({
    List<SleepRecord>? recentRecords,
    List<String>? aiInsights,
    String? weeklyReport,
    bool? isLoadingInsights,
  }) =>
      SleepAnalysisState(
        recentRecords: recentRecords ?? this.recentRecords,
        aiInsights: aiInsights ?? this.aiInsights,
        weeklyReport: weeklyReport ?? this.weeklyReport,
        isLoadingInsights: isLoadingInsights ?? this.isLoadingInsights,
      );

  double get avgSleepHours {
    if (recentRecords.isEmpty) return 0;
    final total = recentRecords.map((r) => r.durationMinutes).reduce((a, b) => a + b);
    return total / recentRecords.length / 60.0;
  }

  double get avgScore {
    if (recentRecords.isEmpty) return 0;
    final total = recentRecords
        .where((r) => r.sleepScore != null)
        .map((r) => r.sleepScore!)
        .fold<double>(0, (a, b) => a + b);
    final count = recentRecords.where((r) => r.sleepScore != null).length;
    return count == 0 ? 0 : total / count;
  }

  double get avgQuality {
    if (recentRecords.isEmpty) return 0;
    return recentRecords.map((r) => r.qualityRating).reduce((a, b) => a + b) /
        recentRecords.length;
  }
}

class SleepAnalysisNotifier extends AsyncNotifier<SleepAnalysisState> {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  late final SleepAgent _agent;

  @override
  Future<SleepAnalysisState> build() async {
    _agent = SleepAgent(aiServiceInstance);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SleepAnalysisState();
    return _load(uid);
  }

  Future<SleepAnalysisState> _load(String uid) async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.sleepRecordsCollection)
        .orderBy('date', descending: true)
        .limit(14)
        .get();

    final records = snap.docs.map((d) => SleepRecord.fromMap(d.data())).toList();
    return SleepAnalysisState(recentRecords: records);
  }

  Future<void> logSleep({
    required int bedHour,
    required int bedMinute,
    required int wakeHour,
    required int wakeMinute,
    required int quality,
    String? notes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final id = _uuid.v4();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Calculate score
    var record = SleepRecord(
      id: id,
      userId: uid,
      date: today,
      bedTimeHour: bedHour,
      bedTimeMinute: bedMinute,
      wakeTimeHour: wakeHour,
      wakeTimeMinute: wakeMinute,
      qualityRating: quality,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final score = await _agent.calculateSleepScore(
      record,
      UserProfileModel(id: uid, email: '', targetSleepHours: 8, createdAt: DateTime.now()),
    );
    record = record.copyWith(sleepScore: score);

    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.sleepRecordsCollection)
        .doc(id)
        .set(record.toMap());

    final current = state.value ?? const SleepAnalysisState();
    state = AsyncData(
      current.copyWith(recentRecords: [record, ...current.recentRecords]),
    );
  }

  Future<void> loadAIInsights() async {
    final current = state.value ?? const SleepAnalysisState();
    state = AsyncData(current.copyWith(isLoadingInsights: true));
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final insights = await _agent.generateSleepInsights(
      records: current.recentRecords,
      profile: UserProfileModel(id: uid, email: '', targetSleepHours: 8, createdAt: DateTime.now()),
    );
    state = AsyncData(current.copyWith(
      aiInsights: insights,
      isLoadingInsights: false,
    ));
  }

  Future<void> refresh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = AsyncData(await _load(uid));
  }
}

final sleepAnalysisNotifierProvider =
    AsyncNotifierProvider<SleepAnalysisNotifier, SleepAnalysisState>(
        SleepAnalysisNotifier.new);
