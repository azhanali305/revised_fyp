// Place this file at: lib/screens/caregiver/caregiver_add_memory_page.dart
//
// UI/layout is untouched except for one small addition: tapping the photo
// box now opens a "Take Photo / Choose from Gallery" bottom sheet instead
// of going straight to the file picker, since there are now two ways to
// get a photo in. Logic changes:
//  - Photo picker placeholder -> real file picker (gallery) OR real
//    camera capture (front camera by default, with the OS camera UI's own
//    flip-camera control to switch to the rear camera), file is copied
//    into app storage and kept either way.
//  - Record/Stop -> real microphone recording via the `record` package,
//    saved as a local audio file.
//  - Save Memory -> builds a MemoryModel with the resolved patientId and
//    writes it to Hive via PatientDataService, instead of just popping
//    `true` with no data.
//
// NEW DEPENDENCIES (add to pubspec.yaml): file_picker, image_picker, record, path_provider
// PLATFORM SETUP NEEDED (not included — I don't have these files):
//  - Android: RECORD_AUDIO and CAMERA permissions in AndroidManifest.xml
//  - iOS: NSMicrophoneUsageDescription and NSCameraUsageDescription in Info.plist

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/memory_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';
import '../../services/face_recognition_service.dart';
import 'dart:io';

class CaregiverAddMemoryPage extends StatefulWidget {
  const CaregiverAddMemoryPage({super.key});

  @override
  State<CaregiverAddMemoryPage> createState() => _CaregiverAddMemoryPageState();
}

class _CaregiverAddMemoryPageState extends State<CaregiverAddMemoryPage> {
  String? photoPath;
  bool get photoAdded => photoPath != null;

  // Face embedding derived from `photoPath`, generated as soon as the
  // photo is picked (not at save time) so a "no face found" problem is
  // caught while the caregiver can still retake/reselect the photo.
  List<double>? _faceEmbedding;
  bool _isProcessingPhoto = false;
  bool _photoHasNoDetectableFace = false;

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

  final _imagePicker = ImagePicker();

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      // Opens front-facing by default; the OS camera UI still provides
      // its own flip-camera control to switch to the rear camera.
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return;
    await _handlePickedPhoto(picked.path);
  }

  Future<void> _pickFromGallery() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;
    await _handlePickedPhoto(path);
  }

  Future<void> _handlePickedPhoto(String rawPath) async {
    final saved = await PatientDataService.persistFile(rawPath, 'memory_photo');
    setState(() {
      photoPath = saved;
      _faceEmbedding = null;
      _photoHasNoDetectableFace = false;
      _isProcessingPhoto = true;
    });

    // "Who Is This?" matching depends on this embedding, but a missing
    // face shouldn't block saving the memory itself — the caregiver may
    // still want the photo/description/voice note even if face-scan
    // recognition won't work for this particular person.
    try {
      if (!FaceRecognitionService.isReady) {
        await FaceRecognitionService.init();
      }
      final embedding =
          await FaceRecognitionService.generateEmbeddingFromFile(File(saved));
      if (!mounted) return;
      setState(() {
        _faceEmbedding = embedding;
        _photoHasNoDetectableFace = embedding == null;
        _isProcessingPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoHasNoDetectableFace = true;
        _isProcessingPhoto = false;
      });
    }
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
        faceEmbedding: _faceEmbedding,
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
                onTap: _showPhotoSourceSheet,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                    ),
                    child: photoAdded
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(photoPath!), fit: BoxFit.cover),
                              if (_isProcessingPhoto)
                                Container(
                                  color: Colors.black.withOpacity(0.4),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Checking photo…',
                                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(AppRadius.chip),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, size: 48, color: AppColors.primary),
                              SizedBox(height: 10),
                              Text(
                                'Tap to add a photo',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              if (photoAdded && !_isProcessingPhoto && _photoHasNoDetectableFace) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "No face was detected in this photo, so \"Who Is This?\" won't be able to "
                        "recognize this person by face. The memory can still be saved.",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
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
                onTap: _isSaving || _isProcessingPhoto ? () {} : _saveMemory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}