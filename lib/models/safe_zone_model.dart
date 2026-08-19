// Place this file at: lib/models/safe_zone_model.dart
//
// Same dual-purpose pattern as patient_model.dart:
//  - Hive TypeAdapter for local caching (so the patient's app can show
//    "You are at Home" and run geofence checks even briefly offline).
//  - toMap()/fromMap() for Firestore sync.
//
// typeId is 10 to stay well clear of the existing 0-3 range used by
// PatientModel / MemoryModel / CalmingItemModel / RoutineTaskModel.
// If typeId 10 happens to collide with something else in your project,
// change it here AND nowhere else (Hive just needs it unique + stable).
//
// After adding this file, run:
//   dart run build_runner build --delete-conflicting-outputs
// This generates safe_zone_model.g.dart (SafeZoneModelAdapter) next to it.

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'safe_zone_model.g.dart';

@HiveType(typeId: 10)
class SafeZoneModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String patientId;
  @HiveField(2)
  final String name; // "Home", "Grandma's House"
  @HiveField(3)
  final double latitude;
  @HiveField(4)
  final double longitude;
  @HiveField(5)
  final double radiusMeters;
  @HiveField(6)
  final DateTime createdAt;

  SafeZoneModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SafeZoneModel.fromMap(Map<dynamic, dynamic> map) {
    return SafeZoneModel(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: (map['radiusMeters'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  SafeZoneModel copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
  }) {
    return SafeZoneModel(
      id: id,
      patientId: patientId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdAt: createdAt,
    );
  }
}