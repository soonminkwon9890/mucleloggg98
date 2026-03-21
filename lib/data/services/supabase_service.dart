import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';

/// Supabase 서비스 클래스
class SupabaseService {
  static SupabaseClient? _client;

  /// Supabase 초기화
  static Future<void> initialize() async {
    const url = EnvConfig.supabaseUrl;
    const anonKey = EnvConfig.supabaseAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'Supabase 환경 변수가 설정되지 않았습니다. '
        '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... 로 빌드하세요.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _client = Supabase.instance.client;
  }

  /// Supabase 클라이언트 인스턴스 가져오기
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
    }
    return _client!;
  }

  /// 현재 사용자 가져오기
  static User? get currentUser => client.auth.currentUser;

  /// 현재 사용자 ID 가져오기
  static String? get currentUserId => currentUser?.id;

  /// 인증 상태 확인
  static bool get isAuthenticated => currentUser != null;

  /// Storage 버킷 가져오기
  static StorageFileApi get storageBucket => client.storage.from('videos');
}
