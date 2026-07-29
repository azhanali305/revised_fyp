// Place this file at: lib/main.dart (replacing the existing one)
//
// Changes from before:
//  - Initializes RoutineNotificationService after Hive is ready (it needs
//    to look up tasks via PatientDataService when a notification fires).
//  - Wires notification taps / full-screen-intent launches to open
//    RoutineAlarmScreen with the correct task, both while the app is
//    already running and on a cold start.

import 'package:flutter/material.dart';
import 'package:fyp_revised/splash_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:fyp_revised/models/patient_model.dart';
import 'package:fyp_revised/models/memory_model.dart';
import 'package:fyp_revised/models/calming_item_model.dart';
import 'package:fyp_revised/models/routine_task_model.dart';
import 'package:fyp_revised/services/patient_data_service.dart';
import 'package:fyp_revised/services/routine_notification_service.dart';
import 'package:fyp_revised/screens/patient/routine_alarm_screen.dart';
import 'firebase_options.dart';

RoutineTaskModel? _findTask(String patientId, String taskId) {
  final tasks = PatientDataService.getRoutineTasks(patientId);
  for (final t in tasks) {
    if (t.id == taskId) return t;
  }
  return null;
}

final navigatorKey = GlobalKey<NavigatorState>();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);
  await Hive.initFlutter();

  // Register TypeAdapters BEFORE opening any box that stores these types.
  Hive.registerAdapter(PatientModelAdapter());
  Hive.registerAdapter(MemoryModelAdapter());
  Hive.registerAdapter(CalmingItemModelAdapter());
  Hive.registerAdapter(RoutineTaskModelAdapter());

  await Hive.openBox('patient');
  // Opens 'patient_profiles', 'memories', 'calming_items', and
  // 'routine_tasks' — everything a caregiver sets up for a patient.
  await PatientDataService.init();

  await RoutineNotificationService.init();

  // Fires when a notification is tapped, or when Android's full-screen
  // intent launches the app directly while it's already running.
  RoutineNotificationService.onNotificationOpened =
      (patientId, taskId) async {
    final task = _findTask(patientId, taskId);
    if (task != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => RoutineAlarmScreen(task: task)),
      );
    }
  };

  // If the app was launched cold by tapping a notification / full-screen
  // intent, show the alarm screen immediately instead of the splash flow.
  RoutineTaskModel? launchTask;
  final launchPayload = await RoutineNotificationService.getLaunchPayload();
  if (launchPayload != null) {
    final (patientId, taskId) = launchPayload;
    launchTask = _findTask(patientId, taskId);
  }

  runApp(MemoryCareApp(launchTask: launchTask));
}

class MemoryCareApp extends StatelessWidget {
  final RoutineTaskModel? launchTask;
  const MemoryCareApp({super.key, this.launchTask});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Memory Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: launchTask != null
          ? RoutineAlarmScreen(task: launchTask!)
          : const SplashScreen(),
    );
  }
}