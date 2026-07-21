/// Place this file at: lib/models/caregiver_model.dart
///
/// Represents the caregiver profile that is saved to Firestore after
/// Firebase Authentication sign-up (per the flow diagram:
/// "Firebase Authentication" -> "Store Caregiver (Firestore)").
class CaregiverModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfBirth;

  CaregiverModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth.toIso8601String(),
    };
  }

  factory CaregiverModel.fromMap(Map<String, dynamic> map) {
    return CaregiverModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
    );
  }
}