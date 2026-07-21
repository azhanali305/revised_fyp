import 'package:flutter/material.dart';
import 'package:fyp_revised/splash_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);
  await Hive.initFlutter();
  await Hive.openBox('patient');
  runApp(const MemoryCareApp());
}

class MemoryCareApp extends StatelessWidget {
  const MemoryCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home:  SplashScreen(),
    );
  }
}
