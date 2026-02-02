import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env 기반 환경 변수 접근
/// GEMINI_API_KEY 등 API 키는 서비스 레이어에서 null/빈 문자열 시 예외 처리.
class EnvConfig {
  EnvConfig._();

  /// Gemini API 키 (AiCoachingService 등에서 사용)
  static String? get geminiApiKey => dotenv.env['GEMINI_API_KEY'];
}
