// Place this file at: lib/screens/caregiver/caregiver_calming_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - The hardcoded `items` list is replaced with real ones loaded from
//    Hive (via PatientDataService), which auto-seeds the 4 bundled
//    presets (Deep Breathing, Ocean Waves, Piano Melody, Rainfall) the
//    first time it's opened for a patient.
//  - Delete removes the item from Hive, not just from memory.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/calming_item_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';
import 'caregiver_add_calming_page.dart';

const _typeStyles = {
  'Music': (Icons.music_note_rounded, AppColors.caregiver, AppColors.caregiverLight),
  'Sound': (Icons.waves_rounded, AppColors.primary, AppColors.primaryLight),
  'Breathing Exercise': (Icons.air_rounded, AppColors.success, AppColors.successLight),
};

class CaregiverCalmingPage extends StatefulWidget {
  const CaregiverCalmingPage({super.key});

  @override
  State<CaregiverCalmingPage> createState() => _CaregiverCalmingPageState();
}

class _CaregiverCalmingPageState extends State<CaregiverCalmingPage> {
  String? _patientId;
  List<CalmingItemModel> items = [];
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
      items = patientId == null ? [] : PatientDataService.getCalmingItems(patientId);
      _loading = false;
    });
  }

  Future<void> _addItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverAddCalmingPage()),
    );
    if (result == true) _load();
  }

  Future<void> _deleteItem(int index) async {
    if (_patientId == null) return;
    final item = items[index];
    await PatientDataService.deleteCalmingItem(_patientId!, item.id);
    setState(() => items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Calming Page'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final style = _typeStyles[item.type] ??
                      (Icons.graphic_eq_rounded, AppColors.primary, AppColors.primaryLight);
                  return AppListCard(
                    child: Row(
                      children: [
                        IconBadge(icon: style.$1, color: style.$2, background: style.$3),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: style.$3,
                                  borderRadius: BorderRadius.circular(AppRadius.chip),
                                ),
                                child: Text(item.type,
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700, color: style.$2)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          onPressed: () => _deleteItem(i),
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
