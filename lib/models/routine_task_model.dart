// Place this file at: lib/models/routine_task_model.dart
//
// After adding this file, run:
//   dart run build_runner build --delete-conflicting-outputs
// This generates routine_task_model.g.dart (RoutineTaskModelAdapter) next to it.

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'routine_task_model.g.dart';

@HiveType(typeId: 3)
class RoutineTaskModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String patientId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final int hour;
  @HiveField(5)
  final int minute;
  @HiveField(6)
  final bool repeatDaily;
  @HiveField(7)
  final bool notifyEnabled;
  @HiveField(8)
  final bool done;
  @HiveField(9)
  final DateTime createdAt;

  RoutineTaskModel({
    required this.id,
    required this.patientId,
    required this.title,
    required this.category,
    required this.hour,
    required this.minute,
    this.repeatDaily = true,
    this.notifyEnabled = true,
    this.done = false,
    required this.createdAt,
  });

  RoutineTaskModel copyWith({bool? done}) => RoutineTaskModel(
        id: id,
        patientId: patientId,
        title: title,
        category: category,
        hour: hour,
        minute: minute,
        repeatDaily: repeatDaily,
        notifyEnabled: notifyEnabled,
        done: done ?? this.done,
        createdAt: createdAt,
      );

  String get formattedTime {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final suffix = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }
}