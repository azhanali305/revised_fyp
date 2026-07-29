// Place this file at: lib/screens/caregiver/caregiver_dashboard.dart
// (replacing your existing caregiver_dashboard.dart)
//
// UI/layout is untouched except for one addition: a 5th "My Patients"
// tile in the Manage grid, since the updated flow needs a way to reach
// the new Patient List screen (view all / add / edit / delete / select
// active patient) — there was nowhere to put that link otherwise.
//
// Logic changes:
//  - Loads the caregiver's ACTIVE patient (via PatientLookupService,
//    which reads this device's local activePatientId first and only
//    falls back to Firestore if none is set yet) instead of always
//    grabbing "the first patient found".
//  - Handles having no active patient yet (new caregiver, no patients
//    added) — greeting/stats show a neutral empty state and "Patient
//    Profile" explains there's nothing to show yet, instead of crashing
//    or showing stale data.
//  - Quick stats, Patient Profile dialog, and Manage tiles all now key
//    off the active patient.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';
import 'caregiver_memory_page.dart';
import 'caregiver_calming_page.dart';
import 'caregiver_routine_page.dart';
import 'caregiver_patient_list_page.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  bool _loading = true;
  String? _caregiverName;
  String? _patientId;
  Map<String, dynamic>? _patientData;

  int _memoriesCount = 0;
  int _calmingCount = 0;
  int _tasksCount = 0;
  int _tasksDoneCount = 0;

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

      // Active patient for this device — falls back to "first patient
      // for this caregiver" and caches it locally if none is set yet.
      final patientId = await PatientLookupService.getCurrentPatientId();

      Map<String, dynamic>? patientData;
      int memoriesCount = 0;
      int calmingCount = 0;
      int tasksCount = 0;
      int tasksDoneCount = 0;

      if (patientId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .get();
        patientData = doc.data();

        memoriesCount = PatientDataService.getMemories(patientId).length;
        calmingCount = PatientDataService.getCalmingItems(patientId).length;
        final tasks = PatientDataService.getRoutineTasks(patientId);
        tasksCount = tasks.length;
        tasksDoneCount = tasks.where((t) => t.done).length;
      }

      if (!mounted) return;

      setState(() {
        _caregiverName = caregiverDoc.data()?['name'] as String?;
        _patientId = patientId;
        _patientData = patientData;
        _memoriesCount = memoriesCount;
        _calmingCount = calmingCount;
        _tasksCount = tasksCount;
        _tasksDoneCount = tasksDoneCount;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPatientProfile() {
    if (_patientData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active patient yet — add one from "My Patients".')),
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

  Future<void> _openManagePage(Widget page) async {
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a patient first from "My Patients".')),
      );
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final greetingName = _loading
        ? '…'
        : (_caregiverName?.isNotEmpty == true ? _caregiverName! : 'there');
    final patientName = _loading
        ? '…'
        : (_patientData?['fullName'] as String? ?? 'no patient yet');

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
                children: [
                  Expanded(child: _StatCard(label: 'Memories', value: '$_memoriesCount', icon: Icons.photo_album_rounded, color: AppColors.primary, background: AppColors.primaryLight)),
                  const SizedBox(width: 14),
                  Expanded(child: _StatCard(label: "Today's Tasks", value: '$_tasksCount', icon: Icons.checklist_rounded, color: AppColors.accent, background: AppColors.accentLight)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Calming Items', value: '$_calmingCount', icon: Icons.self_improvement_rounded, color: AppColors.success, background: AppColors.successLight)),
                  const SizedBox(width: 14),
                  Expanded(child: _StatCard(label: 'Completed Today', value: '$_tasksDoneCount/$_tasksCount', icon: Icons.emoji_events_rounded, color: AppColors.caregiver, background: AppColors.caregiverLight)),
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
                    icon: Icons.people_alt_rounded,
                    label: 'My Patients',
                    color: AppColors.caregiver,
                    background: AppColors.caregiverLight,
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CaregiverPatientListPage()));
                      _loadDashboardData();
                    },
                  ),
                  BigActionTile(
                    icon: Icons.photo_album_rounded,
                    label: 'Memory Page',
                    color: AppColors.primary,
                    background: AppColors.primaryLight,
                    onTap: () => _openManagePage(const CaregiverMemoryPage()),
                  ),
                  BigActionTile(
                    icon: Icons.self_improvement_rounded,
                    label: 'Calming Page',
                    color: AppColors.success,
                    background: AppColors.successLight,
                    onTap: () => _openManagePage(const CaregiverCalmingPage()),
                  ),
                  BigActionTile(
                    icon: Icons.checklist_rounded,
                    label: 'Routine Page',
                    color: AppColors.accent,
                    background: AppColors.accentLight,
                    onTap: () => _openManagePage(const CaregiverRoutinePage()),
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