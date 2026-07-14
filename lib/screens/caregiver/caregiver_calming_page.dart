import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import 'caregiver_add_calming_page.dart';

class _CalmItem {
  final String title;
  final String type;
  final IconData icon;
  final Color color;
  final Color background;
  _CalmItem(this.title, this.type, this.icon, this.color, this.background);
}

class CaregiverCalmingPage extends StatefulWidget {
  const CaregiverCalmingPage({super.key});

  @override
  State<CaregiverCalmingPage> createState() => _CaregiverCalmingPageState();
}

class _CaregiverCalmingPageState extends State<CaregiverCalmingPage> {
  final List<_CalmItem> items = [
    _CalmItem('Deep Breathing', 'Breathing Exercise', Icons.air_rounded, AppColors.success, AppColors.successLight),
    _CalmItem('Ocean Waves', 'Sound', Icons.waves_rounded, AppColors.primary, AppColors.primaryLight),
    _CalmItem('Piano Melody', 'Music', Icons.music_note_rounded, AppColors.caregiver, AppColors.caregiverLight),
    _CalmItem('Rainfall', 'Sound', Icons.grain_rounded, AppColors.accent, AppColors.accentLight),
  ];

  Future<void> _addItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverAddCalmingPage()),
    );
    if (result == true) {
      setState(() {
        items.add(_CalmItem('New Item', 'Sound', Icons.graphic_eq_rounded, AppColors.primary, AppColors.primaryLight));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Calming Page'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final item = items[i];
            return AppListCard(
              child: Row(
                children: [
                  IconBadge(icon: item.icon, color: item.color, background: item.background),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.background,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(item.type,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item.color)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    onPressed: () => setState(() => items.removeAt(i)),
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
