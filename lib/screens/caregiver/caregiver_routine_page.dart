import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import 'caregiver_add_routine_page.dart';

class _Task {
  final String title;
  final String time;
  final String category;
  final IconData icon;
  final Color color;
  final Color background;
  final bool notify;
  _Task(this.title, this.time, this.category, this.icon, this.color, this.background, {this.notify = true});
}

class CaregiverRoutinePage extends StatefulWidget {
  const CaregiverRoutinePage({super.key});

  @override
  State<CaregiverRoutinePage> createState() => _CaregiverRoutinePageState();
}

class _CaregiverRoutinePageState extends State<CaregiverRoutinePage> {
  final List<_Task> tasks = [
    _Task('Breakfast', '8:00 AM', 'Meal', Icons.restaurant_rounded, AppColors.accent, AppColors.accentLight),
    _Task('Morning Medicine', '9:00 AM', 'Medication', Icons.medication_rounded, AppColors.danger, AppColors.dangerLight),
    _Task('Walk in the Garden', '11:30 AM', 'Exercise', Icons.directions_walk_rounded, AppColors.success, AppColors.successLight),
    _Task('Lunch', '1:00 PM', 'Meal', Icons.restaurant_rounded, AppColors.accent, AppColors.accentLight),
    _Task('Afternoon Medicine', '2:30 PM', 'Medication', Icons.medication_rounded, AppColors.danger, AppColors.dangerLight),
    _Task('Video Call with Sarah', '4:00 PM', 'Appointment', Icons.videocam_rounded, AppColors.caregiver, AppColors.caregiverLight),
    _Task('Brush Teeth', '9:00 PM', 'Hygiene', Icons.clean_hands_rounded, AppColors.primary, AppColors.primaryLight, notify: false),
  ];

  Future<void> _addTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverAddRoutinePage()),
    );
    if (result == true) {
      setState(() {
        tasks.add(_Task('New Task', '12:00 PM', 'Other', Icons.task_alt_rounded, AppColors.primary, AppColors.primaryLight));
      });
    }
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
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final t = tasks[i];
            return AppListCard(
              child: Row(
                children: [
                  IconBadge(icon: t.icon, color: t.color, background: t.background),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('${t.time} · ${t.category}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              t.notify ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                              size: 16,
                              color: t.notify ? AppColors.success : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.notify ? 'Notification on' : 'Notification off',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    onPressed: () => setState(() => tasks.removeAt(i)),
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
