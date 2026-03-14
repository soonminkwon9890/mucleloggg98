import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Profile 존재 여부 확인 및 생성을 담당하는 서비스
///
/// 싱글톤 패턴을 사용하여 앱 전역에서 일관된 프로필 체크를 수행합니다.
/// DB 쓰기 작업 전에 foreign key constraint 에러를 방지합니다.
class ProfileService {
  ProfileService._();

  static final ProfileService _instance = ProfileService._();

  /// 싱글톤 인스턴스 접근자
  static ProfileService get instance => _instance;

  /// 체크 완료된 유저 ID 캐시
  String? _lastCheckedUserId;

  /// Supabase 클라이언트 (간편 접근)
  SupabaseClient get _client => SupabaseService.client;

  /// 현재 사용자 ID 반환 (로그인 필수)
  /// [throws] Exception if not logged in
  String get currentUserId {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }
    return userId;
  }

  /// 현재 사용자 ID 반환 (로그인 불필요, null 가능)
  String? get currentUserIdOrNull => SupabaseService.currentUser?.id;

  /// 프로필 존재 여부 확인 및 생성 (Safety Net)
  ///
  /// [중요] DB 쓰기 작업 전에 호출하여 foreign key constraint 에러 방지
  /// [최적화] 유저 ID 캐싱으로 세션 내 중복 체크 방지
  ///
  /// 호출 예시:
  /// ```dart
  /// await ProfileService.instance.ensureProfileExists();
  /// await client.from('exercise_baselines').insert(data);
  /// ```
  Future<void> ensureProfileExists() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 이미 체크한 유저라면 패스 (네트워크 요청 0회)
    if (_lastCheckedUserId == currentUser.id) return;

    try {
      // profiles 테이블에서 현재 유저 조회
      final existingProfile = await _client
          .from('profiles')
          .select('id')
          .eq('id', currentUser.id)
          .maybeSingle();

      // 프로필이 없으면 기본 프로필 생성
      if (existingProfile == null) {
        await _client.from('profiles').insert({
          'id': currentUser.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 체크 완료된 유저 ID 저장
      _lastCheckedUserId = currentUser.id;
    } catch (e) {
      // 프로필 생성 실패 시에도 계속 진행 (이미 존재하는 경우 등)
      // 실제 foreign key constraint는 다음 작업에서 확인됨
      // 동시 생성 시도 등의 경우를 gracefully 처리
    }
  }

  /// 프로필 체크 캐시 초기화 (로그아웃 시 호출 필수)
  ///
  /// 호출 예시:
  /// ```dart
  /// await supabaseClient.auth.signOut();
  /// ProfileService.instance.clearCache();
  /// ```
  void clearCache() {
    _lastCheckedUserId = null;
  }

  /// 캐시된 유저 ID 확인 (디버깅용)
  String? get cachedUserId => _lastCheckedUserId;

  /// 캐시 상태 확인 (테스트용)
  bool get hasCachedProfile => _lastCheckedUserId != null;
}
