// Place this file at: lib/screens/caregiver/caregiver_patient_list_page.dart
//
// New screen (didn't exist before), styled to match your existing
// caregiver list pages (calming/memory/routine): SimpleTopBar,
// AppListCard, IconBadge, FloatingActionButton.extended.
//
// Lets the caregiver:
//  - View all registered patients (Firestore, source of truth).
//  - See which one is this device's active patient.
//  - Select a patient as active (checks local cache first, per the
//    "Selecting a Patient" requirement — falls back to Firestore + caches
//    locally if this device has never seen that patient before).
//  - Add a new patient (disabled/hidden at the 5-patient limit).
//  - Edit a patient (reuses PatientRegistrationPage, pre-filled).
//  - Delete a patient (Firestore + all local data for that patient).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/patient_model.dart';
import '../../services/patient_data_service.dart';
import '../../services/patient_lookup_service.dart';
import '../patient/patient_registration_page.dart';

class CaregiverPatientListPage extends StatefulWidget {
  const CaregiverPatientListPage({super.key});

  @override
  State<CaregiverPatientListPage> createState() => _CaregiverPatientListPageState();
}

class _CaregiverPatientListPageState extends State<CaregiverPatientListPage> {
  List<Map<String, dynamic>> _patients = [];
  String? _activePatientId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final patients = await PatientLookupService.getAllPatients();
    if (!mounted) return;
    setState(() {
      _patients = patients;
      _activePatientId = PatientDataService.getActivePatientId();
      _loading = false;
    });
  }

  Future<void> _addPatient() async {
    if (_patients.length >= PatientLookupService.maxPatientsPerCaregiver) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Maximum of ${PatientLookupService.maxPatientsPerCaregiver} patients reached.'),
      ));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientRegistrationPage(caregiverId: uid),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _editPatient(Map<String, dynamic> patientData) async {
    final existing = PatientModel.fromMap(patientData);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientRegistrationPage(
          caregiverId: existing.caregiverId,
          existingPatient: existing,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _selectPatient(String patientId, String name) async {
    // "Selecting a Patient": check local data first, else fetch + cache.
    var profile = PatientDataService.getPatientProfile(patientId);

    if (profile == null) {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get();
      if (doc.exists) {
        profile = PatientModel.fromMap(doc.data()!);
        await PatientDataService.savePatientProfile(profile);
      }
    }

    await PatientDataService.setActivePatient(patientId);

    if (!mounted) return;
    setState(() => _activePatientId = patientId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name is now the active patient.')),
    );
  }

  Future<void> _deletePatient(String patientId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Patient?'),
        content: Text('This removes $name and all their data (memories, routines, '
            'calming items) from this app. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance.collection('patients').doc(patientId).delete();
    await PatientDataService.deleteAllDataForPatient(patientId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = _patients.length >= PatientLookupService.maxPatientsPerCaregiver;

    return Scaffold(
      appBar: const SimpleTopBar(title: 'My Patients'),
      floatingActionButton: atLimit
          ? null
          : FloatingActionButton.extended(
              onPressed: _addPatient,
              backgroundColor: AppColors.caregiver,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Patient'),
            ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (atLimit)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Text(
                        'Maximum of ${PatientLookupService.maxPatientsPerCaregiver} patients reached.',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ),
                  Expanded(
                    child: _patients.isEmpty
                        ? Center(
                            child: Text(
                              'No patients added yet.\nTap "Add Patient" to get started.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: _patients.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, i) {
                              final p = _patients[i];
                              final id = p['id'] as String;
                              final name = p['fullName'] as String? ?? 'Unnamed';
                              final relation = p['relationshipWithCaregiver'] as String? ?? '';
                              final isActive = id == _activePatientId;

                              return AppListCard(
                                onTap: () => _selectPatient(id, name),
                                child: Row(
                                  children: [
                                    IconBadge(
                                      icon: Icons.person_rounded,
                                      color: isActive ? AppColors.success : AppColors.caregiver,
                                      background: isActive ? AppColors.successLight : AppColors.caregiverLight,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(name, style: Theme.of(context).textTheme.titleMedium),
                                              if (isActive) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.successLight,
                                                    borderRadius: BorderRadius.circular(AppRadius.chip),
                                                  ),
                                                  child: const Text('Active',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.success)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (relation.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(relation, style: Theme.of(context).textTheme.bodyMedium),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                                      onPressed: () => _editPatient(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                      onPressed: () => _deletePatient(id, name),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}