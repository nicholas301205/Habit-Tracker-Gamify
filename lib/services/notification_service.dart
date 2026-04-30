import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/habit_model.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Makassar')); // Sesuaikan dengan zona waktu Anda

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> scheduleDailyReminder({
  required int id,
  required String habitName,
  required int hour,
  required int minute,
}) async {
  await _plugin.zonedSchedule(
    id,
    'Waktunya Habit! ⏰',
    'Jangan lupa: $habitName hari ini',
    _nextInstanceOf(hour, minute),
    NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_reminder',
        'Habit Reminder',
        channelDescription: 'Pengingat habit harian',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // ✅ FIX
    matchDateTimeComponents: DateTimeComponents.time,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> rescheduleAllHabits(List<HabitModel> habits) async {
    // Cancel all existing notifications first
    await cancelAll();

    // Schedule notifications for habits with reminder times
    for (final habit in habits) {
      if (habit.reminderTime != null && habit.isActive) {
        await scheduleDailyReminder(
          id: habit.name.hashCode,
          habitName: habit.name,
          hour: habit.reminderTime!.hour,
          minute: habit.reminderTime!.minute,
        );
      }
    }
  }

  static Future<void> showTestNotification() async {
    await _plugin.show(
      999,
      'Test Notifikasi 🔔',
      'Notifikasi berhasil! HabitQuest siap mengingatkanmu.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_test',
          'Test',
          importance: Importance.high,
        ),
      ),
    );
  }
}