import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';

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
                label: 'Save Task',
                icon: Icons.check_rounded,
                color: AppColors.accent,
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
