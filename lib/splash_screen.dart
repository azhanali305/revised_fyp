// Place this file at: lib/splash_screen.dart (replacing the existing one)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp_revised/screens/caregiver/caregiver_registration_page.dart';
import 'package:fyp_revised/screens/patient/patient_dashboard.dart';
import 'package:fyp_revised/services/patient_data_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // "Normal Application Launch": if setup is complete, read the Active
    // Patient ID from Hive and go straight to that patient's dashboard —
    // no network call needed. Otherwise, go to Registration/Sign In.
    final setupComplete = PatientDataService.isSetupComplete();
    final activePatientId = PatientDataService.getActivePatientId();

    if (setupComplete && activePatientId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CaregiverRegistrationPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// Logo
            // Image.asset(
            //   "assets/images/logo.png",
            //   width: 150,
            // ),

            const SizedBox(height: 25),

            const Text(
              "Calm Mind",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Helping patients remember what matters",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}