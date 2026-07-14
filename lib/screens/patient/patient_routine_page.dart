import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';

class _Task {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  final Color background;
  bool done;
  _Task(this.title, this.time, this.icon, this.color, this.background, {this.done = false});
}

class PatientRoutinePage extends StatefulWidget {
  const PatientRoutinePage({super.key});

  @override
  State<PatientRoutinePage> createState() => _PatientRoutinePageState();
}

class _PatientRoutinePageState extends State<PatientRoutinePage> {
  final List<_Task> tasks = [
    _Task('Breakfast', '8:00 AM', Icons.restaurant_rounded, AppColors.accent, AppColors.accentLight, done: true),
    _Task('Morning Medicine', '9:00 AM', Icons.medication_rounded, AppColors.danger, AppColors.dangerLight, done: true),
    _Task('Walk in the Garden', '11:30 AM', Icons.directions_walk_rounded, AppColors.success, AppColors.successLight),
    _Task('Lunch', '1:00 PM', Icons.restaurant_rounded, AppColors.accent, AppColors.accentLight),
    _Task('Afternoon Medicine', '2:30 PM', Icons.medication_rounded, AppColors.danger, AppColors.dangerLight),
    _Task('Video Call with Sarah', '4:00 PM', Icons.videocam_rounded, AppColors.caregiver, AppColors.caregiverLight),
    _Task('Brush Teeth', '9:00 PM', Icons.clean_hands_rounded, AppColors.primary, AppColors.primaryLight),
  ];

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
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final t = tasks[i];
                  return AppListCard(
                    onTap: () => setState(() => t.done = !t.done),
                    child: Row(
                      children: [
                        IconBadge(icon: t.icon, color: t.color, background: t.background),
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
                              Text(t.time, style: Theme.of(context).textTheme.bodyMedium),
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
