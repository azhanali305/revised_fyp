import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';

/// Pure UI form for adding a memory: photo, description text, and a
/// "record sound describing the image" control. No real image picker or
/// audio recording wired up — placeholders only.
class CaregiverAddMemoryPage extends StatefulWidget {
  const CaregiverAddMemoryPage({super.key});

  @override
  State<CaregiverAddMemoryPage> createState() => _CaregiverAddMemoryPageState();
}

class _CaregiverAddMemoryPageState extends State<CaregiverAddMemoryPage> {
  bool photoAdded = false;
  bool isRecording = false;
  bool recordingSaved = false;
  final nameController = TextEditingController();
  final relationController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    relationController.dispose();
    descriptionController.dispose();
    super.dispose();
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
              // Photo picker placeholder
              GestureDetector(
                onTap: () => setState(() => photoAdded = !photoAdded),
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
                                ? 'Recording saved (0:12)'
                                : 'No recording yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (isRecording) {
                            isRecording = false;
                            recordingSaved = true;
                          } else {
                            isRecording = true;
                            recordingSaved = false;
                          }
                        });
                      },
                      child: Text(isRecording ? 'Stop' : 'Record',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              BigPrimaryButton(
                label: 'Save Memory',
                icon: Icons.check_rounded,
                color: AppColors.primary,
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
