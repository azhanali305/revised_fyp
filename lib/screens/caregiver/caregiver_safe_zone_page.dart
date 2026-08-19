// Place this file at: lib/screens/caregiver/caregiver_safe_zone_page.dart
//
// Mirrors caregiver_memory_page.dart's structure exactly: loads the
// active patient via PatientLookupService (not a passed-in patientId),
// lists items in AppListCard rows, FAB to add, edit/delete per row.
//
// Add this to caregiver_dashboard.dart's Manage grid:
//   BigActionTile(
//     icon: Icons.shield_rounded,
//     label: 'Safe Zone',
//     color: AppColors.danger,
//     background: AppColors.dangerLight,
//     onTap: () => _openManagePage(const CaregiverSafeZonePage()),
//   ),

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/safe_zone_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';
import 'caregiver_set_safe_zone_page.dart';

class CaregiverSafeZonePage extends StatefulWidget {
  const CaregiverSafeZonePage({super.key});

  @override
  State<CaregiverSafeZonePage> createState() => _CaregiverSafeZonePageState();
}

class _CaregiverSafeZonePageState extends State<CaregiverSafeZonePage> {
  String? _patientId;
  List<SafeZoneModel> zones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patientId = await PatientLookupService.getCurrentPatientId();
    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      zones = patientId == null ? [] : PatientDataService.getSafeZones(patientId);
      _loading = false;
    });
  }

  Future<void> _addZone() async {
    if (_patientId == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaregiverSetSafeZonePage(patientId: _patientId!),
      ),
    );
    if (result != null) _load();
  }

  Future<void> _editZone(SafeZoneModel zone) async {
    if (_patientId == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaregiverSetSafeZonePage(
          patientId: _patientId!,
          existingZone: zone,
        ),
      ),
    );
    if (result != null) _load();
  }

  Future<void> _deleteZone(int index) async {
    if (_patientId == null) return;
    final zone = zones[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Safe Zone?'),
        content: Text('Are you sure you want to delete "${zone.name}"? '
            'The patient will no longer be alerted for this area.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await PatientDataService.deleteSafeZone(_patientId!, zone.id);
    if (mounted) setState(() => zones.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Safe Zones'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _patientId == null ? null : _addZone,
        backgroundColor: AppColors.danger,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Safe Zone'),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : zones.isEmpty
                ? Center(
                    child: Text(
                      'No safe zones set yet.\nTap "Add Safe Zone" to set one, like "Home".',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: zones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final z = zones[i];
                      return AppListCard(
                        child: Row(
                          children: [
                            const IconBadge(
                              icon: Icons.shield_rounded,
                              color: AppColors.danger,
                              background: AppColors.dangerLight,
                              size: 60,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(z.name, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Radius: ${z.radiusMeters.round()} m',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                              onPressed: () => _editZone(z),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                              onPressed: () => _deleteZone(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}