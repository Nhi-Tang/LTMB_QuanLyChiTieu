import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'backend/database/db_helper.dart';
import 'backend/models/user_model.dart';
import 'backend/services/auth_service.dart';
import 'backend/services/pro_service.dart';
import 'backend/services/sync_service.dart';
import 'frontend/screens/auth_screen.dart';
import 'frontend/screens/home_screen.dart';
import 'frontend/screens/admin_management_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  await ProService.instance.init();
  runApp(const MouseyApp());
}

class MouseyApp extends StatelessWidget {
  const MouseyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Mousey',
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFBF3E8),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2F5233)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final firebaseUser = snapshot.data!;

          return FutureBuilder<UserModel?>(
            future: DatabaseHelper.instance.getCurrentUser(firebaseUser.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFFFBF3E8),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2F5233)),
                  ),
                );
              }

              final localUser = userSnapshot.data ?? UserModel(
                uid: firebaseUser.uid,
                name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'Người dùng',
                email: firebaseUser.email ?? '',
                password: '',
                photoUrl: firebaseUser.photoURL,
                provider: firebaseUser.providerData.isNotEmpty ? firebaseUser.providerData.first.providerId : 'password',
                role: firebaseUser.email == 'admin@mousey.com' ? 'admin' : 'user',
                plan: 'free',
                createdAt: DateTime.now().toIso8601String(),
              );

              // Background sync with backend & Pro status (non-blocking on network error)
              AuthService().syncSessionInBackground(firebaseUser);
              SyncService.instance.syncAll();
              ProService.instance.init();

              if (localUser.isAdmin) {
                return AdminManagementScreen(
                  key: ValueKey('admin_${firebaseUser.uid}'),
                  currentAdmin: localUser,
                );
              } else {
                return HomeScreen(
                  key: ValueKey('user_${firebaseUser.uid}'),
                  currentUser: localUser,
                );
              }
            },
          );
        }

        return const AuthScreen();
      },
    );
  }
}
