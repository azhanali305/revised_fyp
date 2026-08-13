// Place this file at: lib/models/memory_model.dart
//
// Change from before:
//  - Added `faceEmbedding` (List<double>?), the 192-d MobileFaceNet
//    vector generated from `photoPath` when a caregiver adds/edits a
//    memory. Nullable because older memories (or ones added without a
//    detectable face) won't have one — those are simply skipped during
//    matching in FaceRecognitionService.findBestMatch.
//
// After editing this file, re-run:
//   dart run build_runner build --delete-conflicting-outputs
// to regenerate memory_model.g.dart with the new HiveField(8).

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
  @HiveField(8)
  final List<double>? faceEmbedding;

  MemoryModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.relation,
    this.photoPath,
    required this.description,
    this.voiceNotePath,
    required this.createdAt,
    this.faceEmbedding,
  });

  /// True when this memory has a usable embedding for face matching.
  bool get hasFaceEmbedding => faceEmbedding != null && faceEmbedding!.isNotEmpty;

  /// Returns a copy with a (re)computed embedding, keeping everything
  /// else the same. Handy if you generate the embedding asynchronously
  /// after the memory was already created and saved.
  MemoryModel copyWithEmbedding(List<double> embedding) {
    return MemoryModel(
      id: id,
      patientId: patientId,
      name: name,
      relation: relation,
      photoPath: photoPath,
      description: description,
      voiceNotePath: voiceNotePath,
      createdAt: createdAt,
      faceEmbedding: embedding,
    );
  }
}