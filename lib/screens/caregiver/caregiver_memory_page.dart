import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import 'caregiver_add_memory_page.dart';

class _Memory {
  final String name;
  final String relation;
  final IconData icon;
  final Color color;
  final Color background;
  _Memory(this.name, this.relation, this.icon, this.color, this.background);
}

class CaregiverMemoryPage extends StatefulWidget {
  const CaregiverMemoryPage({super.key});

  @override
  State<CaregiverMemoryPage> createState() => _CaregiverMemoryPageState();
}

class _CaregiverMemoryPageState extends State<CaregiverMemoryPage> {
  final List<_Memory> memories = [
    _Memory('Sarah', 'Daughter', Icons.face_rounded, AppColors.accent, AppColors.accentLight),
    _Memory('David', 'Son', Icons.face_rounded, AppColors.primary, AppColors.primaryLight),
    _Memory('Home Garden', 'Favorite place', Icons.local_florist_rounded, AppColors.success, AppColors.successLight),
    _Memory('Wedding Day', 'Happy memory', Icons.favorite_rounded, AppColors.danger, AppColors.dangerLight),
    _Memory('Max', 'Family dog', Icons.pets_rounded, AppColors.caregiver, AppColors.caregiverLight),
  ];

  Future<void> _addMemory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverAddMemoryPage()),
    );
    if (result == true) {
      setState(() {
        memories.add(_Memory('New Memory', 'Description', Icons.image_rounded,
            AppColors.primary, AppColors.primaryLight));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Memory Page'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMemory,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Memory'),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: memories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final m = memories[i];
            return AppListCard(
              child: Row(
                children: [
                  IconBadge(icon: m.icon, color: m.color, background: m.background, size: 60),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(m.relation, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Row(
                          children: const [
                            Icon(Icons.mic_rounded, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text('Voice note added', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    onPressed: () => setState(() => memories.removeAt(i)),
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
