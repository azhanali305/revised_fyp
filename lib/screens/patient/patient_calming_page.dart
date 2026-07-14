import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';

class _CalmItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  const _CalmItem(this.title, this.subtitle, this.icon, this.color, this.background);
}

const _items = [
  _CalmItem('Deep Breathing', 'Guided breathing exercise · 3 min', Icons.air_rounded, AppColors.success, AppColors.successLight),
  _CalmItem('Ocean Waves', 'Calming sound', Icons.waves_rounded, AppColors.primary, AppColors.primaryLight),
  _CalmItem('Piano Melody', 'Favorite music', Icons.music_note_rounded, AppColors.caregiver, AppColors.caregiverLight),
  _CalmItem('Rainfall', 'Calming sound', Icons.grain_rounded, AppColors.accent, AppColors.accentLight),
];

class PatientCalmingPage extends StatelessWidget {
  const PatientCalmingPage({super.key});

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
            for (final item in _items) ...[
              AppListCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalmingSessionPage(item: item),
                  ),
                ),
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
                          Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
/// For "Deep Breathing" it shows a static breathing circle guide.
class CalmingSessionPage extends StatefulWidget {
  final _CalmItem item;
  const CalmingSessionPage({super.key, required this.item});

  @override
  State<CalmingSessionPage> createState() => _CalmingSessionPageState();
}

class _CalmingSessionPageState extends State<CalmingSessionPage>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isBreathing => widget.item.title == 'Deep Breathing';

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: item.background,
      appBar: SimpleTopBar(title: item.title, color: item.color),
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
                          color: item.color.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.55),
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
                  decoration: BoxDecoration(color: item.color.withOpacity(0.18), shape: BoxShape.circle),
                  child: Icon(item.icon, size: 100, color: item.color),
                ),
              const SizedBox(height: 30),
              Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(item.subtitle, style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),

              // Fake progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: isPlaying ? 0.35 : 0,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 88,
                height: 88,
                child: ElevatedButton(
                  onPressed: () => setState(() => isPlaying = !isPlaying),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.color,
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
