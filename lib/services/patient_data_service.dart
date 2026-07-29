// Place this file at: lib/services/patient_data_service.dart
//
// Local (Hive) storage for:
//  - which patient this device currently has "active" (drives Patient
//    Dashboard routing on Splash, and which patient caregiver-side Add
//    pages write to)
//  - each patient's profile (cached locally so it can be reused across
//    caregiver devices / patients, per-patient — a caregiver device can
//    hold more than one patient's profile at once)
//  - everything a caregiver sets up for a patient: memories, calming
//    items, routine tasks — all keyed by patientId
//
// Storage shape: memories/calming_items/routine_tasks boxes store, per
// patientId key, a List<TypedModel> directly (Hive handles serialization
// via the generated TypeAdapters — no manual toMap/fromMap needed).
// patient_profiles stores one PatientModel per patientId key.
//
// IMPORTANT: call PatientDataService.init() once during app startup
// (see main.dart), and make sure adapters are registered first.

import 'dart:io';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fyp_revised/models/patient_model.dart';
import 'package:fyp_revised/models/memory_model.dart';
import 'package:fyp_revised/models/calming_item_model.dart';
import 'package:fyp_revised/models/routine_task_model.dart';

class PatientDataService {
  static const patientBoxName = 'patient'; // existing box: activePatientId, isSetupComplete
  static const patientProfilesBoxName = 'patient_profiles';
  static const memoriesBoxName = 'memories';
  static const calmingBoxName = 'calming_items';
  static const routineBoxName = 'routine_tasks';

  static Future<void> init() async {
    await Hive.openBox(patientProfilesBoxName);
    await Hive.openBox(memoriesBoxName);
    await Hive.openBox(calmingBoxName);
    await Hive.openBox(routineBoxName);
  }

  static Box get _patientBox => Hive.box(patientBoxName);
  static Box get _profilesBox => Hive.box(patientProfilesBoxName);
  static Box get _memoriesBox => Hive.box(memoriesBoxName);
  static Box get _calmingBox => Hive.box(calmingBoxName);
  static Box get _routineBox => Hive.box(routineBoxName);

  static String newId() => '${DateTime.now().microsecondsSinceEpoch}';

