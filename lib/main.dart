import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// [NEW] 한국어 Material UI 로컬라이제이션
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';
import 'services/revenue_cat_service.dart';
import 'presentation/screens/onboarding/login_screen.dart';
import 'presentation/screens/workout/main_screen.dart';
import 'presentation/screens/splash/app_start_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // Supabase 초기화
  await SupabaseService.initialize();

  // RevenueCat 초기화 (iOS 클로즈 베타용)
  try {
    await RevenueCatService.instance.init();
  } catch (e) {
    debugPrint('RevenueCat initialization failed: $e');
    // 초기화 실패해도 앱은 계속 실행
  }

  // Sentry 초기화 및 앱 실행
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://0109609cd8f1a40ec0554ac0ea48e8a1@o4510906232864768.ingest.us.sentry.io/4510906246889472';
      options.tracesSampleRate = 1.0; // 베타 테스트: 100% 트랜잭션 캡처
    },
    appRunner: () => runApp(const ProviderScope(child: MyApp())),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuscleLog',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // [NEW] 한국어 로컬라이제이션 설정 (DatePicker, TimePicker 등 Material UI 한국어화)
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
      home: AppStartGate(
        child: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return const LoginScreen();
            }

            final session = snapshot.data?.session ??
                Supabase.instance.client.auth.currentSession;

            if (session != null) {
              return const MainScreen();
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
