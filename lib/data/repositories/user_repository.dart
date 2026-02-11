import '../services/supabase_service.dart';

class UserRepository {
  const UserRepository();

  /// Admin only: grant premium for target user via RPC.
  ///
  /// Security: DO NOT use direct update() from client.
  Future<void> grantPremium(String targetUserId, int days) async {
    try {
      await SupabaseService.client.rpc(
        'admin_grant_premium',
        params: {
          'target_id': targetUserId,
          'days_to_add': days,
        },
      );
    } catch (e) {
      // Surface message to UI (e.g., Access Denied)
      throw Exception('프리미엄 부여 실패: $e');
    }
  }

  /// Admin only: revoke premium for target user via RPC.
  Future<void> revokePremium(String targetUserId) async {
    try {
      await SupabaseService.client.rpc(
        'admin_revoke_premium',
        params: {'target_id': targetUserId},
      );
    } catch (e) {
      throw Exception('프리미엄 해제 실패: $e');
    }
  }

  /// 현재 사용자의 7일 무료 체험 쿠폰을 활성화합니다. (본인만 호출 가능, RPC에서 검증)
  Future<void> activateCoupon() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }
    try {
      await SupabaseService.client.rpc(
        'activate_free_trial_coupon',
        params: {'target_id': userId},
      );
    } catch (e) {
      throw Exception('쿠폰 사용 실패: $e');
    }
  }
}

