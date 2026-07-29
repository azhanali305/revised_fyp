// Place this file at: lib/screens/caregiver/caregiver_routine_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - The hardcoded `tasks` list is replaced with real ones loaded from
//    Hive (via PatientDataService) for the caregiver's patient.
//  - Delete removes the task from Hive, not just from memory, and cancels
//    its pending notification via RoutineNotificationService.
//  - Category -> icon/color mapping now comes from a shared lookup table
//    (matching the categories defined in CaregiverAddRoutinePage) instead
//    of being baked into hardcoded dummy tasks.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/routine_task_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';
import '../../services/routine_notification_service.dart';
import 'caregiver_add_routine_page.dart';

const _categoryStyles = {
  'Medication': (Icons.medication_rounded, AppColors.danger, AppColors.dangerLight),
  'Meal': (Icons.restaurant_rounded, AppColors.accent, AppColors.accentLight),
  'Hygiene': (Icons.clean_hands_rounded, AppColors.primary, AppColors.primaryLight),
  'Exercise': (Icons.directions_walk_rounded, AppColors.success, AppColors.successLight),
  'Appointment': (Icons.event_rounded, AppColors.caregiver, AppColors.caregiverLight),
  'Other': (Icons.task_alt_rounded, AppColors.textSecondary, AppColors.divider),
};

class CaregiverRoutinePage extends StatefulWidget {
  const CaregiverRoutinePage({super.key});

  @override
  State<CaregiverRoutinePage> createState() => _CaregiverRoutinePageState();
}

class _CaregiverRoutinePageState extends State<CaregiverRoutinePage> {
  String? _patientId;
  List<RoutineTaskModel> tasks = [];
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
      tasks = patientId == null ? [] : PatientDataService.getRoutineTasks(patientId);
      _loading = false;
    });
  }

  Future<void> _addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverAddRoutinePage()),
    );
    if (result == true) _load();
  }

  Future<void> _deleteTask(int index) async {
    if (_patientId == null) return;
    final task = tasks[index];
    await RoutineNotificationService.cancel(task);
    await PatientDataService.deleteRoutineTask(_patientId!, task.id);
    setState(() => tasks.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Routine Page'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final t = tasks[i];
                  final style = _categoryStyles[t.category] ??
                      (Icons.task_alt_rounded, AppColors.textSecondary, AppColors.divider);
                  return AppListCard(
                    child: Row(
                      children: [
                        IconBadge(icon: style.$1, color: style.$2, background: style.$3),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text('${t.formattedTime} · ${t.category}',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    t.notifyEnabled
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_off_rounded,
                                    size: 16,
                                    color: t.notifyEnabled ? AppColors.success : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t.notifyEnabled ? 'Notification on' : 'Notification off',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          onPressed: () => _deleteTask(i),
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