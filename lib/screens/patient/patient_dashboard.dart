// Place this file at: lib/screens/patient/patient_dashboard.dart
// (replacing your existing patient_dashboard.dart)
//
// Changes from your current version:
//  - Reminder banner is now dynamic — pulls the patient's actual routine
//    tasks (PatientDataService.getRoutineTasks) and shows the real next
//    upcoming one, instead of the hardcoded "Take afternoon medicine —
//    2:30 PM". Shows a "No reminders" state when there's nothing
//    upcoming.
//  - Pull-to-refresh (RefreshIndicator) added, and returning from any
//    tile's page now refreshes the dashboard, so a routine task added/
//    completed elsewhere shows up here without restarting the app.
//  - The 6 BigActionTile blocks are generated from one small config list
//    instead of being repeated near-identically.
//  - Your greeting logic (4-tier: morning/afternoon/evening/night) and
//    the commented-out back button are both kept exactly as you have
//    them.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/big_action_tile.dart';
import '../../models/routine_task_model.dart';
import '../../models/patient_model.dart';
import '../../services/patient_data_service.dart';
import '../sign_in_screen.dart';
import 'patient_memory_page.dart';
import 'patient_calming_page.dart';
import 'patient_routine_page.dart';
import 'where_am_i_page.dart';
import 'face_scan_page.dart';

