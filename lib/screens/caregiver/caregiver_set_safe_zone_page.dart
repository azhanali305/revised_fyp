// Place this file at: lib/screens/caregiver/caregiver_set_safe_zone_page.dart
//
// Back on flutter_map (OSM, no API key) instead of google_maps_flutter.
// Search an address, tap the map to drop the pin, drag a slider for
// radius, name it, save.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geocoding/geocoding.dart';
import '../../button.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/safe_zone_model.dart';
import '../../services/patient_data_service.dart';

class CaregiverSetSafeZonePage extends StatefulWidget {
  final String patientId;
  final SafeZoneModel? existingZone; // pass this to edit instead of create

  const CaregiverSetSafeZonePage({
    super.key,
    required this.patientId,
    this.existingZone,
  });

  @override
  State<CaregiverSetSafeZonePage> createState() =>
      _CaregiverSetSafeZonePageState();
}

class _CaregiverSetSafeZonePageState extends State<CaregiverSetSafeZonePage> {
  late ll.LatLng _center;
  double _radius = 150;
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingZone;
    if (existing != null) {
      _center = ll.LatLng(existing.latitude, existing.longitude);
      _radius = existing.radiusMeters;
      _nameController.text = existing.name;
    } else {
      // Fallback center before the caregiver searches/taps a location.
      _center = const ll.LatLng(31.5204, 74.3587);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final results = await locationFromAddress(query);
      if (results.isNotEmpty) {
        final loc = results.first;
        setState(() => _center = ll.LatLng(loc.latitude, loc.longitude));
        _mapController.move(_center, 16);
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Address not found')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not search that address')));
      }
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please name this safe zone')));
      return;
    }
    setState(() => _saving = true);

    final zone = SafeZoneModel(
      id: widget.existingZone?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.patientId,
      name: _nameController.text.trim(),
      latitude: _center.latitude,
      longitude: _center.longitude,
      radiusMeters: _radius,
      createdAt: widget.existingZone?.createdAt ?? DateTime.now(),
    );

    await PatientDataService.saveSafeZone(zone);

    if (mounted) Navigator.pop(context, zone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleTopBar(
          title: widget.existingZone == null ? 'Set Safe Zone' : 'Edit Safe Zone'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search an address…',
                  suffixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card)),
                ),
                onSubmitted: _searchAddress,
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 16,
                  onTap: (tapPosition, point) => setState(() => _center = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // Required by OSM's tile usage policy — set this to
                    // your actual applicationId from android/app/build.gradle.
                    userAgentPackageName: 'com.example.fyp_revised',
                  ),
                  CircleLayer(circles: [
                    CircleMarker(
                      point: _center,
                      radius: _radius,
                      useRadiusInMeter: true,
                      color: AppColors.caregiver.withOpacity(0.15),
                      borderColor: AppColors.caregiver,
                      borderStrokeWidth: 2,
                    ),
                  ]),
                  MarkerLayer(markers: [
                    Marker(
                      point: _center,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.caregiver, size: 40),
                    ),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Zone name (e.g. Home)',
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Radius: ${_radius.round()} m',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Slider(
                    value: _radius,
                    min: 50,
                    max: 500,
                    divisions: 45,
                    label: '${_radius.round()} m',
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  const SizedBox(height: 8),
                  BigPrimaryButton(
                    label: _saving ? 'Saving…' : 'Save Safe Zone',
                    icon: Icons.check_rounded,
                    color: AppColors.caregiver,
                    onTap: _saving ? () {} : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}