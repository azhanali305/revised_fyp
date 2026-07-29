// Place this file at: lib/services/routine_notification_service.dart
//
// Schedules OS-level notifications for RoutineTaskModel entries. Because
// caregiver and patient share the same device, a plain local notification
// (no Firebase Cloud Messaging) is enough — the OS fires it even if the
// app is fully closed, and on Android it opens straight to a centered
// popup (full-screen intent), the same way a real alarm clock does.
//
// On iOS, Apple does not allow any app to auto-launch a full-screen UI
// without the user tapping the notification first — that's a hard OS
// rule. So on iOS this shows a banner + gentle sound, and tapping it
// opens the same centered screen.

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/routine_task_model.dart';

class RoutineNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Called when a notification is tapped, or (Android only) when the
  /// full-screen intent fires and launches the app directly.
  /// Payload format: "patientId|taskId"
  static Future<void> Function(String patientId, String taskId)?
      onNotificationOpened;

  static const _channelId = 'routine_task_channel';
  static const _channelName = 'Routine Reminders';
  static const _channelDesc = 'Reminders that pop up at each routine task\'s scheduled time';

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    // IMPORTANT: tz.local defaults to UTC. Without this, every scheduled
    // time is interpreted as UTC instead of the device's actual timezone,
    // which silently shifts every reminder by your UTC offset.
    final deviceTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimezone));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || onNotificationOpened == null) return;
        final parts = payload.split('|');
        if (parts.length == 2) {
          await onNotificationOpened!(parts[0], parts[1]);
        }
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Needed on Android 12+ so the reminder fires at the exact minute
    // instead of being delayed by the OS.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Notification ids must be 32-bit ints; derive a stable one per task.
  static int _notificationId(RoutineTaskModel task) =>
      task.id.hashCode & 0x7FFFFFFF;

  /// Schedules (or reschedules) the popup for a task. Does nothing if
  /// notifyEnabled is false — call [cancel] instead in that case.
  static Future<void> schedule(RoutineTaskModel task) async {
    if (!task.notifyEnabled) {
      await cancel(task);
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      // Makes it pop up on screen like an alarm instead of sitting
      // quietly in the notification shade.
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      // Gentle default sound, not a blaring alarm tone. To use a custom
      // sound, add e.g. android/app/src/main/res/raw/gentle_chime.mp3
      // and set: sound: const RawResourceAndroidNotificationSound('gentle_chime'),
      playSound: true,
      visibility: NotificationVisibility.public,
      ticker: task.title,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final scheduledDate = _nextOccurrence(task.hour, task.minute);

    await _plugin.zonedSchedule(
      _notificationId(task),
      task.title,
      task.category, // body text — model has no separate description field
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          task.repeatDaily ? DateTimeComponents.time : null,
      payload: '${task.patientId}|${task.id}',
    );
  }

  static Future<void> cancel(RoutineTaskModel task) async {
    await _plugin.cancel(_notificationId(task));
  }

  /// One-off re-fire a fixed duration from now (used by the Snooze button
  /// on the alarm screen). Does not touch the task's regular daily
  /// schedule — that gets restored next time [schedule] runs.
  static Future<void> snooze(RoutineTaskModel task, Duration delay) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      visibility: NotificationVisibility.public,
      ticker: task.title,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final fireAt = tz.TZDateTime.now(tz.local).add(delay);

    await _plugin.zonedSchedule(
      _notificationId(task),
      task.title,
      task.category,
      fireAt,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '${task.patientId}|${task.id}',
    );
  }


  /// Next time today/tomorrow that matches hour:minute, so we never
  /// schedule something "in the past" for today.
  static tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Call once at startup to find out if the app was cold-launched by
  /// tapping a notification (useful on iOS, and as a fallback on Android).
  static Future<(String patientId, String taskId)?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      final payload = details.notificationResponse?.payload;
      if (payload != null) {
        final parts = payload.split('|');
        if (parts.length == 2) return (parts[0], parts[1]);
      }
    }
    return null;
  }
}