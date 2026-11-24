import 'package:flutter/material.dart';
import 'backend/database/db_helper.dart';
import 'backend/models/user_model.dart';
import 'backend/services/category_repository.dart';
import 'frontend/screens/home_screen.dart';
import 'frontend/utils/app_language.dart';
import 'frontend/theme/app_colors.dart';
import 'frontend/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguage.instance.load(uid: DatabaseHelper.localUid);
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
      home: const AppStartGate(),
    );
  }
}

/// Tải hồ sơ người dùng trên máy rồi vào thẳng màn hình chính
class AppStartGate extends StatefulWidget {
  const AppStartGate({super.key});

  @override
  State<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends State<AppStartGate> {
  // Giữ future qua các lần dựng lại (đổi ngôn ngữ, sáng/tối) để không
  // hiện lại màn chờ và không tạo lại HomeScreen, làm mất tab đang mở.
  late final Future<UserModel> _userFuture =
      DatabaseHelper.instance.getOrCreateLocalUser().then((user) {
    CategoryRepository.instance.loadIconKeys();
    return user;
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.tealWhite,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            ),
          );
        }
        return HomeScreen(currentUser: snapshot.data!);
      },
    );
  }
}
