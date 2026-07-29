// Place this file at: lib/screens/patient/patient_routine_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - The hardcoded `tasks` list is replaced with real routine tasks
//    loaded from Hive (via PatientDataService) for this device's local
//    patientId — the same ones the caregiver set up.
//  - Tapping a task to toggle done/undone now persists back to Hive, so
//    the caregiver's "Completed Today" dashboard stat reflects it too.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/routine_task_model.dart';
import '../../services/patient_data_service.dart';

const _categoryStyles = {
  'Medication': (Icons.medication_rounded, AppColors.danger, AppColors.dangerLight),
  'Meal': (Icons.restaurant_rounded, AppColors.accent, AppColors.accentLight),
  'Hygiene': (Icons.clean_hands_rounded, AppColors.primary, AppColors.primaryLight),
  'Exercise': (Icons.directions_walk_rounded, AppColors.success, AppColors.successLight),
  'Appointment': (Icons.event_rounded, AppColors.caregiver, AppColors.caregiverLight),
  'Other': (Icons.task_alt_rounded, AppColors.textSecondary, AppColors.divider),
};

class PatientRoutinePage extends StatefulWidget {
  const PatientRoutinePage({super.key});

  @override
  State<PatientRoutinePage> createState() => _PatientRoutinePageState();
}

class _PatientRoutinePageState extends State<PatientRoutinePage> {
  String? _patientId;
  List<RoutineTaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    _patientId = PatientDataService.getActivePatientId();
    tasks = _patientId == null ? [] : PatientDataService.getRoutineTasks(_patientId!);
  }

  Future<void> _toggleDone(int index) async {
    if (_patientId == null) return;
    final task = tasks[index];
    final newDone = !task.done;
    await PatientDataService.setRoutineTaskDone(_patientId!, task.id, newDone);
    setState(() => tasks[index] = task.copyWith(done: newDone));
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = tasks.where((t) => t.done).length;
    return Scaffold(
      appBar: const SimpleTopBar(title: 'My Routine'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: AppColors.success, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'You completed $doneCount of ${tasks.length} tasks today!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No routine tasks set up yet.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final t = tasks[i];
                        final style = _categoryStyles[t.category] ??
                            (Icons.task_alt_rounded, AppColors.textSecondary, AppColors.divider);
                        return AppListCard(
                          onTap: () => _toggleDone(i),
                          child: Row(
                            children: [
                              IconBadge(icon: style.$1, color: style.$2, background: style.$3),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            decoration: t.done ? TextDecoration.lineThrough : null,
                                            color: t.done ? AppColors.textSecondary : AppColors.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(t.formattedTime, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: t.done ? AppColors.success : AppColors.background,
                                  border: Border.all(
                                    color: t.done ? AppColors.success : AppColors.divider,
                                    width: 2,
                                  ),
                                ),
                                child: t.done
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                    : null,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}