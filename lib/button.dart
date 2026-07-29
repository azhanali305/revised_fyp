// Add a temporary button anywhere and call this. If this doesn't show
// a notification INSTANTLY, the problem is in setup/init — not in
// scheduling, timing, or alarm permissions at all.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> debugShowNow() async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  final initResult = await plugin.initialize(
    const InitializationSettings(android: androidInit),
  );
  // ignore: avoid_print
  print('Plugin init result: $initResult');

  const androidDetails = AndroidNotificationDetails(
    'debug_channel',
    'Debug',
    importance: Importance.max,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);

  try {
    await plugin.show(1, 'Immediate test', 'If you see this, the plugin works', details);
    // ignore: avoid_print
    print('show() completed without throwing');
  } catch (e, st) {
    // ignore: avoid_print
    print('show() FAILED: $e');
    // ignore: avoid_print
    print(st);
  }
}