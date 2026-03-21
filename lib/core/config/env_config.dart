/// 컴파일 타임 환경 변수 접근
/// 빌드 시 --dart-define=KEY=VALUE 로 주입됩니다.
/// 예) flutter run --dart-define=GEMINI_API_KEY=... --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class EnvConfig {
  EnvConfig._();

  /// Gemini API 키 (AiCoachingService 에서 사용)
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Supabase 프로젝트 URL
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon key
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
}
