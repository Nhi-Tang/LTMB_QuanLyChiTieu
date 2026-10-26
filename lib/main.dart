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
import 'frontend/utils/app_language.dart';

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
  await AppLanguage.instance.load(uid: FirebaseAuth.instance.currentUser?.uid);
  runApp(const MouseyApp());
}

class MouseyApp extends StatefulWidget {
  const MouseyApp({super.key});

  // Tỉ lệ thu nhỏ toàn bộ giao diện (1.0 = kích thước gốc)
  static const double uiScale = 0.9;

  @override
  State<MouseyApp> createState() => _MouseyAppState();
}

class _MouseyAppState extends State<MouseyApp> {
  static const double uiScale = MouseyApp.uiScale;

  @override
  void initState() {
    super.initState();
    AppLanguage.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  // Đổi ngôn ngữ thì dựng lại toàn bộ cây widget, kể cả các màn hình,
  // dialog và bottom sheet đang mở, để mọi chữ cùng đổi theo.
  void _onLanguageChanged() {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }
    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mousey',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scaledSize = mq.size / uiScale;
        return MediaQuery(
          data: mq.copyWith(
            size: scaledSize,
            padding: mq.padding / uiScale,
            viewPadding: mq.viewPadding / uiScale,
            viewInsets: mq.viewInsets / uiScale,
            // Không phóng to chữ theo cỡ chữ hệ thống của máy
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.0),
          ),
          child: FittedBox(
            fit: BoxFit.fill,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: scaledSize.width,
              height: scaledSize.height,
              child: child,
            ),
          ),
        );
      },
      home: const AuthGate(),
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
            backgroundColor: Color(0xFFF5FDFD),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00BFB5)),
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
                  backgroundColor: Color(0xFFF5FDFD),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF00BFB5)),
                  ),
                );
              }

              final localUser = userSnapshot.data ?? UserModel(
                uid: firebaseUser.uid,
                name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? context.t('Người dùng'),
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
