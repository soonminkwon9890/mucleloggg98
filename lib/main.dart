import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';
import 'services/revenue_cat_service.dart';
import 'presentation/screens/onboarding/login_screen.dart';
import 'presentation/screens/workout/main_screen.dart';
import 'presentation/screens/splash/app_start_gate.dart';

void main() async {
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'MuscleLog',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
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
      ),
    );
  }
}
