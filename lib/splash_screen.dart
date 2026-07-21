import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp_revised/screens/caregiver/caregiver_registration_page.dart';
import 'package:fyp_revised/screens/patient/patient_dashboard.dart';
import 'package:fyp_revised/screens/sign_in_screen.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _tapCount = 0;
  Timer? _tapTimer;
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(seconds: 3));

    if (_navigationStarted) return;

      final patientBox = Hive.box("patient");

      bool patientExists = patientBox.containsKey("profile");

    if (!mounted) return;

    _navigationStarted = true;

    if (patientExists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PatientDashboard(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CaregiverRegistrationPage(),
        ),
      );
    }
  }

  void _handleTap() {
    _tapCount++;

    _tapTimer?.cancel();

    _tapTimer = Timer(
      const Duration(milliseconds: 700),
      () {
        _tapCount = 0;
      },
    );

    if (_tapCount == 3 && !_navigationStarted) {
      _navigationStarted = true;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SignInScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
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
      ),
    );
  }
}