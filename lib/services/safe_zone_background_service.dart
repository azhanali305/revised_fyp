// Place this file at: lib/services/safe_zone_background_service.dart
//
// Runs the safe-zone geofence check inside an Android foreground service,
// so it keeps working even after the app is swiped away from Recents —
// something a plain Geolocator.getPositionStream() listener inside the
// normal app process cannot do, since Android kills that process once
// the UI is gone.
//
// IMPORTANT — isolate boundary: onStart() runs in a SEPARATE Dart
// isolate from your UI. It does NOT share Hive's open boxes, registered
// adapters, or any plugin instance with the UI isolate. Everything this
// isolate needs (Hive, PatientDataService, flutter_local_notifications)
// is re-initialized from scratch inside onStart() below.
//
// Because notifications now fire from here — not from
// SafeZoneLocationService anymore — they fire exactly once whether the
// app is open, backgrounded, or fully closed. (See the matching change
// in safe_zone_location_service.dart: it no longer calls
// SafeZoneNotificationService itself, to avoid firing twice while the
// app happens to be open at the same time this service is running.)
//
// iOS: Apple does not allow a persistent foreground service at all.
// Background location on iOS instead relies on the
// NSLocationAlwaysAndWhenInUseUsageDescription entry in Info.plist and
// the "Location updates" Background Mode enabled in Xcode — iOS itself
// briefly wakes the app to deliver location updates while it's
// suspended. The iOS config below is required by the package but is a
// light no-op compared to the Android foreground service.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../hive_registrar.g.dart';
import 'patient_data_service.dart';

const _fgChannelId = 'safe_zone_tracking_service';
const _fgChannelName = 'Safe Zone Tracking';
const _fgNotificationId = 9001;

// Alert channel — separate from the service's own persistent
// notification, matches SafeZoneNotificationService's old channel id so
// existing user notification settings for it carry over.
const _alertChannelId = 'safe_zone_channel';
const _alertChannelName = 'Safe Zone Alerts';
const _alertChannelDesc = 'Alerts when leaving or returning to a safe zone';

Future<void> initializeSafeZoneBackgroundService() async {
  final service = FlutterBackgroundService();

  // Required by the package: a custom notificationChannelId must exist
  // BEFORE configure() runs, or the service crashes when it tries to
  // show its persistent notification.
  const channel = AndroidNotificationChannel(
    _fgChannelId,
    _fgChannelName,
    description: 'Keeps safe-zone tracking running in the background',
    importance: Importance.low, // low = no sound/heads-up, just persistent
  );
  final setupPlugin = FlutterLocalNotificationsPlugin();
  await setupPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      autoStart: false, // started explicitly once location permission is granted
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: _fgChannelId,
      initialNotificationTitle: 'Location sharing active',
      initialNotificationContent: 'Keeping you safe while the app is closed.',
      foregroundServiceNotificationId: _fgNotificationId,
      // Required on Android 14+ (API 34): every foreground service must
      // declare its type, matching the FOREGROUND_SERVICE_LOCATION
      // permission in AndroidManifest.xml, or the OS throws at startup.
      foregroundServiceTypes: const [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onServiceStart,
      onBackground: _onIosBackground,
    ),
  );
}

Future<void> startSafeZoneBackgroundService() async {
  final service = FlutterBackgroundService();
  if (!await service.isRunning()) {
    await service.startService();
  }
}

Future<void> stopSafeZoneBackgroundService() async {
  final service = FlutterBackgroundService();
  service.invoke('stop');
}

@pragma('vm:entry-point')
bool _onIosBackground(ServiceInstance service) => true;

@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  // --- Re-init everything this isolate needs from scratch ---
  await Hive.initFlutter();
  Hive.registerAdapters();
  // PatientDataService.init() only opens patient_profiles/memories/
  // calming_items/routine_tasks/safe_zones — NOT the 'patient' box
  // (that one is opened separately in main.dart, in the UI isolate
  // only). getActivePatientId() below reads from 'patient', so it must
  // be opened here explicitly too, or Hive throws "Box not found" the
  // instant a position comes in — which was crashing this isolate (and
  // the app) every time.
  await Hive.openBox(PatientDataService.patientBoxName);
  await PatientDataService.init();

  final notifPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifPlugin.initialize(
    const InitializationSettings(android: androidInit),
  );

  service.on('stop').listen((event) {
    service.stopSelf();
  });

  final Map<String, bool> wasInside = {};
  const exitBufferMeters = 20.0;

  StreamSubscription<Position>? sub;
  sub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    ),
  ).listen((position) async {
    try {
      await _handlePosition(service, notifPlugin, position, wasInside, exitBufferMeters);
    } catch (e, st) {
      // Never let an error here kill the whole isolate/service again —
      // log it and keep tracking on the next position update instead.
      debugPrint('safe_zone_background_service position handling error: $e\n$st');
    }
  });
}

Future<void> _handlePosition(
  ServiceInstance service,
  FlutterLocalNotificationsPlugin notifPlugin,
  Position position,
  Map<String, bool> wasInside,
  double exitBufferMeters,
) async {
    final patientId = PatientDataService.getActivePatientId();
    if (patientId == null) return;
    final zones = PatientDataService.getSafeZones(patientId);

    String? currentZoneName;

    for (final zone in zones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      final was = wasInside[zone.id] ?? false;
      final isInside = was
          ? distance <= zone.radiusMeters + exitBufferMeters
          : distance <= zone.radiusMeters;

      if (was && !isInside) {
        await _showAlert(
          notifPlugin,
          id: zone.id.hashCode & 0x7FFFFFFF,
          title: 'Leaving ${zone.name}',
          body: 'You are moving away from ${zone.name}. Stay safe!',
        );
      } else if (!was && isInside) {
        await _showAlert(
          notifPlugin,
          id: (zone.id.hashCode & 0x7FFFFFFF) + 1,
          title: 'Back at ${zone.name}',
          body: "You're back at ${zone.name}.",
        );
      }
      wasInside[zone.id] = isInside;
      if (isInside) currentZoneName = zone.name;
    }

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: currentZoneName != null
            ? 'Currently at $currentZoneName'
            : 'Outside safe zones',
        content: zones.isEmpty
            ? 'No safe zones set yet'
            : 'Tracking against ${zones.length} safe zone(s)',
      );
    }

    // Push the live position to the UI isolate too, in case
    // WhereAmIPage is open at the same time — see
    // safe_zone_location_service.dart for the receiving side.
    service.invoke('position_update', {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'currentZoneName': currentZoneName,
    });
}

Future<void> _showAlert(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String title,
  required String body,
}) async {
  const androidDetails = AndroidNotificationDetails(
    _alertChannelId,
    _alertChannelName,
    channelDescription: _alertChannelDesc,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    visibility: NotificationVisibility.public,
  );
  const details = NotificationDetails(android: androidDetails);
  await plugin.show(id, title, body, details);
}