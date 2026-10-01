import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const PiggySmartApp());
}

class PiggySmartApp extends StatelessWidget {
  const PiggySmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PiggySmart',
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
    );
  }
}
