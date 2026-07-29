// Place this file at: lib/models/memory_model.dart
//
// After adding this file, run:
//   dart run build_runner build --delete-conflicting-outputs
// This generates memory_model.g.dart (MemoryModelAdapter) next to it.

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'memory_model.g.dart';

@HiveType(typeId: 1)
class MemoryModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String patientId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String relation;
  @HiveField(4)
  final String? photoPath;
  @HiveField(5)
  final String description;
  @HiveField(6)
  final String? voiceNotePath;
  @HiveField(7)
  final DateTime createdAt;

  MemoryModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.relation,
    this.photoPath,
    required this.description,
    this.voiceNotePath,
    required this.createdAt,
  });
}