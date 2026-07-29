// Place this file at: lib/models/patient_model.dart
//
// Dual-purpose model:
//  - Hive TypeAdapter (@HiveType/@HiveField) for the local cache in the
//    'patient' box (key "profile") — used for splash-screen routing and
//    reading the local patientId without a network call.
//  - toMap()/fromMap() for Firestore, which needs a plain Map, not a
//    Hive-typed object.
//
// After adding this file, run:
//   dart run build_runner build --delete-conflicting-outputs
// This generates patient_model.g.dart (PatientModelAdapter) next to it.

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'patient_model.g.dart';

@HiveType(typeId: 0)
class PatientModel {
  @HiveField(0)
  final String patientId;
  @HiveField(1)
  final String caregiverId;
  @HiveField(2)
  final String fullName;
  @HiveField(3)
  final DateTime dateOfBirth;
  @HiveField(4)
  final String gender;
  @HiveField(5)
  final String relationshipWithCaregiver;
  @HiveField(6)
  final String preferredLanguage; // "Urdu" or "English"
  @HiveField(7)
  final String emergencyContactName;
  @HiveField(8)
  final String emergencyContactPhone;
  @HiveField(9)
  final DateTime createdAt;

  PatientModel({
    required this.patientId,
    required this.caregiverId,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.relationshipWithCaregiver,
    required this.preferredLanguage,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.createdAt,
  });

  /// Firestore needs a plain Map, not a Hive-typed object.
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'caregiverId': caregiverId,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'relationshipWithCaregiver': relationshipWithCaregiver,
      'preferredLanguage': preferredLanguage,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatientModel.fromMap(Map<dynamic, dynamic> map) {
    return PatientModel(
      patientId: map['patientId'] as String,
      caregiverId: map['caregiverId'] as String,
      fullName: map['fullName'] as String,
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      gender: map['gender'] as String,
      relationshipWithCaregiver: map['relationshipWithCaregiver'] as String,
      preferredLanguage: map['preferredLanguage'] as String,
      emergencyContactName: map['emergencyContactName'] as String,
      emergencyContactPhone: map['emergencyContactPhone'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}