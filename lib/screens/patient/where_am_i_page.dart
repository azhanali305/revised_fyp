import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';

/// Shows the patient a simple, reassuring answer to "Where am I?".
/// Pure UI — a static placeholder map area with a pin, plus a plain-language
/// summary and a big "Call Caregiver" action for extra reassurance.
class WhereAmIPage extends StatelessWidget {
  const WhereAmIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleTopBar(title: 'Where Am I'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map placeholder
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.caregiverLight,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.fromHeight(260),
                      painter: _GridPainter(),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.caregiver,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 34),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('You are safe at:', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 6),
              Text('Home', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text('123 Maple Street, Springfield',
                  style: Theme.of(context).textTheme.bodyMedium),

              const SizedBox(height: 24),
              AppListCard(
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.access_time_rounded, color: AppColors.primary, background: AppColors.primaryLight),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('It is currently', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 2),
                          Text('2:14 PM · Tuesday', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              BigPrimaryButton(
                label: 'Call Sarah (Caregiver)',
                icon: Icons.phone_rounded,
                color: AppColors.caregiver,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Calling Sarah…'),
                      content: const Text('This is a UI placeholder — no call is actually placed.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple decorative grid to suggest a map without needing map packages.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.caregiver.withOpacity(0.15)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
