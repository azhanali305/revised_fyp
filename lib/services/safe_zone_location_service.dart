// Place this file at: lib/services/safe_zone_location_service.dart
//
// Watches the patient's live position and checks it against their saved
// SafeZoneModel list. No native geofencing API needed — geolocator's
// position stream + Geolocator.distanceBetween (Haversine) is enough,
// and it's much easier to test/debug than Android GeofencingClient /
// iOS CLCircularRegion.
//
// A small hysteresis buffer (_exitBufferMeters) stops GPS jitter near
// the zone boundary from firing repeated false "left the zone" alerts.

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/safe_zone_model.dart';

// NOTE: This service no longer fires enter/exit notifications itself.
// That responsibility moved to safe_zone_background_service.dart, which
// runs in an Android foreground service and keeps working even after
// the app is closed — something this UI-isolate listener cannot do.
// Keeping notification-firing in only one place avoids duplicate alerts
// when the app happens to be open at the same time the background
// service is also running.
//
// This service is still useful while the app IS open: it drives the
// live map / "You are currently at X" text on WhereAmIPage.

enum ZoneStatus { inside, outside }

class ZoneStatusUpdate {
  final Position position;
  final SafeZoneModel? currentZone; // the zone the patient is inside, if any
  final ZoneStatus status;

  ZoneStatusUpdate({
    required this.position,
    required this.currentZone,
    required this.status,
  });
}

class SafeZoneLocationService {
  static StreamSubscription<Position>? _sub;
  static final Map<String, bool> _wasInsideZone = {};
  static const double _exitBufferMeters = 20;

  static final StreamController<ZoneStatusUpdate> _controller =
      StreamController<ZoneStatusUpdate>.broadcast();

  /// Listen to this in the UI to show "You are currently at X" live.
  static Stream<ZoneStatusUpdate> get updates => _controller.stream;

  /// Requests location permission (When In Use -> Always) and checks
  /// location services are on. Returns false if the user denies it or
  /// GPS is off — the caller should show a friendly explanation, not a
  /// crash.
  ///
  /// Android 11+ (and iOS) don't allow asking for foreground and
  /// background location in a single prompt — it has to be two separate
  /// requests, with foreground granted first. This does that as two
  /// steps. If the user only ever grants "While Using," tracking still
  /// works, but only while the app is in the foreground.
  static Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }

    // Step 2: now that foreground ("While Using") is granted, ask again
    // to escalate to "Always" / background access. Only meaningful if
    // ACCESS_BACKGROUND_LOCATION is declared in AndroidManifest.xml —
    // without it, Android never offers this option at all.
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return true;
  }

  /// True if the patient has granted "Always"/background access —
  /// useful for showing a warning banner if they've only granted
  /// "While Using," since tracking will silently stop once the app is
  /// backgrounded in that case.
  static Future<bool> hasAlwaysPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Starts watching position against the patient's safe zones.
  /// [zonesProvider] is re-invoked on every position update so the zone
  /// list can change live (e.g. caregiver edits it while the patient's
  /// app is open) without needing to restart tracking.
  static Future<void> start({
    required String patientId,
    required List<SafeZoneModel> Function() zonesProvider,
  }) async {
    await stop();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15, // meters moved before a new update fires
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) => _onPosition(position, zonesProvider()));
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _wasInsideZone.clear();
  }

  static void _onPosition(Position position, List<SafeZoneModel> zones) {
    SafeZoneModel? currentZone;

    for (final zone in zones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      final wasInside = _wasInsideZone[zone.id] ?? false;
      // While already inside, require crossing radius + buffer before
      // counting as "exited" (hysteresis). While outside, entering is
      // just crossing the plain radius.
      final isInside = wasInside
          ? distance <= zone.radiusMeters + _exitBufferMeters
          : distance <= zone.radiusMeters;

      if (wasInside && !isInside) {
        // Exit detected — no notification fired here; see note at top
        // of file. Status still updates below for the live UI.
      } else if (!wasInside && isInside) {
        // Entry detected — same as above.
      }
      _wasInsideZone[zone.id] = isInside;

      if (isInside) currentZone = zone;
    }

    _controller.add(ZoneStatusUpdate(
      position: position,
      currentZone: currentZone,
      status: currentZone != null ? ZoneStatus.inside : ZoneStatus.outside,
    ));
  }
}