import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import 'caregiver_memory_page.dart';
import 'caregiver_calming_page.dart';
import 'caregiver_routine_page.dart';

class CaregiverDashboard extends StatelessWidget {
  const CaregiverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.caregiverLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded,
                        color: AppColors.caregiver, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, Sarah', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Caring for Robert', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick stats
              Row(
                children: const [
                  Expanded(child: _StatCard(label: 'Memories', value: '5', icon: Icons.photo_album_rounded, color: AppColors.primary, background: AppColors.primaryLight)),
                  SizedBox(width: 14),
                  Expanded(child: _StatCard(label: "Today's Tasks", value: '7', icon: Icons.checklist_rounded, color: AppColors.accent, background: AppColors.accentLight)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(child: _StatCard(label: 'Calming Items', value: '4', icon: Icons.self_improvement_rounded, color: AppColors.success, background: AppColors.successLight)),
                  SizedBox(width: 14),
                  Expanded(child: _StatCard(label: 'Completed Today', value: '2/7', icon: Icons.emoji_events_rounded, color: AppColors.caregiver, background: AppColors.caregiverLight)),
                ],
              ),

              const SizedBox(height: 28),
              Text('Manage', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: [
                  BigActionTile(
                    icon: Icons.photo_album_rounded,
                    label: 'Memory Page',
                    color: AppColors.primary,
                    background: AppColors.primaryLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CaregiverMemoryPage())),
                  ),
                  BigActionTile(
                    icon: Icons.self_improvement_rounded,
                    label: 'Calming Page',
                    color: AppColors.success,
                    background: AppColors.successLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CaregiverCalmingPage())),
                  ),
                  BigActionTile(
                    icon: Icons.checklist_rounded,
                    label: 'Routine Page',
                    color: AppColors.accent,
                    background: AppColors.accentLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CaregiverRoutinePage())),
                  ),
                  BigActionTile(
                    icon: Icons.person_rounded,
                    label: 'Patient Profile',
                    color: AppColors.caregiver,
                    background: AppColors.caregiverLight,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, background: background, size: 44),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
