// Place this file at: lib/screens/caregiver/caregiver_add_calming_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - Upload File placeholder -> real file picker (audio from device
//    storage), file copied into app storage.
//  - Save Item -> builds a CalmingItemModel with the resolved patientId
//    and writes it to Hive via PatientDataService.
//
// NEW DEPENDENCY (add to pubspec.yaml): file_picker

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/calming_item_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';

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
  String? filePath;
  bool get fileAdded => filePath != null;
  bool _isSaving = false;
  final titleController = TextEditingController();
  final durationController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = result?.files.single.path;
    if (path == null) return;

    final saved = await PatientDataService.persistFile(path, 'calming_audio');
    setState(() => filePath = saved);
  }

  Future<void> _saveItem() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a title.')));
      return;
    }
    if (selectedType != 'Breathing Exercise' && filePath == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload an audio file.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final patientId = await PatientLookupService.getCurrentPatientId();
      if (patientId == null) {
        throw Exception('No patient found for this caregiver yet.');
      }

      final item = CalmingItemModel(
        id: PatientDataService.newId(),
        patientId: patientId,
        title: titleController.text.trim(),
        type: selectedType,
        audioPath: filePath,
        isAsset: false,
        durationMinutes: int.tryParse(durationController.text.trim()) ?? 3,
        createdAt: DateTime.now(),
      );

      await PatientDataService.addCalmingItem(item);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                  onTap: _pickFile,
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
                label: _isSaving ? 'Saving…' : 'Save Item',
                icon: Icons.check_rounded,
                color: AppColors.success,
                onTap: _isSaving ? () {} : _saveItem,
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
