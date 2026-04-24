/// 컴파일 타임 환경 변수 접근
/// 빌드 시 --dart-define-from-file=config.json 으로 주입됩니다.
/// config.json 은 절대 pubspec.yaml assets 에 선언하지 말 것 (APK/IPA에 번들되면 키 노출).
/// config.json 은 반드시 .gitignore 에 포함되어야 함.
class EnvConfig {
  EnvConfig._();

  /// Gemini API 키 (AiCoachingService 에서 사용)
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Supabase 프로젝트 URL
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon key
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Amplitude API 키 (AnalyticsService 에서 사용)
  static const String amplitudeApiKey =
      String.fromEnvironment('AMPLITUDE_API_KEY');
}
