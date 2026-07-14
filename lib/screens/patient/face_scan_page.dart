import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';

/// Pure UI mock of the face-scan flow: a camera-preview placeholder, a big
/// scan button, a fake "scanning" state, then a result card that matches
/// against something the caregiver saved on the Memory page.
/// No camera / ML model wiring — visuals only.
class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

enum _ScanState { idle, scanning, matched }

class _FaceScanPageState extends State<FaceScanPage> {
  _ScanState state = _ScanState.idle;

  void _startScan() async {
    setState(() => state = _ScanState.scanning);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => state = _ScanState.matched);
  }

  void _reset() => setState(() => state = _ScanState.idle);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Who Is This?', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fake camera preview
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.grey.shade900, Colors.black],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 180,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  // Face-frame guide overlay
                  Center(
                    child: Container(
                      width: 230,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: state == _ScanState.matched
                              ? AppColors.success
                              : Colors.white.withOpacity(0.7),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(140),
                      ),
                    ),
                  ),
                  if (state == _ScanState.scanning)
                    const Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          ),
                          SizedBox(height: 12),
                          Text('Scanning…', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom panel: button OR result card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: state == _ScanState.matched
                  ? _MatchResult(onScanAgain: _reset)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Point the camera at the person\'s face and tap scan.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        BigPrimaryButton(
                          label: state == _ScanState.scanning ? 'Scanning…' : 'Scan Face',
                          icon: Icons.camera_alt_rounded,
                          color: AppColors.danger,
                          onTap: state == _ScanState.scanning ? () {} : _startScan,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchResult extends StatelessWidget {
  final VoidCallback onScanAgain;
  const _MatchResult({required this.onScanAgain});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const IconBadge(
              icon: Icons.face_rounded,
              color: AppColors.accent,
              background: AppColors.accentLight,
              size: 72,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 6),
                      Text('Match found', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Sarah', style: Theme.of(context).textTheme.headlineMedium),
                  Text('This is your daughter', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: BigPrimaryButton(
                label: 'Play Info',
                icon: Icons.volume_up_rounded,
                color: AppColors.primary,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onScanAgain,
            child: const Text('Scan Again', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
