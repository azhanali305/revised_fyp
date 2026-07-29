// Place this file at: lib/services/patient_lookup_service.dart
//
// Caregiver-side helpers for resolving/managing which patient the
// caregiver-side pages (Memory/Calming/Routine Add & List, Dashboard)
// operate on, and for the Patient List screen.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_revised/services/patient_data_service.dart';

class PatientLookupService {
  static const maxPatientsPerCaregiver = 5;

  /// Returns the patientId the caregiver-side pages should act on:
  ///  1. Whatever this device already has set as "active" (fast, offline).
  ///  2. Otherwise, the first patient found in Firestore for this
  ///     caregiver — cached as active locally so future calls skip the
  ///     network round trip.
  /// Returns null if no caregiver is signed in or no patient exists yet.
  static Future<String?> getCurrentPatientId() async {
    final localActive = PatientDataService.getActivePatientId();
    if (localActive != null) return localActive;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final query = await FirebaseFirestore.instance
        .collection('patients')
        .where('caregiverId', isEqualTo: uid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final patientId = query.docs.first.id;
    await PatientDataService.setActivePatient(patientId);
    return patientId;
  }

  /// All patients belonging to the signed-in caregiver, straight from
  /// Firestore (source of truth for "who exists"), newest first.
  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];


  final query = await FirebaseFirestore.instance
      .collection('patients')
      .where('caregiverId', isEqualTo: uid)
      .get();


    return query.docs.map((d) => {'id': d.id, ...d.data()}).toList();

  //   print("Step 1");

  // final uid = FirebaseAuth.instance.currentUser?.uid;
  // print("UID = $uid");

  // print("Step 2");

  // final query = await FirebaseFirestore.instance
  //     .collection('patients')
  //     .where('caregiverId', isEqualTo: uid)
  //     .get();

  // print("Step 3");

  // print("Documents = ${query.docs.length}");

  // return query.docs.map((d) => {
  //       'id': d.id,
  //       ...d.data(),
  //     }).toList();
  }

  static Future<bool> hasReachedPatientLimit() async {
    final patients = await getAllPatients();
    return patients.length >= maxPatientsPerCaregiver;
  }
}