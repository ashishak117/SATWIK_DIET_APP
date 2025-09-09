// lib/services/reminder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import 'notification_service.dart';

class ReminderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notif = NotificationService();

  CollectionReference<Map<String, dynamic>> remindersRef(String uid) =>
      _db.collection('profiles').doc(uid).collection('reminders');

  Future<List<Reminder>> getReminders(String uid) async {
    final snapshot = await remindersRef(uid).get();
    return snapshot.docs.map((d) => Reminder.fromMap(d.id, d.data())).toList();
  }

  Future<void> saveReminder(String uid, Reminder r) async {
    try {
      final ref = r.id.isNotEmpty ? remindersRef(uid).doc(r.id) : remindersRef(uid).doc();
      final docId = ref.id;
      final reminderToSave = r.copyWith(id: docId);

      // Write to Firestore (owner-restricted by rules)
      await ref.set(reminderToSave.toMap());

      // After successful write, schedule notifications (local)
      await _scheduleForReminder(reminderToSave);
    } on FirebaseException catch (fe) {
      // Re-throw with clearer message for the UI
      debugPrint('ReminderService.saveReminder: FirebaseException: ${fe.code} ${fe.message}');
      rethrow;
    } catch (e) {
      debugPrint('ReminderService.saveReminder: unknown error: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String uid, String id) async {
    try {
      final base = (id.hashCode & 0x7fffffff);
      for (int i = 0; i < 32; i++) {
        final idToCancel = (base + i) % 2147483647;
        await _notif.cancel(idToCancel);
      }
      await remindersRef(uid).doc(id).delete();
    } on FirebaseException catch (fe) {
      debugPrint('ReminderService.deleteReminder: FirebaseException: ${fe.code} ${fe.message}');
      rethrow;
    }
  }

  Future<void> toggleReminderEnabled(String uid, Reminder r, bool enabled) async {
    try {
      final updated = r.copyWith(enabled: enabled);
      await remindersRef(uid).doc(r.id).set(updated.toMap());
      if (enabled) {
        await _scheduleForReminder(updated);
      } else {
        final base = (r.id.hashCode & 0x7fffffff);
        for (int i = 0; i < 32; i++) {
          final idToCancel = (base + i) % 2147483647;
          await _notif.cancel(idToCancel);
        }
      }
    } on FirebaseException catch (fe) {
      debugPrint('ReminderService.toggleReminderEnabled: FirebaseException: ${fe.code} ${fe.message}');
      rethrow;
    }
  }

  Future<void> _scheduleForReminder(Reminder r) async {
    if (!r.enabled) return;
    final baseKey = r.id;

    if (r.type == 'hydration' && r.intervalHours > 0) {
      int count = (24 / (r.intervalHours > 0 ? r.intervalHours : 1)).ceil();
      await _notif.scheduleHydrationSeries(
        baseIdKey: baseKey,
        title: r.title,
        body: r.body,
        startHour: r.hour,
        startMinute: r.minute,
        intervalHours: r.intervalHours,
        count: count,
      );
    } else {
      final id = (baseKey.hashCode & 0x7fffffff) % 2147483647;
      await _notif.scheduleDaily(id, r.title, r.body, r.hour, r.minute);
    }
  }

  Future<void> resyncAllForUser(String uid) async {
    final items = await getReminders(uid);
    for (final r in items) {
      if (r.enabled) await _scheduleForReminder(r);
    }
  }
}
