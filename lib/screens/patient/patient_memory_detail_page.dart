// Place this file at: lib/screens/patient/patient_memory_detail_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - Now takes a real MemoryModel instead of loose name/relation/icon
//    params.
//  - Large photo placeholder -> shows the actual caregiver-added photo
//    (Image.file) when one exists, falling back to the same icon
//    placeholder style when it doesn't.
//  - "About" text -> the caregiver's real description instead of a
//    hardcoded sentence.
//  - "Play Description" -> actually plays the caregiver's recorded voice
//    note (via audioplayers) when one exists; shows a clear "no
//    recording" state instead when it doesn't, rather than pretending to
//    play one.
//
// NEW DEPENDENCY (add to pubspec.yaml): audioplayers

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/memory_model.dart';

/// Patient-facing detail view for a single memory: big photo, simple
/// description text, and a big "Play Description" button that plays the
/// caregiver-recorded voice note.
class PatientMemoryDetailPage extends StatefulWidget {
  final MemoryModel memory;
  final Color color;
  final Color background;

  const PatientMemoryDetailPage({
    super.key,
    required this.memory,
    required this.color,
    required this.background,
  });

  @override
  State<PatientMemoryDetailPage> createState() => _PatientMemoryDetailPageState();
}

class _PatientMemoryDetailPageState extends State<PatientMemoryDetailPage> {
  final _player = AudioPlayer();
  bool isPlaying = false;

  bool get _hasVoiceNote => widget.memory.voiceNotePath != null;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (!_hasVoiceNote) return;

    if (isPlaying) {
      await _player.pause();
      setState(() => isPlaying = false);
      return;
    }

    await _player.play(DeviceFileSource(widget.memory.voiceNotePath!));
    setState(() => isPlaying = true);
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;

    return Scaffold(
      appBar: SimpleTopBar(title: memory.name),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo — real image if the caregiver added one, else the
              // same icon-placeholder look as before.
              Container(
                height: 280,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: widget.background,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: memory.photoPath != null
                    ? Image.file(File(memory.photoPath!), fit: BoxFit.cover)
                    : Icon(Icons.image_rounded, size: 110, color: widget.color),
              ),
              const SizedBox(height: 22),
              Text(memory.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(memory.relation, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),

              AppListCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      memory.description.isNotEmpty
                          ? memory.description
                          : 'No description added yet.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              BigPrimaryButton(
                label: !_hasVoiceNote
                    ? 'No Voice Recording'
                    : (isPlaying ? 'Playing…' : 'Play Description'),
                icon: !_hasVoiceNote
                    ? Icons.mic_off_rounded
                    : (isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded),
                color: widget.color,
                onTap: _hasVoiceNote ? _togglePlayback : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
