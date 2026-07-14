import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import 'patient_memory_detail_page.dart';

class _Memory {
  final String name;
  final String relation;
  final IconData icon;
  final Color color;
  final Color background;
  const _Memory(this.name, this.relation, this.icon, this.color, this.background);
}

const _dummyMemories = [
  _Memory('Sarah', 'Your daughter', Icons.face_rounded, AppColors.accent, AppColors.accentLight),
  _Memory('David', 'Your son', Icons.face_rounded, AppColors.primary, AppColors.primaryLight),
  _Memory('Home Garden', 'A place you love', Icons.local_florist_rounded, AppColors.success, AppColors.successLight),
  _Memory('Wedding Day', 'A happy memory', Icons.favorite_rounded, AppColors.danger, AppColors.dangerLight),
  _Memory('Max', 'Your dog', Icons.pets_rounded, AppColors.caregiver, AppColors.caregiverLight),
];

/// Patient-facing: browse memories (read-only, large tappable cards).
class PatientMemoryPage extends StatelessWidget {
  const PatientMemoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'My Memories'),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: _dummyMemories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final m = _dummyMemories[i];
            return AppListCard(
              padding: const EdgeInsets.all(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientMemoryDetailPage(
                    name: m.name,
                    relation: m.relation,
                    icon: m.icon,
                    color: m.color,
                    background: m.background,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconBadge(icon: m.icon, color: m.color, background: m.background, size: 64),
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
