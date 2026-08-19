// Place this file at: lib/services/safe_zone_notification_service.dart
//
// Fires immediate local notifications when the patient enters/leaves a
// safe zone. Mirrors RoutineNotificationService's setup style, but uses
// .show() instead of .zonedSchedule() since these are triggered by a
// live location event, not a clock time — no timezone setup needed.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/safe_zone_model.dart';

class SafeZoneNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'safe_zone_channel';
  static const _channelName = 'Safe Zone Alerts';
  static const _channelDesc =
      'Alerts when leaving or returning to a safe zone';

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> notifyLeftZone(SafeZoneModel zone) => _show(
        id: (zone.id.hashCode & 0x7FFFFFFF),
        title: 'Leaving ${zone.name}',
        body: 'You are moving away from ${zone.name}. Stay safe!',
      );

  static Future<void> notifyEnteredZone(SafeZoneModel zone) => _show(
        id: (zone.id.hashCode & 0x7FFFFFFF) + 1,
        title: 'Back at ${zone.name}',
        body: "You're back at ${zone.name}.",
      );

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      visibility: NotificationVisibility.public,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details);
  }
}