class _Tile {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Widget Function() page;
  const _Tile(this.icon, this.label, this.color, this.background, this.page);
}

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
const _categoryIcons = {
  'Medication': Icons.medication_rounded,
  'Meal': Icons.restaurant_rounded,
  'Hygiene': Icons.clean_hands_rounded,
  'Exercise': Icons.directions_walk_rounded,
  'Appointment': Icons.event_rounded,
};

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> with WidgetsBindingObserver {
  String _patientName = 'there';
  String _caregiverName = 'your caregiver';
  List<RoutineTaskModel> _routineTasks = [];

  int _tapCount = 0;
  Timer? _tapTimer;
  Timer? _dashboardTimer;

  final _tiles = [
    _Tile(Icons.photo_album_rounded, 'My Memories', AppColors.primary, AppColors.primaryLight, () => const PatientMemoryPage()),
    _Tile(Icons.self_improvement_rounded, 'Calm Down', AppColors.success, AppColors.successLight, () => const PatientCalmingPage()),
    _Tile(Icons.checklist_rounded, 'My Routine', AppColors.accent, AppColors.accentLight, () => const PatientRoutinePage()),
    _Tile(Icons.location_on_rounded, 'Where Am I', AppColors.caregiver, AppColors.caregiverLight, () => const WhereAmIPage()),
    _Tile(Icons.face_retouching_natural_rounded, 'Who Is This?', AppColors.danger, AppColors.dangerLight, () => const FaceScanPage()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
    // Refresh periodically so the reminder banner advances once the
    // current reminder's time passes.
    _dashboardTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapTimer?.cancel();
    _dashboardTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Covers any path back to this screen that isn't already handled by
    // _navigateAndRefresh/_openCaregiverSignIn (e.g. the app being
    // backgrounded and resumed).
    if (state == AppLifecycleState.resumed) {
      _refreshDashboard();
    }
  }

  Future<void> _loadDashboardData() async {
    final patientId = PatientDataService.getActivePatientId();
    if (patientId == null) {
      if (mounted) setState(() => _routineTasks = []);
      return;
    }

    // Local data is always available (even offline) — show it right away.
    _routineTasks = PatientDataService.getRoutineTasks(patientId);
    var profile = PatientDataService.getPatientProfile(patientId);
    if (profile != null && profile.fullName.isNotEmpty) {
      _patientName = profile.fullName;
    }
    if (mounted) setState(() {});

    // Refresh the patient's own profile from Firestore too. The local
    // cache above is only ever populated by an explicit
    // savePatientProfile() call somewhere — if this device never ran
    // that (e.g. it only ever received the active patientId, not the
    // full profile), the name would otherwise be stuck on the "there"
    // fallback forever, even though routines/memories/etc. work fine
    // (those are written directly to local Hive when added).
    try {
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get();
      final data = patientDoc.data();
      if (data != null) {
        final fetchedName = data['fullName'] as String?;
        if (fetchedName != null && fetchedName.isNotEmpty && mounted) {
          setState(() => _patientName = fetchedName);
        }
        // Cache it locally so next launch has it offline too, and so
        // profile?.caregiverId below reflects the fresh data.
        try {
          profile = PatientModel.fromMap(data);
          await PatientDataService.savePatientProfile(profile!);
        } catch (_) {
          // Firestore doc didn't cleanly map to PatientModel (e.g. a
          // missing/renamed field) — skip caching, keep the fetched name.
        }
      }
    } catch (_) {
      // Offline / no network — local cache (or the "there" fallback) stands.
    }

    // Caregiver's name needs the network — best-effort, and its failure
    // shouldn't affect the rest of an otherwise-usable offline dashboard.
    if (profile?.caregiverId.isNotEmpty == true) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('caregivers')
            .doc(profile!.caregiverId)
            .get();
        final name = doc.data()?['name'] as String?;
        if (name != null && name.isNotEmpty && mounted) {
          setState(() => _caregiverName = name);
        }
      } catch (_) {
        // Keep the fallback caregiver name; dashboard stays usable offline.
      }
    }
  }

  Future<void> _refreshDashboard() => _loadDashboardData();

  Future<void> _navigateAndRefresh(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await _refreshDashboard();
  }

  String _greeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good evening';
    }

    return 'Good night';
  }

  String _formattedDate(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$weekday, ${date.day} $month';
  }

  // ---------------- Next reminder ----------------

  /// Next time [task] fires from [now], or null if it has none left
  /// (a non-repeating task whose time already passed has no next
  /// occurrence at all).
  DateTime? _nextOccurrence(RoutineTaskModel task, DateTime now) {
    var dt = DateTime(now.year, now.month, now.day, task.hour, task.minute);
    if (!dt.isAfter(now)) {
      if (!task.repeatDaily) return null;
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  (RoutineTaskModel, DateTime)? _findNextReminder() {
    final now = DateTime.now();
    RoutineTaskModel? bestTask;
    DateTime? bestTime;

    for (final task in _routineTasks.where((t) => t.notifyEnabled)) {
      final dt = _nextOccurrence(task, now);
      if (dt == null) continue;
      if (bestTime == null || dt.isBefore(bestTime)) {
        bestTime = dt;
        bestTask = task;
      }
    }

    return (bestTask != null && bestTime != null) ? (bestTask, bestTime) : null;
  }

  String _reminderTimeText(DateTime time, DateTime now) {
    final isTomorrow = time.year != now.year || time.month != now.month || time.day != now.day;
    final formatted = TimeOfDay.fromDateTime(time).format(context);
    return '${isTomorrow ? "Tomorrow" : "Today"} at $formatted';
  }

  Widget _reminderCard({required IconData icon, required String label, required String title, String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderBanner() {
    final next = _findNextReminder();
    if (next == null) {
      return _reminderCard(
        icon: Icons.notifications_none_rounded,
        label: 'No reminders',
        title: 'You have no upcoming tasks.',
      );
    }

    final (task, time) = next;
    return _reminderCard(
      icon: _categoryIcons[task.category] ?? Icons.task_alt_rounded,
      label: 'Next reminder',
      title: task.title,
      subtitle: _reminderTimeText(time, DateTime.now()),
    );
  }

  void _callCaregiver() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Calling $_caregiverName…'),
        content: const Text('This is a UI placeholder — no call is actually placed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTripleTapCandidate() async {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 700), () => _tapCount = 0);

    if (_tapCount == 3) {
      _tapCount = 0;
      // Same push-then-refresh pattern as the other tiles: whatever the
      // caregiver does after this (add a routine task, switch patients,
      // etc.), by the time control returns here — however many screens
      // deep — the dashboard reloads instead of showing stale data from
      // before the trip.
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
      await _refreshDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return GestureDetector(
      onTap: _handleTripleTapCandidate,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row(
                  //   children: [
                  //     IconButton(
                  //       icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  //       onPressed: () => Navigator.of(context).maybePop(),
                  //     ),
                  //     const Spacer(),
                  //   ],
                  // ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wb_sunny_rounded,
                            color: AppColors.accent, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greeting(now.hour)}, $_patientName',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(_formattedDate(now),
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildReminderBanner(),

                  const SizedBox(height: 28),
                  Text('What would you like to do?',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.05,
                    children: [
                      for (final t in _tiles)
                        BigActionTile(
                          icon: t.icon,
                          label: t.label,
                          color: t.color,
                          background: t.background,
                          onTap: () => _navigateAndRefresh(t.page()),
                        ),
                      BigActionTile(
                        icon: Icons.phone_rounded,
                        label: 'Call Caregiver',
                        color: AppColors.primaryDark,
                        background: AppColors.primaryLight,
                        onTap: _callCaregiver,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}