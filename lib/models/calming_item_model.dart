// Place this file at: lib/models/calming_item_model.dart
//
// After adding this file, run:
//   dart run build_runner build --delete-conflicting-outputs
// This generates calming_item_model.g.dart (CalmingItemModelAdapter) next to it.

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'calming_item_model.g.dart';

@HiveType(typeId: 2)
class CalmingItemModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String patientId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String type; // 'Music' | 'Sound' | 'Breathing Exercise'
  @HiveField(4)
  final String? audioPath;
  @HiveField(5)
  final bool isAsset;
  @HiveField(6)
  final int durationMinutes;
  @HiveField(7)
  final int breatheInSeconds;
  @HiveField(8)
  final int holdSeconds;
  @HiveField(9)
  final int breatheOutSeconds;
  @HiveField(10)
  final DateTime createdAt;

  CalmingItemModel({
    required this.id,
    required this.patientId,
    required this.title,
    required this.type,
    this.audioPath,
    this.isAsset = false,
    this.durationMinutes = 3,
    this.breatheInSeconds = 4,
    this.holdSeconds = 4,
    this.breatheOutSeconds = 4,
    required this.createdAt,
  });
}