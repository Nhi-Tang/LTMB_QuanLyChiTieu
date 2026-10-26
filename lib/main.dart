import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'backend/database/db_helper.dart';
import 'backend/models/user_model.dart';
import 'backend/services/auth_service.dart';
import 'backend/services/category_repository.dart';
import 'backend/services/pro_service.dart';
import 'backend/services/sync_service.dart';
import 'frontend/screens/auth_screen.dart';
import 'frontend/screens/home_screen.dart';
import 'frontend/screens/admin_management_screen.dart';
import 'frontend/utils/app_language.dart';
import 'frontend/theme/app_colors.dart';
import 'frontend/theme/app_theme.dart';

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
  await AppTheme.instance.load();
  runApp(const MouseyApp());
}

class MouseyApp extends StatefulWidget {
  const MouseyApp({super.key});

  // Tỉ lệ thu nhỏ toàn bộ giao diện (1.0 = kích thước gốc)
  static const double uiScale = 0.9;

  @override
  State<MouseyApp> createState() => _MouseyAppState();
}

class _MouseyAppState extends State<MouseyApp> with WidgetsBindingObserver {
  static const double uiScale = MouseyApp.uiScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLanguage.instance.addListener(_rebuildAll);
    AppTheme.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLanguage.instance.removeListener(_rebuildAll);
    AppTheme.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    AppTheme.instance.onPlatformBrightnessChanged();
  }

  void _onThemeChanged() {
    setState(() {});
    _rebuildAll();
  }

  // Đổi ngôn ngữ hoặc giao diện sáng/tối thì dựng lại toàn bộ cây widget,
  // kể cả các màn hình, dialog và bottom sheet đang mở, để mọi thứ cùng đổi theo.
  void _rebuildAll() {
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppTheme.instance.value,
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Giữ stream/future qua các lần dựng lại (đổi ngôn ngữ, sáng/tối) để không
  // hiện lại màn chờ và không tạo lại HomeScreen, làm mất tab đang mở.
  final Stream<User?> _authChanges = FirebaseAuth.instance.authStateChanges();
  String? _uid;
  Future<UserModel?>? _userFuture;

  Future<UserModel?> _loadUser(User firebaseUser) {
    if (_userFuture == null || _uid != firebaseUser.uid) {
      _uid = firebaseUser.uid;
      _userFuture = DatabaseHelper.instance.getCurrentUser(firebaseUser.uid).then((user) {
        // Background sync with backend & Pro status (non-blocking on network error)
        AuthService().syncSessionInBackground(firebaseUser);
        SyncService.instance.syncAll();
        ProService.instance.init();
        CategoryRepository.instance.loadIconKeys();
        return user;
      });
    }
    return _userFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authChanges,
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.tealWhite,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final firebaseUser = snapshot.data!;

          return FutureBuilder<UserModel?>(
            future: _loadUser(firebaseUser),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: AppColors.tealWhite,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
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

        _uid = null;
        _userFuture = null;
        return const AuthScreen();
      },
    );
  }
}
