import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/constants/app_constants.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/shared_models/alarm_model.dart';
import 'package:uuid/uuid.dart';

class AlarmNotifier extends AsyncNotifier<List<AlarmModel>> {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<List<AlarmModel>> build() async {
    final uid = _uid;
    if (uid == null) return [];
    return _fetchAlarms(uid);
  }

  Future<List<AlarmModel>> _fetchAlarms(String uid) async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.alarmsCollection)
        .orderBy('timeHour')
        .orderBy('timeMinute')
        .get();
    return snap.docs.map((d) => AlarmModel.fromMap(d.data())).toList();
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    final uid = _uid;
    if (uid == null) return;
    final id = _uuid.v4();
    final newAlarm = alarm.copyWith(id: id, userId: uid);

    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.alarmsCollection)
        .doc(id)
        .set(newAlarm.toMap());

    await _scheduleAlarm(newAlarm);
    state = AsyncData([...?state.value, newAlarm]);
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.alarmsCollection)
        .doc(alarm.id)
        .update(alarm.toMap());

    await NotificationService.cancelAlarm(alarm.id.hashCode);
    if (alarm.isEnabled) await _scheduleAlarm(alarm);

    final current = state.value ?? [];
    state = AsyncData(
      current.map((a) => a.id == alarm.id ? alarm : a).toList(),
    );
  }

  Future<void> deleteAlarm(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.alarmsCollection)
        .doc(id)
        .delete();

    await NotificationService.cancelAlarm(id.hashCode);

    final current = state.value ?? [];
    state = AsyncData(current.where((a) => a.id != id).toList());
  }

  Future<void> toggleAlarm(String id) async {
    final current = state.value ?? [];
    final alarm = current.firstWhere((a) => a.id == id);
    await updateAlarm(alarm.copyWith(isEnabled: !alarm.isEnabled));
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncLoading();
    state = AsyncData(await _fetchAlarms(uid));
  }

  Future<void> _scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;
    final notifId = alarm.id.hashCode;

    if (alarm.repeatDays.isEmpty) {
      final now = DateTime.now();
      var scheduled = DateTime(
          now.year, now.month, now.day, alarm.timeHour, alarm.timeMinute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await NotificationService.scheduleAlarm(
        id: notifId,
        title: alarm.label,
        body: 'Time to wake up! 🌅',
        scheduledTime: scheduled,
        payload: alarm.id,
      );
    } else {
      await NotificationService.scheduleRepeatingAlarm(
        id: notifId,
        title: alarm.label,
        body: 'Time to wake up! 🌅',
        hour: alarm.timeHour,
        minute: alarm.timeMinute,
        days: alarm.repeatDays.map((d) => d + 1).toList(),
        payload: alarm.id,
      );
    }
  }
}

final alarmNotifierProvider =
    AsyncNotifierProvider<AlarmNotifier, List<AlarmModel>>(AlarmNotifier.new);
