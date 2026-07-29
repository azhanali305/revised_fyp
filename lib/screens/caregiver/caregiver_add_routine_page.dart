// Place this file at: lib/screens/caregiver/caregiver_add_routine_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - Save Task -> builds a RoutineTaskModel with the resolved patientId
//    and writes it to Hive via PatientDataService, instead of just
//    popping `true` with no data.
//  - If notifyEnabled is on, schedules the reminder popup right after
//    saving via RoutineNotificationService.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/routine_task_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';
import '../../services/routine_notification_service.dart';

class CaregiverAddRoutinePage extends StatefulWidget {
  const CaregiverAddRoutinePage({super.key});

  @override
  State<CaregiverAddRoutinePage> createState() => _CaregiverAddRoutinePageState();
}

class _CaregiverAddRoutinePageState extends State<CaregiverAddRoutinePage> {
  final categories = const [
    ('Medication', Icons.medication_rounded, AppColors.danger, AppColors.dangerLight),
    ('Meal', Icons.restaurant_rounded, AppColors.accent, AppColors.accentLight),
    ('Hygiene', Icons.clean_hands_rounded, AppColors.primary, AppColors.primaryLight),
    ('Exercise', Icons.directions_walk_rounded, AppColors.success, AppColors.successLight),
    ('Appointment', Icons.event_rounded, AppColors.caregiver, AppColors.caregiverLight),
    ('Other', Icons.task_alt_rounded, AppColors.textSecondary, AppColors.divider),
  ];
  String selectedCategory = 'Medication';
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool repeatDaily = true;
  bool notifyEnabled = true;
  bool _isSaving = false;
  final titleController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _saveTask() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a task name.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final patientId = await PatientLookupService.getCurrentPatientId();
      if (patientId == null) {
        throw Exception('No patient found for this caregiver yet.');
      }

      final task = RoutineTaskModel(
        id: PatientDataService.newId(),
        patientId: patientId,
        title: titleController.text.trim(),
        category: selectedCategory,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
        repeatDaily: repeatDaily,
        notifyEnabled: notifyEnabled,
        createdAt: DateTime.now(),
      );

      await PatientDataService.addRoutineTask(task);
      await RoutineNotificationService.schedule(task);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save task: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Add Routine Task'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Task', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'e.g. Morning Medicine'),
              ),
              const SizedBox(height: 22),

              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((c) {
                  final selected = selectedCategory == c.$1;
                  return ChoiceChip(
                    label: Text(c.$1),
                    avatar: Icon(c.$2, size: 18, color: selected ? Colors.white : c.$3),
                    selected: selected,
                    onSelected: (_) => setState(() => selectedCategory = c.$1),
                    selectedColor: c.$3,
                    backgroundColor: c.$4,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : c.$3,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      side: BorderSide.none,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              Text('Time', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              AppListCard(
                onTap: _pickTime,
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.access_time_rounded, color: AppColors.primary, background: AppColors.primaryLight),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(selectedTime.format(context), style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const Text('Change', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              AppListCard(
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.repeat_rounded, color: AppColors.caregiver, background: AppColors.caregiverLight),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Repeat Daily', style: Theme.of(context).textTheme.titleMedium),
                          Text('Task repeats every day at this time', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Switch(
                      value: repeatDaily,
                      activeTrackColor: AppColors.caregiver,
                      onChanged: (v) => setState(() => repeatDaily = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              AppListCard(
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.notifications_active_rounded, color: AppColors.success, background: AppColors.successLight),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Send Notification', style: Theme.of(context).textTheme.titleMedium),
                          Text('Patient gets a reminder alert', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Switch(
                      value: notifyEnabled,
                      activeTrackColor: AppColors.success,
                      onChanged: (v) => setState(() => notifyEnabled = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              BigPrimaryButton(
                label: _isSaving ? 'Saving…' : 'Save Task',
                icon: Icons.check_rounded,
                color: AppColors.accent,
                onTap: _isSaving ? () {} : _saveTask,
              ),
            ],
          ),
        ),
      ),
    );
  }
}