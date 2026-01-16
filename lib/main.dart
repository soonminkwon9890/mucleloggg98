import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';
import 'presentation/screens/onboarding/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // Supabase 초기화
  await SupabaseService.initialize();

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
        home: const LoginScreen(),
      ),
    );
  }
}
