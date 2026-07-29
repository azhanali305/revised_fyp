// Place this file at: lib/screens/patient/patient_memory_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - The hardcoded `_dummyMemories` list is replaced with real memories
//    loaded from Hive (via PatientDataService), using this device's local
//    patientId — the same ones the caregiver added on their device.
//  - Passes the full memory (photo/description/voice note) into the
//    detail page instead of just name/relation/icon.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/memory_model.dart';
import '../../services/patient_data_service.dart';
import 'patient_memory_detail_page.dart';

const _palette = [
  (AppColors.accent, AppColors.accentLight),
  (AppColors.primary, AppColors.primaryLight),
  (AppColors.success, AppColors.successLight),
  (AppColors.danger, AppColors.dangerLight),
  (AppColors.caregiver, AppColors.caregiverLight),
];

/// Patient-facing: browse memories (read-only, large tappable cards).
class PatientMemoryPage extends StatefulWidget {
  const PatientMemoryPage({super.key});

  @override
  State<PatientMemoryPage> createState() => _PatientMemoryPageState();
}

class _PatientMemoryPageState extends State<PatientMemoryPage> {
  List<MemoryModel> memories = [];

  @override
  void initState() {
    super.initState();
    final patientId = PatientDataService.getActivePatientId();
    memories = patientId == null ? [] : PatientDataService.getMemories(patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'My Memories'),
      body: SafeArea(
        top: false,
        child: memories.isEmpty
            ? Center(
                child: Text(
                  'No memories added yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: memories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final m = memories[i];
                  final colors = _palette[i % _palette.length];
                  return AppListCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientMemoryDetailPage(
                          memory: m,
                          color: colors.$1,
                          background: colors.$2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconBadge(icon: Icons.image_rounded, color: colors.$1, background: colors.$2, size: 64),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(m.relation, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}