  /// Raw app-private documents directory path — for callers (like the
  /// audio recorder) that need a concrete destination path up front,
  /// rather than copying a file that already exists.
  static Future<String> appDocumentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Copies a picked file into app-private storage so it survives cache
  /// clears and file-picker temp cleanup, and returns the new path.
  static Future<String> persistFile(String sourcePath, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'dat';
    final destPath =
        '${dir.path}/${prefix}_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  // ---------------- Active patient / setup state (per device) ----------------

  static String? getActivePatientId() =>
      _patientBox.get('activePatientId') as String?;

  static bool isSetupComplete() =>
      _patientBox.get('isSetupComplete', defaultValue: false) as bool;

  /// Marks this device as pointed at [patientId] — used right after a
  /// patient is registered, or when a caregiver "selects" a patient from
  /// the Patient List. Also flips isSetupComplete so Splash routes
  /// straight to PatientDashboard on next launch.
  static Future<void> setActivePatient(String patientId) async {
    await _patientBox.put('activePatientId', patientId);
    await _patientBox.put('isSetupComplete', true);
  }

  static Future<void> clearActivePatient() async {
    await _patientBox.delete('activePatientId');
    await _patientBox.put('isSetupComplete', false);
  }

  // ---------------- Patient profiles (local cache, per patientId) ----------------

  static PatientModel? getPatientProfile(String patientId) =>
      _profilesBox.get(patientId) as PatientModel?;

  static Future<void> savePatientProfile(PatientModel patient) async {
    await _profilesBox.put(patient.patientId, patient);
  }

  static Future<void> deletePatientProfile(String patientId) async {
    await _profilesBox.delete(patientId);
  }

  /// Wipes every local trace of a patient (profile + memories + calming
  /// items + routine tasks). Used when a caregiver deletes a patient. If
  /// this device's active patient was the one deleted, clears that too.
  static Future<void> deleteAllDataForPatient(String patientId) async {
    await _profilesBox.delete(patientId);
    await _memoriesBox.delete(patientId);
    await _calmingBox.delete(patientId);
    await _routineBox.delete(patientId);
    if (getActivePatientId() == patientId) {
      await clearActivePatient();
    }
  }

  // ---------------- Memories ----------------

  static List<MemoryModel> getMemories(String patientId) {
    final raw = _memoriesBox.get(patientId) as List?;
    if (raw == null) return [];
    return List<MemoryModel>.from(raw);
  }

  static Future<void> addMemory(MemoryModel memory) async {
    final list = getMemories(memory.patientId)..add(memory);
    await _memoriesBox.put(memory.patientId, list);
  }

  static Future<void> deleteMemory(String patientId, String memoryId) async {
    final list = getMemories(patientId)..removeWhere((m) => m.id == memoryId);
    await _memoriesBox.put(patientId, list);
  }

  // ---------------- Calming items ----------------

  /// Bundled/preset items shipped with the app. These match the four
  /// items that were previously hardcoded on both the caregiver and
  /// patient calming pages.
  static List<CalmingItemModel> _defaultCalmingItems(String patientId) {
    final now = DateTime.now();
    return [
      CalmingItemModel(
        id: 'preset_breathing',
        patientId: patientId,
        title: 'Deep Breathing',
        type: 'Breathing Exercise',
        durationMinutes: 3,
        createdAt: now,
      ),
      CalmingItemModel(
        id: 'preset_ocean',
        patientId: patientId,
        title: 'Ocean Waves',
        type: 'Sound',
        audioPath: 'assets/sounds/ocean_waves.mp3',
        isAsset: true,
        durationMinutes: 5,
        createdAt: now,
      ),
      CalmingItemModel(
        id: 'preset_piano',
        patientId: patientId,
        title: 'Piano Melody',
        type: 'Music',
        audioPath: 'assets/sounds/piano_melody.mp3',
        isAsset: true,
        durationMinutes: 4,
        createdAt: now,
      ),
      CalmingItemModel(
        id: 'preset_rain',
        patientId: patientId,
        title: 'Rainfall',
        type: 'Sound',
        audioPath: 'assets/sounds/rainfall.mp3',
        isAsset: true,
        durationMinutes: 6,
        createdAt: now,
      ),
    ];
  }

  static List<CalmingItemModel> getCalmingItems(String patientId) {
    final raw = _calmingBox.get(patientId) as List?;

    if (raw == null) {
      // First time this patient's calming list is opened — seed it with
      // the bundled presets so both caregiver and patient see them.
      final defaults = _defaultCalmingItems(patientId);
      _calmingBox.put(patientId, defaults);
      return defaults;
    }

    return List<CalmingItemModel>.from(raw);
  }

  static Future<void> addCalmingItem(CalmingItemModel item) async {
    final list = getCalmingItems(item.patientId)..add(item);
    await _calmingBox.put(item.patientId, list);
  }

  static Future<void> deleteCalmingItem(String patientId, String itemId) async {
    final list = getCalmingItems(patientId)..removeWhere((c) => c.id == itemId);
    await _calmingBox.put(patientId, list);
  }

  // ---------------- Routine tasks ----------------

  static List<RoutineTaskModel> getRoutineTasks(String patientId) {
    final raw = _routineBox.get(patientId) as List?;
    if (raw == null) return [];
    final tasks = List<RoutineTaskModel>.from(raw);
    tasks.sort((a, b) =>
        (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return tasks;
  }

  static Future<void> addRoutineTask(RoutineTaskModel task) async {
    final list = getRoutineTasks(task.patientId)..add(task);
    await _routineBox.put(task.patientId, list);
  }

  static Future<void> deleteRoutineTask(String patientId, String taskId) async {
    final list = getRoutineTasks(patientId)..removeWhere((t) => t.id == taskId);
    await _routineBox.put(patientId, list);
  }

  static Future<void> setRoutineTaskDone(
      String patientId, String taskId, bool done) async {
    final list = getRoutineTasks(patientId);
    final index = list.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    list[index] = list[index].copyWith(done: done);
    await _routineBox.put(patientId, list);
  }
}