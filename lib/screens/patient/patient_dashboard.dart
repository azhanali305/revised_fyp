import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import 'patient_memory_page.dart';
import 'patient_calming_page.dart';
import 'patient_routine_page.dart';
import 'where_am_i_page.dart';
import 'face_scan_page.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wb_sunny_rounded,
                        color: AppColors.accent, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good afternoon, Robert',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Tuesday, 12 July',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gentle reminder banner (static/dummy)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: AppColors.primary, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Next reminder',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('Take afternoon medicine — 2:30 PM',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Text('What would you like to do?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: [
                  BigActionTile(
                    icon: Icons.photo_album_rounded,
                    label: 'My Memories',
                    color: AppColors.primary,
                    background: AppColors.primaryLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PatientMemoryPage())),
                  ),
                  BigActionTile(
                    icon: Icons.self_improvement_rounded,
                    label: 'Calm Down',
                    color: AppColors.success,
                    background: AppColors.successLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PatientCalmingPage())),
                  ),
                  BigActionTile(
                    icon: Icons.checklist_rounded,
                    label: 'My Routine',
                    color: AppColors.accent,
                    background: AppColors.accentLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PatientRoutinePage())),
                  ),
                  BigActionTile(
                    icon: Icons.location_on_rounded,
                    label: 'Where Am I',
                    color: AppColors.caregiver,
                    background: AppColors.caregiverLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WhereAmIPage())),
                  ),
                  BigActionTile(
                    icon: Icons.face_retouching_natural_rounded,
                    label: 'Who Is This?',
                    color: AppColors.danger,
                    background: AppColors.dangerLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FaceScanPage())),
                  ),
                  BigActionTile(
                    icon: Icons.phone_rounded,
                    label: 'Call Caregiver',
                    color: AppColors.primaryDark,
                    background: AppColors.primaryLight,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Calling Sarah…'),
                          content: const Text('This is a UI placeholder — no call is actually placed.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
