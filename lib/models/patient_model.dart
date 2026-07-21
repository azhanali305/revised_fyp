/// Place this file at: lib/models/patient_model.dart
///
/// Represents the patient profile. It is written to BOTH:
///  - Firestore (collection: "patients") — the source of truth, since
///    caregivers/other devices may need it.
///  - Hive box "patient", key "profile" — a local cache so the app can
///    boot straight to PatientDashboard without a network call.
///
/// patientId is the Firestore auto-generated document id (see
/// FirebaseFirestore.instance.collection('patients').doc().id).
/// caregiverId is the Firebase Auth uid of the caregiver who registered
/// this patient (auto-filled, not typed by the user).
class PatientModel {
  final String patientId;
  final String caregiverId;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String relationshipWithCaregiver;
  final String preferredLanguage; // "Urdu" or "English"
  final String emergencyContactName;
  final String emergencyContactPhone;
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