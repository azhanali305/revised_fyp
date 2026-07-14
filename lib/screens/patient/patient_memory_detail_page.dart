import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';

/// Patient-facing detail view for a single memory: big photo, simple
/// description text, and a big "Play Description" button (UI only —
/// pretends to play the caregiver-recorded audio).
class PatientMemoryDetailPage extends StatefulWidget {
  final String name;
  final String relation;
  final IconData icon;
  final Color color;
  final Color background;

  const PatientMemoryDetailPage({
    super.key,
    required this.name,
    required this.relation,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  State<PatientMemoryDetailPage> createState() => _PatientMemoryDetailPageState();
}

class _PatientMemoryDetailPageState extends State<PatientMemoryDetailPage> {
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleTopBar(title: widget.name),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large photo placeholder
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: widget.background,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(widget.icon, size: 110, color: widget.color),
              ),
              const SizedBox(height: 22),
              Text(widget.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(widget.relation, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),

              AppListCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'This is ${widget.name}, ${widget.relation.toLowerCase()}. '
                      'She visits you every Sunday and loves to hear about your day.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              BigPrimaryButton(
                label: isPlaying ? 'Playing…' : 'Play Description',
                icon: isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                color: widget.color,
                onTap: () => setState(() => isPlaying = !isPlaying),
              ),
              const SizedBox(height: 14),
              if (isPlaying)
                Center(
                  child: Text(
                    '🔊 "This is ${widget.name}, ${widget.relation.toLowerCase()}..."',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
