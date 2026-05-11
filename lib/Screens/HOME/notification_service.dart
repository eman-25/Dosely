import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId          = 'medicine_reminders';
  static const _channelName        = 'Medicine Reminders';
  static const _channelDescription = 'Reminds you to take your medicines on time';

  // ── Init — call once in main.dart before runApp() ────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final tzName = 'Etc/GMT${DateTime.now().timeZoneOffset.inHours >= 0 ? '-' : '+'}${DateTime.now().timeZoneOffset.inHours.abs()}';
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      // Create the notification channel so Dosely appears in system settings
      // immediately — even before the first notification is shown.
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      );

      // Request POST_NOTIFICATIONS permission (Android 13+)
      await androidImpl.requestNotificationsPermission();

      // Request SCHEDULE_EXACT_ALARM permission (Android 12+)
      // Without this exact alarms silently fall back to inexact.
      await androidImpl.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  // ── Schedule notifications for a medicine ────────────────────────────────
  static Future<void> scheduleMedicine({
    required int id,
    required String name,
    required int hour,
    required int minute,
    required List<int> weekdays,
  }) async {
    await cancelMedicine(id);

    for (final weekday in weekdays) {
      final int notifId = id * 10 + weekday;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      final scheduledTime = _nextWeekdayTime(weekday, hour, minute);
      try {
        await _plugin.zonedSchedule(
          notifId,
          'Time to take $name 💊',
          "Don't forget your medication!",
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (_) {
        // Exact alarms not permitted — fall back to inexact scheduling
        await _plugin.zonedSchedule(
          notifId,
          'Time to take $name 💊',
          "Don't forget your medication!",
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  // ── Cancel all notifications for one medicine ─────────────────────────────
  static Future<void> cancelMedicine(int id) async {
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id * 10 + weekday);
    }
  }

  // ── Cancel every notification ─────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Next occurrence of weekday at given time ──────────────────────────────
  static tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (candidate.weekday != weekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  // ── Convert Firestore doc ID to a stable int ──────────────────────────────
  static int idFromDocId(String docId) {
    return docId.hashCode.abs() % 100000;
  }
}