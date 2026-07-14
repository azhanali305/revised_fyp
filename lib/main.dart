import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/role_selection_screen.dart';

void main() {
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
      home: const RoleSelectionScreen(),
    );
  }
}
