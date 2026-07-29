// Place this file at: lib/screens/caregiver/caregiver_add_memory_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - Photo picker placeholder -> real file picker (device storage /
//    gallery), file is copied into app storage and kept.
//  - Record/Stop -> real microphone recording via the `record` package,
//    saved as a local audio file.
//  - Save Memory -> builds a MemoryModel with the resolved patientId and
//    writes it to Hive via PatientDataService, instead of just popping
//    `true` with no data.
//
// NEW DEPENDENCIES (add to pubspec.yaml): file_picker, record, path_provider
// PLATFORM SETUP NEEDED (not included — I don't have these files):
//  - Android: RECORD_AUDIO permission in AndroidManifest.xml
//  - iOS: NSMicrophoneUsageDescription in Info.plist

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/memory_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';

class CaregiverAddMemoryPage extends StatefulWidget {
  const CaregiverAddMemoryPage({super.key});

  @override
  State<CaregiverAddMemoryPage> createState() => _CaregiverAddMemoryPageState();
}

class _CaregiverAddMemoryPageState extends State<CaregiverAddMemoryPage> {
  String? photoPath;
  bool get photoAdded => photoPath != null;

  final _recorder = AudioRecorder();
  bool isRecording = false;
  String? recordingPath;
  bool get recordingSaved => recordingPath != null;

  bool _isSaving = false;

  final nameController = TextEditingController();
  final relationController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    relationController.dispose();
    descriptionController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    final saved = await PatientDataService.persistFile(path, 'memory_photo');
    setState(() => photoPath = saved);
  }

  Future<void> _toggleRecording() async {
    if (isRecording) {
      final path = await _recorder.stop();
      setState(() {
        isRecording = false;
        if (path != null) recordingPath = path;
      });
      return;
    }

    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to record.')),
        );
      }
      return;
    }

    final docsPath = await PatientDataService.appDocumentsPath();
    final destPath =
        '$docsPath/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: destPath);
    setState(() => isRecording = true);
  }

  Future<void> _saveMemory() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a name.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final patientId = await PatientLookupService.getCurrentPatientId();
      if (patientId == null) {
        throw Exception('No patient found for this caregiver yet.');
      }

      final memory = MemoryModel(
        id: PatientDataService.newId(),
        patientId: patientId,
        name: nameController.text.trim(),
        relation: relationController.text.trim(),
        photoPath: photoPath,
        description: descriptionController.text.trim(),
        voiceNotePath: recordingPath,
        createdAt: DateTime.now(),
      );

      await PatientDataService.addMemory(memory);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save memory: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Add Memory'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo picker
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        photoAdded ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        photoAdded ? 'Photo added' : 'Tap to add a photo',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              Text('Name', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'e.g. Sarah'),
              ),
              const SizedBox(height: 18),

              Text('Relation / Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(hintText: 'e.g. Daughter, Favorite place'),
              ),
              const SizedBox(height: 18),

              Text('Description', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write a short, simple description the patient will hear/read...',
                ),
              ),
              const SizedBox(height: 22),

              Text('Voice Description', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Record your voice describing this photo — the patient will hear it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              AppListCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isRecording ? AppColors.dangerLight : AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: isRecording ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        isRecording
                            ? 'Recording…'
                            : recordingSaved
                                ? 'Recording saved'
                                : 'No recording yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleRecording,
                      child: Text(isRecording ? 'Stop' : 'Record',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              BigPrimaryButton(
                label: _isSaving ? 'Saving…' : 'Save Memory',
                icon: Icons.check_rounded,
                color: AppColors.primary,
                onTap: _isSaving ? () {} : _saveMemory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
