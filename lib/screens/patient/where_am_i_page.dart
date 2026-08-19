// Place this file at: lib/screens/patient/where_am_i_page.dart
// (replacing your current version)
//
// Back on flutter_map (OSM, no API key) instead of google_maps_flutter.
// Logic is otherwise unchanged: reads active patientId, loads safe
// zones, starts SafeZoneLocationService (live UI status) + the
// persistent background service (real alerting, survives app close),
// and shows an "Always permission" warning banner if only "While Using"
// was granted.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/safe_zone_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/safe_zone_location_service.dart';
import '../../services/safe_zone_background_service.dart';

class WhereAmIPage extends StatefulWidget {
  const WhereAmIPage({super.key});

  @override
  State<WhereAmIPage> createState() => _WhereAmIPageState();
}

class _WhereAmIPageState extends State<WhereAmIPage> {
  StreamSubscription<ZoneStatusUpdate>? _sub;
  ZoneStatusUpdate? _latest;
  List<SafeZoneModel> _zones = [];
  String? _patientId;
  bool _permissionDenied = false;
  bool _alwaysGranted = true; // assume true until checked, to avoid a flash
  bool _noProfile = false;
  String? _error;
  bool _loading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final patientId = PatientDataService.getActivePatientId();
      if (patientId == null) {
        setState(() {
          _noProfile = true;
          _loading = false;
        });
        return;
      }
      _patientId = patientId;
      _zones = PatientDataService.getSafeZones(_patientId!);

      final granted = await SafeZoneLocationService.ensurePermission();
      if (!granted) {
        setState(() {
          _permissionDenied = true;
          _loading = false;
        });
        return;
      }

      // Isolated on purpose: if the background service fails to start
      // for any reason (native platform exception, plugin issue, etc.),
      // that alone shouldn't crash this screen — foreground tracking
      // below still works fine while the app is open.
      try {
        await startSafeZoneBackgroundService();
      } catch (e, st) {
        debugPrint('startSafeZoneBackgroundService() failed: $e\n$st');
      }

      await SafeZoneLocationService.start(
        patientId: _patientId!,
        zonesProvider: () {
          _zones = PatientDataService.getSafeZones(_patientId!);
          return _zones;
        },
      );

      final alwaysGranted = await SafeZoneLocationService.hasAlwaysPermission();
      if (mounted) setState(() => _alwaysGranted = alwaysGranted);

      _sub = SafeZoneLocationService.updates.listen((update) {
        if (!mounted) return;
        setState(() {
          _latest = update;
          _loading = false;
        });
        _mapController.move(
          ll.LatLng(update.position.latitude, update.position.longitude),
          16,
        );
      });

      // In case no position update has arrived yet (e.g. slow GPS fix),
      // stop showing the spinner once permission + zones are confirmed
      // rather than blocking indefinitely on the first fix.
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    } catch (e, st) {
      debugPrint('WhereAmIPage._init() failed: $e\n$st');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Something went wrong setting up location tracking. '
              'Please try reopening this page.';
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Tracking intentionally keeps running via the background service
    // even after this screen closes — see safe_zone_background_service.dart.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Where Am I'),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildMessage(context, _error!, icon: Icons.error_outline_rounded)
                : _noProfile
                ? _buildMessage(context, 'No patient profile found on this device.')
                : _permissionDenied
                    ? _buildMessage(
                        context,
                        'Location access is needed for this feature to work. '
                        'Please enable it in your phone\'s Settings.',
                        icon: Icons.location_off_rounded,
                      )
                    : _buildContent(context),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String message,
      {IconData icon = Icons.info_outline_rounded}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.caregiver),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final position = _latest?.position;
    final currentZone = _latest?.currentZone;
    final center = position != null
        ? ll.LatLng(position.latitude, position.longitude)
        : (_zones.isNotEmpty
            ? ll.LatLng(_zones.first.latitude, _zones.first.longitude)
            : const ll.LatLng(0, 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_alwaysGranted) ...[
            AppListCard(
              child: Row(
                children: [
                  const IconBadge(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    background: AppColors.accentLight,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location access is limited to "While Using the App."',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Alerts won\'t work while the app is closed or the '
                          'screen is off. Tap below to allow it all the time.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open Location Settings'),
            ),
            const SizedBox(height: 20),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: SizedBox(
              height: 260,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: center, initialZoom: 16),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // Set this to your real applicationId (see build.gradle).
                    userAgentPackageName: 'com.example.fyp_revised',
                  ),
                  CircleLayer(
                    circles: _zones
                        .map((z) => CircleMarker(
                              point: ll.LatLng(z.latitude, z.longitude),
                              radius: z.radiusMeters,
                              useRadiusInMeter: true,
                              color: AppColors.caregiver.withOpacity(0.15),
                              borderColor: AppColors.caregiver,
                              borderStrokeWidth: 2,
                            ))
                        .toList(),
                  ),
                  if (position != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: ll.LatLng(position.latitude, position.longitude),
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.caregiver,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_pin_circle_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            currentZone != null ? 'You are safe at:' : 'You are currently at:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            currentZone?.name ?? 'Outside your safe zones',
            style: Theme.of(context).textTheme.headlineLarge,
          ),

          const SizedBox(height: 24),
          AppListCard(
            child: Row(
              children: [
                const IconBadge(
                    icon: Icons.access_time_rounded,
                    color: AppColors.primary,
                    background: AppColors.primaryLight),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('It is currently', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Text(_formattedNow(), style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          BigPrimaryButton(
            label: 'Call Caregiver',
            icon: Icons.phone_rounded,
            color: AppColors.caregiver,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Calling…'),
                  content: const Text('This is a UI placeholder — no call is actually placed.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formattedNow() {
    final now = DateTime.now();
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period · ${days[now.weekday - 1]}';
  }
}