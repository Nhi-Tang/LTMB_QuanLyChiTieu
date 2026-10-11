import 'package:flutter/material.dart';
import 'frontend/screens/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
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
