import '../services/supabase_service.dart';
import '../services/profile_service.dart';

/// 레포지토리 공통 기능 제공
///
/// 프로필 존재 확인, 클라이언트 접근 등 모든 레포지토리에서 필요한 기능을 제공합니다.
/// D.5 리팩토링: ProfileService로 프로필 체크 로직 위임
mixin BaseRepositoryMixin {
  /// Supabase 클라이언트
  final client = SupabaseService.client;

  /// Supabase Storage 버킷
  final storage = SupabaseService.storageBucket;

  /// ProfileService 인스턴스 (D.5: 중앙 집중화된 프로필 관리)
  final _profileService = ProfileService.instance;

  /// 현재 사용자 ID 반환 (로그인 필수)
  String get currentUserId => _profileService.currentUserId;

  /// 현재 사용자 ID 반환 (로그인 불필요, null 가능)
  String? get currentUserIdOrNull => _profileService.currentUserIdOrNull;

  /// 프로필 존재 여부 확인 및 생성 (Safety Net)
  /// [중요] DB 쓰기 작업 전에 호출하여 foreign key constraint 에러 방지
  /// [D.5] ProfileService로 위임
  Future<void> ensureProfileExists() => _profileService.ensureProfileExists();

  /// 프로필 체크 캐시 초기화 (로그아웃 시 호출)
  /// [D.5] ProfileService로 위임
  static void clearProfileCache() => ProfileService.instance.clearCache();
}
