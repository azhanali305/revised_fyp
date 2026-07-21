// Place this file at: lib/screens/patient/patient_dashboard.dart
// (replacing your existing patient_dashboard.dart)
//
// UI/layout is untouched. Logic changes only:
//  - "Good afternoon, Robert" -> greeting now uses the actual patient name
//    from the local Hive profile (saved during Patient Registration) and a
//    real time-of-day greeting (morning/afternoon/evening) instead of a
//    fixed "afternoon".
//  - "Tuesday, 12 July" -> now today's real date, formatted the same way,
//    no `intl` dependency needed.
//  - "Calling Sarah…" -> now uses the actual caregiver's name, looked up
//    from Firestore (caregivers/{caregiverId}) using the caregiverId that
//    was stored on the patient's profile during registration. Falls back
//    to "your caregiver" if offline or the lookup fails, so the dialog
//    never breaks.
//  - The reminder banner is left as-is — it was already marked
//    static/dummy in your comment, and there's no reminders data model yet
//    to pull a real one from.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import 'patient_memory_page.dart';
import 'patient_calming_page.dart';
import 'patient_routine_page.dart';
import 'where_am_i_page.dart';
import 'face_scan_page.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String _patientName = 'there';
  String _caregiverName = 'your caregiver';

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final patientBox = Hive.box('patient');
      final profile = patientBox.get('profile') as Map?;

      if (profile == null) return;

      final fullName = profile['fullName'] as String?;
      final caregiverId = profile['caregiverId'] as String?;

      if (fullName != null && fullName.isNotEmpty) {
        _patientName = fullName;
      }

      if (caregiverId != null && caregiverId.isNotEmpty) {
        final caregiverDoc = await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(caregiverId)
            .get();

        final name = caregiverDoc.data()?['name'] as String?;
        if (name != null && name.isNotEmpty) {
          _caregiverName = name;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      // Offline or lookup failed — keep the fallback text so the UI
      // never breaks.
    }
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formattedDate(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$weekday, ${date.day} $month';
  }

  void _callCaregiver() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Calling $_caregiverName…'),
        content: const Text('This is a UI placeholder — no call is actually placed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

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
                        Text('${_greeting(now.hour)}, $_patientName',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(_formattedDate(now),
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
                    onTap: _callCaregiver,
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