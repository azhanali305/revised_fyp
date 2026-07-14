import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';

class CaregiverAddCalmingPage extends StatefulWidget {
  const CaregiverAddCalmingPage({super.key});

  @override
  State<CaregiverAddCalmingPage> createState() => _CaregiverAddCalmingPageState();
}

class _CaregiverAddCalmingPageState extends State<CaregiverAddCalmingPage> {
  final types = const [
    ('Music', Icons.music_note_rounded),
    ('Sound', Icons.waves_rounded),
    ('Breathing Exercise', Icons.air_rounded),
  ];
  String selectedType = 'Music';
  bool fileAdded = false;
  final titleController = TextEditingController();
  final durationController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Add Calming Item'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: types.map((t) {
                  final selected = selectedType == t.$1;
                  return ChoiceChip(
                    label: Text(t.$1),
                    avatar: Icon(t.$2, size: 18, color: selected ? Colors.white : AppColors.primary),
                    selected: selected,
                    onSelected: (_) => setState(() => selectedType = t.$1),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.primary,
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

              Text('Title', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: selectedType == 'Breathing Exercise'
                      ? 'e.g. Deep Breathing'
                      : 'e.g. Ocean Waves',
                ),
              ),
              const SizedBox(height: 18),

              if (selectedType != 'Breathing Exercise') ...[
                Text('Upload File', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => fileAdded = !fileAdded),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          fileAdded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                          color: AppColors.success,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fileAdded ? 'Audio file added' : 'Tap to upload audio file',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ] else ...[
                Text('Breathing Pattern', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                AppListCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _BreathRow(label: 'Breathe In', seconds: '4 sec'),
                      SizedBox(height: 10),
                      _BreathRow(label: 'Hold', seconds: '4 sec'),
                      SizedBox(height: 10),
                      _BreathRow(label: 'Breathe Out', seconds: '4 sec'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              Text('Duration (minutes)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 3'),
              ),

              const SizedBox(height: 30),
              BigPrimaryButton(
                label: 'Save Item',
                icon: Icons.check_rounded,
                color: AppColors.success,
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathRow extends StatelessWidget {
  final String label;
  final String seconds;
  const _BreathRow({required this.label, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(seconds, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
      ],
    );
  }
}
