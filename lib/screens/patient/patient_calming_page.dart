// Place this file at: lib/screens/patient/patient_calming_page.dart
//
// UI/layout is untouched. Logic changes only:
//  - The hardcoded `_items` list is replaced with real calming items
//    loaded from Hive (via PatientDataService) for this device's local
//    patientId — bundled presets plus anything the caregiver added.
//  - The "Fake progress bar" for Music/Sound sessions is now driven by
//    real playback position via audioplayers (assets for bundled presets,
//    local files for caregiver-uploaded ones). Deep Breathing keeps its
//    original animated-circle-only behavior (no audio).
//
// NEW DEPENDENCY (add to pubspec.yaml): audioplayers

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/calming_item_model.dart';
import '../../services/patient_data_service.dart';

const _typeStyles = {
  'Music': (Icons.music_note_rounded, AppColors.caregiver, AppColors.caregiverLight),
  'Sound': (Icons.waves_rounded, AppColors.primary, AppColors.primaryLight),
  'Breathing Exercise': (Icons.air_rounded, AppColors.success, AppColors.successLight),
};

class PatientCalmingPage extends StatefulWidget {
  const PatientCalmingPage({super.key});

  @override
  State<PatientCalmingPage> createState() => _PatientCalmingPageState();
}

class _PatientCalmingPageState extends State<PatientCalmingPage> {
  List<CalmingItemModel> items = [];

  @override
  void initState() {
    super.initState();
    final patientId = PatientDataService.getActivePatientId();
    items = patientId == null ? [] : PatientDataService.getCalmingItems(patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Calm Down'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              "Choose something to help you feel relaxed.",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            for (final item in items) ...[
              AppListCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalmingSessionPage(item: item),
                  ),
                ),
                child: Row(
                  children: [
                    IconBadge(
                      icon: (_typeStyles[item.type] ?? _typeStyles['Sound']!).$1,
                      color: (_typeStyles[item.type] ?? _typeStyles['Sound']!).$2,
                      background: (_typeStyles[item.type] ?? _typeStyles['Sound']!).$3,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            item.type == 'Breathing Exercise'
                                ? 'Guided breathing exercise · ${item.durationMinutes} min'
                                : '${item.type} · ${item.durationMinutes} min',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen calming "session" — a simple, non-distracting player UI.
/// For "Deep Breathing" it shows a breathing circle guide. For Music/Sound
/// it plays the item's real audio (bundled asset or caregiver-uploaded
/// file) and drives the progress bar off actual playback position.
class CalmingSessionPage extends StatefulWidget {
  final CalmingItemModel item;
  const CalmingSessionPage({super.key, required this.item});

  @override
  State<CalmingSessionPage> createState() => _CalmingSessionPageState();
}

class _CalmingSessionPageState extends State<CalmingSessionPage>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  late final AnimationController _controller;

  final _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool get isBreathing => widget.item.type == 'Breathing Exercise';
  IconData get _icon => (_typeStyles[widget.item.type] ?? _typeStyles['Sound']!).$1;
  Color get _color => (_typeStyles[widget.item.type] ?? _typeStyles['Sound']!).$2;
  Color get _background => (_typeStyles[widget.item.type] ?? _typeStyles['Sound']!).$3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    if (!isBreathing) {
      _player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => isPlaying = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (isBreathing) {
      setState(() => isPlaying = !isPlaying);
      return;
    }

    if (widget.item.audioPath == null) return;

    if (isPlaying) {
      await _player.pause();
    } else {
      final source = widget.item.isAsset
          ? AssetSource(widget.item.audioPath!.replaceFirst('assets/', ''))
          : DeviceFileSource(widget.item.audioPath!);
      await _player.play(source);
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : _position.inMilliseconds / _duration.inMilliseconds;

    return Scaffold(
      backgroundColor: _background,
      appBar: SimpleTopBar(title: item.title, color: _color),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              if (isBreathing)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final scale = isPlaying ? 0.8 + (_controller.value * 0.4) : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _color.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: _color.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                isPlaying ? (scale > 1.0 ? 'Breathe In' : 'Breathe Out') : 'Ready',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(color: _color.withOpacity(0.18), shape: BoxShape.circle),
                  child: Icon(_icon, size: 100, color: _color),
                ),
              const SizedBox(height: 30),
              Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('${item.type} · ${item.durationMinutes} min', style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: isBreathing ? (isPlaying ? 0.35 : 0) : progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  color: _color,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 88,
                height: 88,
                child: ElevatedButton(
                  onPressed: _toggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}