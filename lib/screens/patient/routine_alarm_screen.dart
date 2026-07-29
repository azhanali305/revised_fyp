// Place this file at: lib/screens/patient/routine_alarm_screen.dart
//
// Shown when a routine task's scheduled time arrives. On Android this
// opens automatically (full-screen intent) even if the app was closed.
// On iOS it opens after the patient/caregiver taps the notification.

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/routine_task_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/routine_notification_service.dart';

const _categoryStyles = {
  'Medication': (Icons.medication_rounded, AppColors.danger, AppColors.dangerLight),
  'Meal': (Icons.restaurant_rounded, AppColors.accent, AppColors.accentLight),
  'Hygiene': (Icons.clean_hands_rounded, AppColors.primary, AppColors.primaryLight),
  'Exercise': (Icons.directions_walk_rounded, AppColors.success, AppColors.successLight),
  'Appointment': (Icons.event_rounded, AppColors.caregiver, AppColors.caregiverLight),
  'Other': (Icons.task_alt_rounded, AppColors.textSecondary, AppColors.divider),
};

class RoutineAlarmScreen extends StatelessWidget {
  final RoutineTaskModel task;
  const RoutineAlarmScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyles[task.category] ??
        (Icons.task_alt_rounded, AppColors.textSecondary, AppColors.divider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: style.$3,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.$1, size: 56, color: style.$2),
                ),
                const SizedBox(height: 28),
                Text(
                  task.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${task.category} · ${task.formattedTime}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: style.$2),
                        ),
                        onPressed: () async {
                          await RoutineNotificationService.snooze(
                            task,
                            const Duration(minutes: 5),
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Text('Snooze 5 min',
                            style: TextStyle(color: style.$2)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: style.$2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          await PatientDataService.setRoutineTaskDone(
                              task.patientId, task.id, true);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Done',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}