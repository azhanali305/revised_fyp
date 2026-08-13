// Place this file at: lib/screens/caregiver/caregiver_memory_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - The hardcoded `memories` list is replaced with real ones loaded from
//    Hive (via PatientDataService) for the caregiver's patient.
//  - Delete now removes the item from Hive, not just from memory.
//  - Since real memories don't carry a caregiver-picked icon/color, list
//    rows cycle through the same palette your dummy data used, purely for
//    visual variety — nothing is persisted for it.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/memory_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';
import 'caregiver_add_memory_page.dart';

const _palette = [
  (AppColors.accent, AppColors.accentLight),
  (AppColors.primary, AppColors.primaryLight),
  (AppColors.success, AppColors.successLight),
  (AppColors.danger, AppColors.dangerLight),
  (AppColors.caregiver, AppColors.caregiverLight),
];

class CaregiverMemoryPage extends StatefulWidget {
  const CaregiverMemoryPage({super.key});

  @override
  State<CaregiverMemoryPage> createState() => _CaregiverMemoryPageState();
}

class _CaregiverMemoryPageState extends State<CaregiverMemoryPage> {
  String? _patientId;
  List<MemoryModel> memories = [];
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
      memories = patientId == null ? [] : PatientDataService.getMemories(patientId);
      _loading = false;
    });
  }

  Future<void> _addMemory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverAddMemoryPage()),
    );
    if (result == true) _load();
  }

  Future<void> _deleteMemory(int index) async {
    if (_patientId == null) return;
    final memory = memories[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Memory?'),
        content: Text('Are you sure you want to delete "${memory.name}"? '
            'This cannot be undone.'),
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

    await PatientDataService.deleteMemory(_patientId!, memory.id);
    if (mounted) setState(() => memories.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Memory Page'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMemory,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Memory'),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : memories.isEmpty
                ? Center(
                    child: Text(
                      'No memories added yet.\nTap "Add Memory" to get started.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: memories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final m = memories[i];
                      final colors = _palette[i % _palette.length];
                      return AppListCard(
                        child: Row(
                          children: [
                            IconBadge(
                              icon: Icons.image_rounded,
                              color: colors.$1,
                              background: colors.$2,
                              size: 60,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(m.relation, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        m.voiceNotePath != null
                                            ? Icons.mic_rounded
                                            : Icons.mic_off_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        m.voiceNotePath != null
                                            ? 'Voice note added'
                                            : 'No voice note',
                                        style: const TextStyle(
                                            fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                              onPressed: () => _deleteMemory(i),
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