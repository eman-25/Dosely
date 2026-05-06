import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Init — call once in main.dart before runApp() ────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Ask for permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

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
    // Cancel existing notifications for this medicine first
    await cancelMedicine(id);

    for (final weekday in weekdays) {
      final int notifId = id * 10 + weekday;

      await _plugin.zonedSchedule(
        notifId,
        'Time to take $name',
        'Don\'t forget your medication!',
        _nextWeekdayTime(weekday, hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders',
            'Medicine Reminders',
            channelDescription: 'Reminds you to take your medicines on time',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  // ── Cancel all notifications for one medicine (up to 7 days) ─────────────
  static Future<void> cancelMedicine(int id) async {
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id * 10 + weekday);
    }
  }

  // ── Cancel every notification (call on logout) ────────────────────────────
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