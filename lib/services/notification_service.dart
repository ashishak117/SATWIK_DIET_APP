// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  /// Initialize timezone and plugin. Call once at app startup.
  Future<void> init() async {
    // Initialize timezone database
    tzdata.initializeTimeZones();

    String tzName = 'UTC';
    try {
      tzName = await FlutterNativeTimezone.getLocalTimezone();
    } catch (e) {
      // fallback: keep UTC
    }

    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // handle tap when the app is running or backgrounded
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    // background tap handler (minimal)
  }

  NotificationDetails _platformDetails() {
    const android = AndroidNotificationDetails(
      'satwik_reminders',
      'Reminders',
      channelDescription: 'Daily meal & hydration reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'reminder',
    );
    const darwin = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: darwin, macOS: darwin);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  /// Schedule a daily repeating notification
  Future<void> scheduleDaily(
      int id,
      String title,
      String body,
      int hour,
      int minute, {
        AndroidScheduleMode androidMode = AndroidScheduleMode.inexact,
      }) async {
    final scheduled = _nextInstanceOf(hour, minute);
    await _fln.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _platformDetails(),
      androidScheduleMode: androidMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a one-off notification
  Future<void> scheduleOneOff(int id, String title, String body, DateTime when,
      {AndroidScheduleMode androidMode = AndroidScheduleMode.exactAllowWhileIdle}) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    await _fln.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      _platformDetails(),
      androidScheduleMode: androidMode,
    );
  }

  /// Schedule hydration series
  Future<List<int>> scheduleHydrationSeries({
    required String baseIdKey,
    required String title,
    required String body,
    required int startHour,
    required int startMinute,
    required int intervalHours,
    int count = 8,
    AndroidScheduleMode androidMode = AndroidScheduleMode.inexact,
  }) async {
    final List<int> scheduledIds = [];
    final base = (baseIdKey.hashCode & 0x7fffffff);
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < count; i++) {
      final id = (base + i) % 2147483647;
      tz.TZDateTime scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        startHour,
        startMinute,
      ).add(Duration(hours: intervalHours * i));
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
      await _fln.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _platformDetails(),
        androidScheduleMode: androidMode,
      );
      scheduledIds.add(id);
    }
    return scheduledIds;
  }

  Future<void> cancel(int id) => _fln.cancel(id);
  Future<void> cancelAll() => _fln.cancelAll();
}
