import 'package:flutter/material.dart';
// import 'package:fyp_revised/screens/sign_in_screen.dart';
import 'package:fyp_revised/screens/sign_up_screen.dart';
import 'theme/app_theme.dart';
// import 'screens/role_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);
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
      home:  SignUpScreen(),
    );
  }
}
