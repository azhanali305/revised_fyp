// Place this file at: lib/screens/caregiver/caregiver_dashboard.dart
// (replacing your existing caregiver_dashboard.dart)
//
// UI/layout is untouched. Logic changes only:
//  - "Hello, Sarah" / "Caring for Robert" are no longer hardcoded — they're
//    pulled from Firestore (caregivers/{uid} for the caregiver's name, and
//    the first patients doc with matching caregiverId for the patient's
//    name).
//  - The "Patient Profile" tile's onTap was empty (`() {}`) — it now shows
//    the registered patient's details in a dialog, using the same
//    "placeholder action via AlertDialog" pattern your PatientDashboard
//    already uses for "Call Caregiver".
//  - Memories / Today's Tasks / Calming Items / Completed Today are left
//    as placeholder numbers — there's no memories/tasks/calming-items data
//    model yet, so there's nothing real to pull them from. Tell me if you
//    want those built out too.
//
// NOTE: this screen has no sign-out control in its current design, so none
// was added — if you want one, tell me where it should go and I'll wire it
// in without otherwise touching the layout.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import 'caregiver_memory_page.dart';
import 'caregiver_calming_page.dart';
import 'caregiver_routine_page.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  bool _loading = true;
  String? _caregiverName;
  Map<String, dynamic>? _patientData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final caregiverDoc =
          await FirebaseFirestore.instance.collection('caregivers').doc(uid).get();

      final patientQuery = await FirebaseFirestore.instance
          .collection('patients')
          .where('caregiverId', isEqualTo: uid)
          .limit(1)
          .get();

      if (!mounted) return;

      setState(() {
        _caregiverName = caregiverDoc.data()?['name'] as String?;
        _patientData =
            patientQuery.docs.isNotEmpty ? patientQuery.docs.first.data() : null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPatientProfile() {
    if (_patientData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient registered yet.')),
      );
      return;
    }

    final patient = _patientData!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(patient['fullName'] as String? ?? 'Patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Relationship: ${patient['relationshipWithCaregiver'] ?? '-'}'),
            Text('Gender: ${patient['gender'] ?? '-'}'),
            Text('Preferred language: ${patient['preferredLanguage'] ?? '-'}'),
            Text(
              'Emergency contact: ${patient['emergencyContactName'] ?? '-'} '
              '(${patient['emergencyContactPhone'] ?? '-'})',
            ),
          ],
        ),
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
    final greetingName = _loading
        ? '…'
        : (_caregiverName?.isNotEmpty == true ? _caregiverName! : 'there');
    final patientName = _loading
        ? '…'
        : (_patientData?['fullName'] as String? ?? 'your patient');

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
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.caregiverLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded,
                        color: AppColors.caregiver, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $greetingName',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Caring for $patientName',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick stats
              Row(
                children: const [
                  Expanded(child: _StatCard(label: 'Memories', value: '5', icon: Icons.photo_album_rounded, color: AppColors.primary, background: AppColors.primaryLight)),
                  SizedBox(width: 14),
                  Expanded(child: _StatCard(label: "Today's Tasks", value: '7', icon: Icons.checklist_rounded, color: AppColors.accent, background: AppColors.accentLight)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(child: _StatCard(label: 'Calming Items', value: '4', icon: Icons.self_improvement_rounded, color: AppColors.success, background: AppColors.successLight)),
                  SizedBox(width: 14),
                  Expanded(child: _StatCard(label: 'Completed Today', value: '2/7', icon: Icons.emoji_events_rounded, color: AppColors.caregiver, background: AppColors.caregiverLight)),
                ],
              ),

              const SizedBox(height: 28),
              Text('Manage', style: Theme.of(context).textTheme.titleLarge),
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
                    label: 'Memory Page',
                    color: AppColors.primary,
                    background: AppColors.primaryLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CaregiverMemoryPage())),
                  ),
                  BigActionTile(
                    icon: Icons.self_improvement_rounded,
                    label: 'Calming Page',
                    color: AppColors.success,
                    background: AppColors.successLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CaregiverCalmingPage())),
                  ),
                  BigActionTile(
                    icon: Icons.checklist_rounded,
                    label: 'Routine Page',
                    color: AppColors.accent,
                    background: AppColors.accentLight,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CaregiverRoutinePage())),
                  ),
                  BigActionTile(
                    icon: Icons.person_rounded,
                    label: 'Patient Profile',
                    color: AppColors.caregiver,
                    background: AppColors.caregiverLight,
                    onTap: _showPatientProfile,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, background: background, size: 44),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}